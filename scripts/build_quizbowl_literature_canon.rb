#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "digest"
require "fileutils"
require "json"
require "optparse"
require "set"
require "sqlite3"
require "time"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DEFAULT_DB = "/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db"
DEFAULT_OUT = File.join(ROOT, "_planning", "quizbowl_lit_canon")
DEFAULT_DATA_OUT = File.join(ROOT, "_data", "quizbowl_literature_canon.yml")

LIT_TYPES = %w[
  novel play poem story short\ story novella epic book collection cycle trilogy tetralogy
  memoir autobiography essay drama comedy tragedy sonnet ode ballad elegy saga romance
  tale fable myth scripture gospel
].freeze

LIT_CONTEXT_RE = /\b(?:novel|play|poem|story|novella|epic|collection|trilogy|memoir|autobiography|essay|drama|comedy|tragedy|sonnet|ode|ballad|elegy|saga|romance|tale|fable|myth|scripture|gospel|author|writer|poet|novelist|playwright|wrote|written|published|composed|translated|adapted|narrator|protagonist|title character|speaker|opening line|last line)\b/i
ANSWER_MARKER_RE = /\b(?:answer|answers|answerline|answerlines)\s*:/i
SPACE_RE = /\s+/
LEADING_NOISE_RE = /\A(?:the\s+)?(?:title\s+|aforementioned\s+|another\s+|one\s+|this\s+|that\s+)+/i
BAD_TITLE_RE = /\A(?:for ten points|ftp|name this|identify this|accept|prompt|do not accept|bonus|tossup|packet|round|page|figure|chapter|part|section|line|answer|answers|read|ftp name|ten points|this work|this poem|this novel|this play|this story)\z/i
PERSON_PREFIX_RE = /\A(?:mr|mrs|ms|dr|professor|captain|general|colonel|king|queen|prince|princess|lord|lady|sir|saint|st)\.?\s+/i
COMMON_NONWORK_RE = /\A(?:america|england|france|germany|italy|spain|russia|china|japan|india|ireland|africa|europe|asia|united states|new york|london|paris|rome|world war|civil war|renaissance|romanticism|modernism|realism|naturalism|symbolism)\z/i
LEADING_BAD_WORD_RE = /\A(?:in|on|at|by|from|to|for|with|and|or|name|identify|this|that|another|other|along|later|extra)\b/i
TRAILING_BAD_WORD_RE = /\b(?:in|on|at|by|from|to|for|with|and|or|the|a|an|of|is|are|was|were)\z/i
QUOTE_TITLE_CONTEXT_RE = /\b(?:entitled|called|named|titled|novel|play|poem|story|short story|work|collection|essay|book|epic|novella|trilogy|tale|fable)\b/i
SEED_ALIAS_DESCRIPTOR_RE = /\b(?:accept|reject|prompt|before read|word forms?|equivalents?|characters?|protagonists?|title character|before (?:he|she|they|it)|early|underlined)\b/i
SEED_ALIAS_STOP_NORMALIZED = Set.new([
  "baby", "cavalry", "cavalrymen", "characters", "equivalents", "ghost",
  "ghosts", "horsemen", "influence", "knights", "monkey", "monkey king",
  "nobleman", "noblemen", "protagonist", "protagonists", "richard", "shiva",
  "soldiers", "spirit", "spirits", "warriors"
]).freeze
SEED_ALIAS_PERSON_DESCRIPTOR_RE = /\b(?:duke|earl|king|lord|prince|princess|queen|sir|saint)\b/i
HIGH_RISK_TITLE_EXEMPT_NORMALIZED = Set.new([
  "the aeneid", "the iliad", "the odyssey", "the ramayana"
]).freeze

CAP_WORD = /(?:[A-Z][A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*|[A-Z][A-Z]+|[IVXLCM]+|[0-9]+)/
LOWER_CONNECTOR = /(?:of|the|and|a|an|in|on|to|for|with|from|as|at|by|or|nor|but|into|over|under|after|before|through|without|between|against|upon|is|are|was|were)/
LOWER_CONNECTOR_WORDS = Set.new(%w[
  of the and a an in on to for with from as at by or nor but into over under
  after before through without between against upon is are was were
]).freeze
TITLE_PHRASE_RE = /#{CAP_WORD}(?:(?:\s+#{LOWER_CONNECTOR}|\s+#{CAP_WORD})){0,10}/
LIT_TYPE_RE = /(?:novel|play|poem|short story|story|novella|epic|collection|cycle|trilogy|tetralogy|memoir|autobiography|essay|drama|comedy|tragedy|sonnet|ode|ballad|elegy|saga|romance|tale|fable|myth|scripture|gospel)/i

CandidateStats = Struct.new(
  :normalized_title,
  :display_counts,
  :source_counts,
  :form_counts,
  :question_ids,
  :dedup_keys,
  :set_titles,
  :years,
  :question_type_counts,
  :difficulty_counts,
  :circuit_counts,
  :examples,
  keyword_init: true
)

SeedCandidate = Struct.new(
  :canonical_title,
  :normalized_title,
  :form_hint,
  :variants,
  keyword_init: true
)

def new_stats(normalized_title)
  CandidateStats.new(
    normalized_title: normalized_title,
    display_counts: Hash.new(0),
    source_counts: Hash.new(0),
    form_counts: Hash.new(0),
    question_ids: Set.new,
    dedup_keys: Set.new,
    set_titles: Set.new,
    years: Set.new,
    question_type_counts: Hash.new(0),
    difficulty_counts: Hash.new(0),
    circuit_counts: Hash.new(0),
    examples: []
  )
end

def normalize_space(value)
  value.to_s.gsub(SPACE_RE, " ").strip
end

def ascii_fold(value)
  value.to_s.unicode_normalize(:nfkd).encode("ASCII", invalid: :replace, undef: :replace, replace: "")
end

def normalize_title(value)
  ascii_fold(value)
    .downcase
    .gsub(/[“”‘’"']/u, "")
    .gsub(/&/, " and ")
    .gsub(/[^a-z0-9]+/, " ")
    .gsub(SPACE_RE, " ")
    .strip
end

def title_slug(value)
  slug = normalize_title(value).gsub(" ", "_")
  slug = "untitled" if slug.empty?
  slug[0, 60]
end

def title_case_like?(value)
  words = value.to_s.scan(/[A-Za-z]+/)
  return false if words.empty?

  words.all? do |word|
    LOWER_CONNECTOR_WORDS.include?(word.downcase) || word[0] == word[0].upcase
  end
end

def clean_candidate(raw)
  value = normalize_space(raw)
  value = value.gsub(/\A["'“”‘’\(\[\{]+|["'“”‘’\)\]\},;:\.!\?]+\z/u, "")
  value = value.gsub(LEADING_NOISE_RE, "")
  value = normalize_space(value)
  value = value.gsub(/\A(?:called|titled|named|entitled)\s+/i, "")
  normalize_space(value)
end

def reject_candidate?(title, source)
  return true if title.empty?
  return true if title.length < 3 || title.length > 110
  return true if title.match?(BAD_TITLE_RE)
  return true if title.match?(COMMON_NONWORK_RE)
  return true if title.include?("://")
  return true if title.count("(") != title.count(")")
  return true if title.scan(/[A-Za-z]/).length < 3
  return true if title.split.length > 14
  return true if title =~ /\A[0-9IVXLCM]+\z/
  return true if title =~ /\A(?:[A-Z]\.){2,}\z/
  return true if title.match?(LEADING_BAD_WORD_RE)
  return true if title.match?(TRAILING_BAD_WORD_RE)
  return true if source != "quoted_lit_context" && title.split.length == 1 && title.length < 4

  false
end

def clean_seed_variant(raw)
  value = normalize_space(raw)
  value = value.gsub(/[\u200B\u200C\u200D\uFEFF]/, "")
  value = value.gsub("_", "")
  value = value.gsub(/\s*["'“”‘’]*\s*\[[^\]]*\]\z/u, "")
  value = value.gsub(/\s*["'“”‘’]*\s*\([^)]*\)\z/u, "")
  value = value.gsub(/\A[_\-\s"'“”‘’]+|[_\-\s"'“”‘’,;:\.!\?]+\z/u, "")
  value = value.gsub(/\A\(?\d+\)?\s+/, "")
  value = value.gsub(/\A\((?:the)\)\s+/i, "The ")
  value = value.gsub(/\s*\[(?:accept|or|reject|prompt|do not accept|before read).*\]\z/i, "")
  value = value.gsub(/\s*\((?:by|play|novel|poem|work|from|accept|or|reject|prompt).*?\)\z/i, "")
  value = normalize_space(value)
  return "" if value.match?(/\b(?:accept|reject|prompt|underlined|before read|do not accept)\b/i)

  value
end

def reject_seed_variant?(title)
  return true if reject_candidate?(title, "seed_exact_title")
  return true if title.length < 5
  return true if title.split.length == 1 && title.length < 6
  return true if title.split.length == 1 && title[/[A-Za-z]/] != title[/[A-Za-z]/]&.upcase

  false
end

def high_risk_seed_variant?(title)
  normalized = normalize_title(title)
  return false if HIGH_RISK_TITLE_EXEMPT_NORMALIZED.include?(normalized)

  words = normalized.split
  return true if words.length == 1
  return true if words.length == 2 && %w[the a an].include?(words.first)

  false
end

def strong_literary_title_context?(context)
  context.to_s.match?(LIT_CONTEXT_RE)
end

def person_like_seed_alias?(title)
  return true if title.match?(/[A-Z][A-Za-z]+['’]s\s+[a-z]/)
  return true if title.match?(SEED_ALIAS_PERSON_DESCRIPTOR_RE)

  words = title.split
  return false unless words.length == 2

  words.all? { |word| word.match?(/\A[A-Z][a-z]+\.?\z/) }
end

def acceptable_seed_alias?(alias_title, canonical, display)
  return false if alias_title.empty? || reject_seed_variant?(alias_title)
  return false if alias_title.match?(SEED_ALIAS_DESCRIPTOR_RE)

  alias_norm = normalize_title(alias_title)
  canonical_norm = normalize_title(canonical)
  display_norm = normalize_title(display)
  return false if SEED_ALIAS_STOP_NORMALIZED.include?(alias_norm)

  exact_primary = alias_norm == canonical_norm || alias_norm == display_norm
  return true if exact_primary

  alias_words = alias_norm.split
  return false if alias_words.length < 2
  return true if alias_norm.include?(canonical_norm) || canonical_norm.include?(alias_norm)
  return false if person_like_seed_alias?(alias_title)

  # Keep plausible alternate-language titles, but not loose one-word prompts or
  # character/person aliases. These still route through alias-dominated review.
  alias_title.match?(/\A[A-Z0-9][A-Za-z0-9'’.\-\s]+\z/) && alias_title.length >= 8
end

def seed_variant_pattern(title)
  escaped = Regexp.escape(title)
  escaped = escaped.gsub(/\\\s+/, "[\\s\\u00A0]+")
  escaped = escaped.gsub("\\-", "[-\\u2010-\\u2015\\s]+")
  escaped = escaped.gsub("\\'", "['’]")
  escaped
end

def parse_json_array(value)
  parsed = JSON.parse(value.to_s)
  parsed.is_a?(Array) ? parsed : []
rescue JSON::ParserError
  []
end

def infer_form(context)
  match = context.to_s.match(LIT_TYPE_RE)
  match ? match[0].downcase.gsub(/\s+/, "_") : "unknown"
end

def snippet_for(text, start_index, length = 220)
  start_pos = [start_index - 80, 0].max
  normalize_space(text[start_pos, length].to_s)
end

def surrounding_text(text, start_index, end_index, radius = 120)
  start_pos = [start_index - radius, 0].max
  end_pos = [end_index + radius, text.length].min
  text[start_pos...end_pos].to_s
end

def add_candidate(matches, raw_title, source, form_hint, clue_text, start_index)
  title = clean_candidate(raw_title)
  return if reject_candidate?(title, source)

  normalized = normalize_title(title)
  return if normalized.empty?

  matches[normalized] ||= {
    title: title,
    source: source,
    form_hint: form_hint,
    snippet: snippet_for(clue_text, start_index || 0)
  }
end

def extract_candidates(clue_text)
  matches = {}
  text = clue_text.to_s

  text.to_enum(:scan, /["“]([^"”]{3,110})["”]/).each do
    match = Regexp.last_match
    raw = match[1]
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    next unless context.match?(QUOTE_TITLE_CONTEXT_RE)
    next unless title_case_like?(raw)
    next if context =~ /\b(?:line|lines|phrase|quotation|quote|opens|begins|ends|says|states|declares|asks|called out)\b[^"“]{0,35}["“]#{Regexp.escape(raw)}/i

    add_candidate(matches, raw, "quoted_lit_context", infer_form(context), text, start_index)
  end

  typed_re = /\b(#{LIT_TYPE_RE})\s+(?:called|titled|named|entitled\s+)?(#{TITLE_PHRASE_RE})/
  text.to_enum(:scan, typed_re).each do
    match = Regexp.last_match
    form = match[1].downcase.gsub(/\s+/, "_")
    raw = match[2]
    add_candidate(matches, raw, "typed_title", form, text, match.begin(2))
  end

  author_re = /\b(?:author of|writer of|poet of|playwright of|wrote|writes|written|published|composed|authored|translated|adapted)\s+(?:a\s+|an\s+|the\s+)?(?:#{LIT_TYPE_RE}\s+)?(?:called|titled|named|entitled\s+)?(#{TITLE_PHRASE_RE})/
  text.to_enum(:scan, author_re).each do
    match = Regexp.last_match
    raw = match[1]
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    add_candidate(matches, raw, "author_verb_title", infer_form(context), text, start_index)
  end

  byline_re = /\b(#{TITLE_PHRASE_RE})\s+by\s+(?:[A-Z][A-Za-z.'-]+(?:\s+[A-Z][A-Za-z.'-]+){0,4})/
  text.to_enum(:scan, byline_re).each do
    match = Regexp.last_match
    raw = match[1]
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    next unless context.match?(LIT_CONTEXT_RE)

    add_candidate(matches, raw, "byline_title", infer_form(context), text, start_index)
  end

  title_context_re = /\b(?:title|eponymous|namesake)\s+(?:character|poem|novel|play|story|work|book|epic|collection|whale|figure|hero|heroine)?(?:\s+of|\s*,)?\s+(#{TITLE_PHRASE_RE})/
  text.to_enum(:scan, title_context_re).each do
    match = Regexp.last_match
    raw = match[1]
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    add_candidate(matches, raw, "title_context", infer_form(context), text, start_index)
  end

  matches.values
end

def build_seed_lexicon(db)
  rows = db.execute(<<~SQL)
    SELECT
      c.normalized_answer_key,
      c.display_answer,
      r.canonical_name,
      r.aliases_json,
      r.answerline_type,
      r.broadness,
      r.model_name,
      r.created_at
    FROM archive_canon_refinement_runs r
    JOIN archive_canon_answerline_candidates c ON c.id = r.candidate_id
    WHERE r.refinement_version = 'archive-canon-refinement-v1'
      AND r.status = 'classified'
      AND r.primary_track_id = 'literature'
      AND r.answerline_type IN (
        'work',
        'work_title',
        'work_section_title',
        'work_or_title',
        'work_or_character',
        'work/character',
        'work/concept'
      )
  SQL

  selected = {}
  rows.each do |row|
    key = row["normalized_answer_key"].to_s
    priority = [
      row["model_name"].to_s == "gpt-5.4-mini" ? 0 : 1,
      row["created_at"].to_s
    ]
    current = selected[key]
    selected[key] = [priority, row] if current.nil? || ((priority <=> current[0]) == -1)
  end

  seeds_by_key = {}
  selected.each_value do |(_, row)|
    canonical = clean_seed_variant(row["canonical_name"].to_s.empty? ? row["display_answer"] : row["canonical_name"])
    next if reject_seed_variant?(canonical)
    display = clean_seed_variant(row["display_answer"])

    variants = Set.new
    variants << canonical
    variants << display if acceptable_seed_alias?(display, canonical, display)
    parse_json_array(row["aliases_json"]).each do |variant|
      alias_title = clean_seed_variant(variant)
      variants << alias_title if acceptable_seed_alias?(alias_title, canonical, display)
    end
    variants = variants.reject { |variant| variant.empty? || reject_seed_variant?(variant) }
    next if variants.empty?

    normalized = normalize_title(canonical)
    seeds_by_key[normalized] ||= SeedCandidate.new(
      canonical_title: canonical,
      normalized_title: normalized,
      form_hint: "seeded_literary_work",
      variants: Set.new
    )
    variants.each { |variant| seeds_by_key[normalized].variants << variant }
  end

  variant_to_seed = {}
  seeds_by_key.each_value do |seed|
    seed.variants.each do |variant|
      variant_to_seed[normalize_title(variant)] ||= Set.new
      variant_to_seed[normalize_title(variant)] << seed.normalized_title
    end
  end

  # Ambiguous short aliases such as "Tempest" can refer to multiple targets or
  # ordinary language; keep only variants that point to one seed.
  variant_to_seed = variant_to_seed.select { |_, seed_keys| seed_keys.length == 1 }
  variant_display_by_normalized = {}
  seeds_by_key.each_value do |seed|
    seed.variants.each do |variant|
      variant_display_by_normalized[normalize_title(variant)] ||= variant
    end
  end
  seed_index = {
    by_length: Hash.new { |hash, key| hash[key] = {} },
    max_length: 0,
    variant_display: variant_display_by_normalized
  }
  variant_to_seed.each do |normalized_variant, seed_keys|
    words = normalized_variant.split
    next if words.empty?

    seed_index[:by_length][words.length][normalized_variant] = seed_keys.first
    seed_index[:max_length] = [seed_index[:max_length], words.length].max
  end

  [seeds_by_key, variant_to_seed.transform_values { |set| set.first }, seed_index]
end

def find_seed_variant_position(text, display_variant)
  match = text.match(/(?<![[:alnum:]])#{seed_variant_pattern(display_variant)}(?![[:alnum:]])/i)
  match ? [match.begin(0), match.end(0), match[0]] : [0, 0, ""]
end

def unreliable_high_risk_seed_match?(text, start_index, end_index, matched_text)
  first_alpha = matched_text.to_s[/[A-Za-z]/]
  return true if first_alpha && first_alpha != first_alpha.upcase

  matched_words = normalize_title(matched_text).split
  if matched_words.length == 1
    following = text[end_index, 40].to_s
    return true if following.match?(/\A\s+[A-Z][A-Za-z]+/)
  end

  if matched_words.length == 2 && %w[the a an].include?(matched_words.first)
    following = text[end_index, 40].to_s
    return true if following.match?(/\A\s+[A-Z][A-Za-z]+/)
  end

  false
end

def extract_seed_matches(clue_text, seeds_by_key, _variant_to_seed, seed_index)
  return [] if seed_index.nil? || seed_index[:max_length].to_i.zero?

  matches = {}
  text = clue_text.to_s
  tokens = normalize_title(text).split
  max_length = seed_index[:max_length]
  by_length = seed_index[:by_length]
  variant_display = seed_index[:variant_display]

  tokens.each_index do |start|
    max_here = [max_length, tokens.length - start].min
    1.upto(max_here) do |length|
      normalized_variant = tokens[start, length].join(" ")
      seed_key = by_length[length][normalized_variant]
      next unless seed_key

      raw = variant_display[normalized_variant] || normalized_variant
      raw_start, raw_end, matched_text = find_seed_variant_position(text, raw)
      context = surrounding_text(text, raw_start, raw_end)
      next if high_risk_seed_variant?(raw) && unreliable_high_risk_seed_match?(text, raw_start, raw_end, matched_text)
      next if high_risk_seed_variant?(raw) && !strong_literary_title_context?(context)

      seed = seeds_by_key.fetch(seed_key)
      matches[seed.normalized_title] ||= {
        title: seed.canonical_title,
        source: normalize_title(raw) == seed.normalized_title ? "seed_exact_title_clue_hit" : "seed_alias_clue_hit",
        form_hint: seed.form_hint,
        snippet: snippet_for(text, raw_start)
      }
    end
  end

  matches.values
end

def combined_matches(clue_text, seeds_by_key, variant_to_seed, seed_index)
  seeded = extract_seed_matches(clue_text, seeds_by_key, variant_to_seed, seed_index)
  extracted = extract_candidates(clue_text)
  merged = {}
  (seeded + extracted).each do |match|
    key = normalize_title(match[:title])
    merged[key] ||= match
  end
  merged.values
end

def safe_tsv(value)
  normalize_space(value).gsub("\t", " ")
end

def write_tsv(path, headers, rows)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def canonical_title(stats)
  stats.display_counts.max_by { |title, count| [count, title.length] }&.first || stats.normalized_title
end

def candidate_id_for(title)
  "qb_lit_#{title_slug(title)}_#{Digest::SHA1.hexdigest(normalize_title(title))[0, 8]}"
end

def review_status_for(stats)
  title = canonical_title(stats)
  exact_or_pattern_count = stats.source_counts.reject { |source, _| source == "seed_alias_clue_hit" }.values.sum
  alias_count = stats.source_counts["seed_alias_clue_hit"].to_i
  seed_exact_count = stats.source_counts["seed_exact_title_clue_hit"].to_i
  high_frequency_seed_title = seed_exact_count >= 80 && stats.set_titles.length >= 50 && stats.years.length >= 10

  if alias_count.positive? && exact_or_pattern_count < 2 && alias_count >= 2 * [exact_or_pattern_count, 1].max
    "needs_review_alias_dominated"
  elsif high_frequency_seed_title
    "accepted_likely_work"
  elsif high_risk_seed_variant?(title)
    "needs_review_common_or_short_title"
  elsif seed_exact_count.zero? && person_like_seed_alias?(title)
    "needs_review_possible_character_or_person"
  elsif title.match?(PERSON_PREFIX_RE) && !title.match?(/\A(?:Lord|Lady)\s+of\b/i)
    "needs_review_possible_character_or_person"
  elsif title.split.length == 1
    "needs_review_short_title"
  else
    "accepted_likely_work"
  end
end

def log1p(value)
  Math.log(value.to_f + 1.0)
end

def salience_score(stats)
  question_count = stats.question_ids.length
  set_count = stats.set_titles.length
  year_count = stats.years.length
  tossup_count = stats.question_type_counts["tossup"]
  circuit_count = stats.circuit_counts.reject { |key, _| key.empty? || key == "unknown" }.length
  difficulty_count = stats.difficulty_counts.reject { |key, _| key.empty? || key == "unknown" }.length

  log1p(question_count) +
    (0.8 * log1p(set_count)) +
    (0.5 * log1p(year_count)) +
    (0.3 * log1p(tossup_count)) +
    (0.2 * log1p(circuit_count)) +
    (0.1 * log1p(difficulty_count))
end

def tier_for(score, review_status, question_count, set_count, year_count)
  return "qb_candidate" unless review_status == "accepted_likely_work"
  return "qb_core" if score >= 12.0 && question_count >= 80 && set_count >= 25 && year_count >= 10
  return "qb_major" if score >= 8.5 && question_count >= 20 && set_count >= 8
  return "qb_contextual" if question_count >= 4

  "qb_candidate"
end

def parse_options
  options = {
    db_path: DEFAULT_DB,
    out_dir: DEFAULT_OUT,
    data_out: DEFAULT_DATA_OUT,
    threshold: 4,
    limit: nil,
    max_clue_chars: 5_000,
    progress_every: 100_000,
    use_answerline_seeds: true,
    track_id: "literature"
  }

  OptionParser.new do |parser|
    parser.on("--db PATH") { |value| options[:db_path] = value }
    parser.on("--out-dir PATH") { |value| options[:out_dir] = value }
    parser.on("--data-out PATH") { |value| options[:data_out] = value }
    parser.on("--threshold N", Integer) { |value| options[:threshold] = value }
    parser.on("--limit N", Integer) { |value| options[:limit] = value }
    parser.on("--max-clue-chars N", Integer) { |value| options[:max_clue_chars] = value }
    parser.on("--progress-every N", Integer) { |value| options[:progress_every] = value }
    parser.on("--no-answerline-seeds") { options[:use_answerline_seeds] = false }
    parser.on("--track TRACK") { |value| options[:track_id] = value }
    parser.on("--all-tracks") { options[:track_id] = nil }
  end.parse!

  options
end

def main
options = parse_options

raise "Missing Loci database: #{options[:db_path]}" unless File.exist?(options[:db_path])

FileUtils.mkdir_p(options[:out_dir])
FileUtils.mkdir_p(File.dirname(options[:data_out]))

db = SQLite3::Database.new(options[:db_path])
db.results_as_hash = true
db.busy_timeout = 30_000

seeds_by_key = {}
variant_to_seed = {}
seed_index = nil
if options[:use_answerline_seeds]
  seeds_by_key, variant_to_seed, seed_index = build_seed_lexicon(db)
  warn "Loaded #{seeds_by_key.length} refined local quizbowl literature-work seeds; #{variant_to_seed.length} unambiguous title variants"
else
  warn "Answerline-seeded title lexicon disabled; using clue-pattern extraction only"
end

stats_by_key = {}
skipped_long = 0
skipped_answer_marker = 0
processed = 0
started_at = Time.now

limit_sql = options[:limit] ? " LIMIT #{Integer(options[:limit])}" : ""
where_clauses = ["q.clue_text IS NOT NULL"]
query_params = []
if options[:track_id]
  where_clauses << "p.track_id = ?"
  query_params << options[:track_id]
end

query = <<~SQL
  SELECT
    q.id AS question_id,
    q.set_title AS set_title,
    q.year AS year,
    q.question_type AS question_type,
    q.clue_text AS clue_text,
    COALESCE(p.dedup_key, '') AS dedup_key,
    COALESCE(p.difficulty_category, 'unknown') AS difficulty_category,
    COALESCE(p.packet_circuit, 'unknown') AS packet_circuit
  FROM archive_practice_questions p
  JOIN archive_parsed_questions q ON q.id = p.archive_parsed_question_id
  WHERE #{where_clauses.join(" AND ")}
  ORDER BY q.id
  #{limit_sql}
SQL

warn "Pass 1: extracting clue-title candidates from #{options[:db_path]}"
db.execute(query, query_params) do |row|
  processed += 1
  if (processed % options[:progress_every]).zero?
    warn "  processed=#{processed} candidates=#{stats_by_key.length} elapsed=#{(Time.now - started_at).round(1)}s"
  end

  clue_text = row["clue_text"].to_s
  if clue_text.length > options[:max_clue_chars]
    skipped_long += 1
    next
  end
  if clue_text.match?(ANSWER_MARKER_RE)
    skipped_answer_marker += 1
    next
  end

  matches = combined_matches(clue_text, seeds_by_key, variant_to_seed, seed_index)
  next if matches.empty?

  matches.each do |match|
    key = normalize_title(match[:title])
    stats = (stats_by_key[key] ||= new_stats(key))
    stats.display_counts[match[:title]] += 1
    stats.source_counts[match[:source]] += 1
    stats.form_counts[match[:form_hint]] += 1
    stats.question_ids << row["question_id"].to_i
    stats.dedup_keys << row["dedup_key"].to_s unless row["dedup_key"].to_s.empty?
    stats.set_titles << row["set_title"].to_s
    stats.years << row["year"].to_i if row["year"]
    stats.question_type_counts[row["question_type"].to_s] += 1
    stats.difficulty_counts[row["difficulty_category"].to_s] += 1
    stats.circuit_counts[row["packet_circuit"].to_s] += 1
    if stats.examples.length < 5
      stats.examples << {
        "question_id" => row["question_id"].to_i,
        "set_title" => row["set_title"].to_s,
        "year" => row["year"],
        "question_type" => row["question_type"].to_s,
        "match_type" => match[:source],
        "snippet" => match[:snippet]
      }
    end
  end

end

accepted_stats = stats_by_key.values
  .select { |stats| stats.question_ids.length >= options[:threshold] }
  .sort_by { |stats| [-salience_score(stats), -stats.question_ids.length, canonical_title(stats)] }

candidate_rows = []
score_rows = []
yaml_rows = []
accepted_keys = Set.new(accepted_stats.map(&:normalized_title))

accepted_stats.each_with_index do |stats, index|
  title = canonical_title(stats)
  candidate_id = candidate_id_for(title)
  review_status = review_status_for(stats)
  score = salience_score(stats)
  tier = tier_for(score, review_status, stats.question_ids.length, stats.set_titles.length, stats.years.length)
  form_hint = stats.form_counts.max_by { |_, count| count }&.first || "unknown"

  candidate_rows << {
    "candidate_id" => candidate_id,
    "canonical_title" => title,
    "normalized_title" => stats.normalized_title,
    "form_hint" => form_hint,
    "candidate_source" => stats.source_counts.sort_by { |key, value| [-value, key] }.map { |key, value| "#{key}:#{value}" }.join(";"),
    "disambiguation_status" => review_status,
    "distinct_question_count" => stats.question_ids.length,
    "distinct_set_count" => stats.set_titles.length,
    "distinct_year_count" => stats.years.length,
    "notes" => "Generated from quizbowl clue_text only; threshold=#{options[:threshold]}."
  }

  score_row = {
    "work_id" => candidate_id,
    "rank" => index + 1,
    "canonical_title" => title,
    "accepted_mention_count" => stats.question_ids.length,
    "distinct_question_count" => stats.question_ids.length,
    "distinct_dedup_count" => stats.dedup_keys.length,
    "distinct_set_count" => stats.set_titles.length,
    "distinct_year_count" => stats.years.length,
    "first_year" => stats.years.min,
    "last_year" => stats.years.max,
    "tossup_count" => stats.question_type_counts["tossup"],
    "bonus_count" => stats.question_type_counts["bonus_part"],
    "difficulty_diversity_count" => stats.difficulty_counts.length,
    "circuit_diversity_count" => stats.circuit_counts.length,
    "quizbowl_salience_score" => format("%.4f", score),
    "tier" => tier,
    "review_status" => review_status,
    "source_counts_json" => JSON.generate(stats.source_counts),
    "examples_json" => JSON.generate(stats.examples)
  }
  score_rows << score_row

  yaml_rows << {
    "id" => candidate_id,
    "rank" => index + 1,
    "title" => title,
    "tier" => tier,
    "review_status" => review_status,
    "quizbowl_salience_score" => score.round(4),
    "distinct_question_count" => stats.question_ids.length,
    "distinct_set_count" => stats.set_titles.length,
    "distinct_year_count" => stats.years.length,
    "first_year" => stats.years.min,
    "last_year" => stats.years.max,
    "tossup_count" => stats.question_type_counts["tossup"],
    "bonus_count" => stats.question_type_counts["bonus_part"],
    "form_hint" => form_hint,
    "evidence_basis" => "quizbowl_clue_text_only",
    "examples" => stats.examples.first(3)
  }
end

write_tsv(
  File.join(options[:out_dir], "quizbowl_lit_title_candidates.tsv"),
  %w[candidate_id canonical_title normalized_title form_hint candidate_source disambiguation_status distinct_question_count distinct_set_count distinct_year_count notes],
  candidate_rows
)

write_tsv(
  File.join(options[:out_dir], "quizbowl_lit_canon_scores.tsv"),
  %w[work_id rank canonical_title accepted_mention_count distinct_question_count distinct_dedup_count distinct_set_count distinct_year_count first_year last_year tossup_count bonus_count difficulty_diversity_count circuit_diversity_count quizbowl_salience_score tier review_status source_counts_json examples_json],
  score_rows
)

cluster_rows = accepted_stats.map do |stats|
  title = canonical_title(stats)
  {
    "work_id" => candidate_id_for(title),
    "canonical_title" => title,
    "normalized_title" => stats.normalized_title,
    "title_variants_json" => JSON.generate(stats.display_counts.sort_by { |key, value| [-value, key] }.to_h),
    "cluster_status" => "single_normalized_title_cluster",
    "notes" => "Article and translation-title merges are intentionally deferred to review."
  }
end

write_tsv(
  File.join(options[:out_dir], "quizbowl_lit_clusters.tsv"),
  %w[work_id canonical_title normalized_title title_variants_json cluster_status notes],
  cluster_rows
)

warn "Pass 2: writing accepted clue mention table for #{accepted_keys.length} candidates"
mention_path = File.join(options[:out_dir], "quizbowl_lit_mentions.tsv")
mention_count = 0
CSV.open(mention_path, "w", col_sep: "\t", write_headers: true, headers: %w[mention_id candidate_id archive_parsed_question_id set_title year question_type mention_text match_type evidence_status clue_snippet]) do |csv|
  db.execute(query, query_params) do |row|
    clue_text = row["clue_text"].to_s
    next if clue_text.length > options[:max_clue_chars]
    next if clue_text.match?(ANSWER_MARKER_RE)

    seen_in_question = Set.new
    combined_matches(clue_text, seeds_by_key, variant_to_seed, seed_index).each do |match|
      key = normalize_title(match[:title])
      next unless accepted_keys.include?(key)
      next if seen_in_question.include?(key)

      seen_in_question << key
      stats = stats_by_key.fetch(key)
      title = canonical_title(stats)
      mention_count += 1
      csv << [
        "qb_lit_mention_%07d" % mention_count,
        candidate_id_for(title),
        row["question_id"].to_i,
        safe_tsv(row["set_title"]),
        row["year"],
        row["question_type"],
        safe_tsv(match[:title]),
        match[:source],
        "accepted",
        safe_tsv(match[:snippet])
      ]
    end
  end
end

false_positive_rows = accepted_stats
  .select { |stats| review_status_for(stats) != "accepted_likely_work" || canonical_title(stats).split.length == 1 || canonical_title(stats).match?(PERSON_PREFIX_RE) }
  .first(500)
  .map do |stats|
    title = canonical_title(stats)
    {
      "candidate_id" => candidate_id_for(title),
      "canonical_title" => title,
      "review_reason" => review_status_for(stats),
      "distinct_question_count" => stats.question_ids.length,
      "distinct_set_count" => stats.set_titles.length,
      "source_counts_json" => JSON.generate(stats.source_counts),
      "example_snippet" => stats.examples.first&.fetch("snippet", "")
    }
  end

write_tsv(
  File.join(options[:out_dir], "quizbowl_lit_false_positive_review.tsv"),
  %w[candidate_id canonical_title review_reason distinct_question_count distinct_set_count source_counts_json example_snippet],
  false_positive_rows
)

File.write(options[:data_out], YAML.dump(yaml_rows))

summary = {
  "generated_at" => Time.now.utc.iso8601,
  "db_path" => options[:db_path],
  "track_id" => options[:track_id] || "all_tracks",
  "threshold" => options[:threshold],
  "processed_rows" => processed,
  "skipped_long_clue_rows" => skipped_long,
  "skipped_answer_marker_rows" => skipped_answer_marker,
  "answerline_seed_lexicon_enabled" => options[:use_answerline_seeds],
  "answerline_seed_work_count" => seeds_by_key.length,
  "answerline_seed_variant_count" => variant_to_seed.length,
  "raw_candidate_count" => stats_by_key.length,
  "threshold_candidate_count" => accepted_stats.length,
  "mention_rows" => mention_count,
  "tier_counts" => score_rows.group_by { |row| row["tier"] }.transform_values(&:length),
  "review_status_counts" => score_rows.group_by { |row| row["review_status"] }.transform_values(&:length)
}

report = <<~MD
  # Quizbowl Literature Canon Method Report

  Generated: #{summary["generated_at"]}

  ## Corpus

  - Database: `#{options[:db_path]}`
  - Source tables: `archive_practice_questions` joined to `archive_parsed_questions`
  - Track filter: `#{options[:track_id] || "all_tracks"}`
  - Evidence field: `clue_text`
  - Answerline policy: answerlines are not counted as evidence.
  - Local answerline seed lexicon enabled: #{options[:use_answerline_seeds]}
  - Local refined literature-work seeds: #{seeds_by_key.length}
  - Unambiguous seed title variants: #{variant_to_seed.length}
  - Processed rows: #{processed}
  - Skipped parser-artifact rows with long clue text: #{skipped_long}
  - Skipped rows with visible answer markers in clue text: #{skipped_answer_marker}

  ## Candidate Extraction

  - Raw normalized clue-title candidates: #{stats_by_key.length}
  - Candidates clearing threshold `distinct_question_count >= #{options[:threshold]}`: #{accepted_stats.length}
  - Accepted mention rows written: #{mention_count}

  ## Tier Counts

  #{summary["tier_counts"].sort.map { |tier, count| "- `#{tier}`: #{count}" }.join("\n")}

  ## Review Status Counts

  #{summary["review_status_counts"].sort.map { |status, count| "- `#{status}`: #{count}" }.join("\n")}

  ## Outputs

  - `quizbowl_lit_title_candidates.tsv`
  - `quizbowl_lit_mentions.tsv`
  - `quizbowl_lit_clusters.tsv`
  - `quizbowl_lit_canon_scores.tsv`
  - `quizbowl_lit_false_positive_review.tsv`
  - `_data/quizbowl_literature_canon.yml`

  ## Caveats

  This is a first automatic quizbowl-only build. It intentionally favors recall and routes ambiguous short titles, character/person-like strings, and context-only capitalized spans to review. Tiers should be treated as quizbowl-salience tiers, not a universal literature canon.
MD

File.write(File.join(options[:out_dir], "quizbowl_lit_method_report.md"), report)
File.write(File.join(options[:out_dir], "quizbowl_lit_summary.json"), JSON.pretty_generate(summary) + "\n")

warn "Done. threshold_candidates=#{accepted_stats.length} mention_rows=#{mention_count}"
warn "Wrote #{options[:out_dir]} and #{options[:data_out]}"
end

main if __FILE__ == $PROGRAM_NAME
