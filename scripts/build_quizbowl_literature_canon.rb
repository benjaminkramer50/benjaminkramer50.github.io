#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "digest"
require "fileutils"
require "json"
require "optparse"
require "rbconfig"
require "set"
require "sqlite3"
require "time"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DEFAULT_DB = "/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db"
DEFAULT_OUT = File.join(ROOT, "_planning", "quizbowl_lit_canon")
DEFAULT_DATA_OUT = File.join(ROOT, "_data", "quizbowl_literature_canon.yml")
DEFAULT_ADJUDICATIONS = File.join(DEFAULT_OUT, "quizbowl_lit_adjudications.yml")

SPACE_RE = /\s+/
ANSWER_MARKER_RE = /\b(?:answer|answers|answerline|answerlines)\s*:/i
BAD_TITLE_RE = /\A(?:for ten points|ftp|name this|identify this|accept|prompt|do not accept|bonus|tossup|packet|round|page|figure|chapter|part|section|line|answer|answers|read|ftp name|ten points|this work|this poem|this novel|this play|this story)\z/i
COMMON_NONWORK_RE = /\A(?:america|england|france|germany|italy|spain|russia|china|japan|india|ireland|africa|europe|asia|united states|new york|london|paris|rome|world war|civil war|renaissance|romanticism|modernism|realism|naturalism|symbolism|zero|none|all of these|both)\z/i
OBVIOUS_NONWORK_NORMALIZED = Set.new(%w[
  civil\ war the\ civil\ war world\ war world\ war\ i world\ war\ ii
  world\ war\ one world\ war\ two the\ world\ war the\ world\ war\ i
  the\ world\ war\ ii the\ world\ war\ one the\ world\ war\ two
]).freeze
HIGH_RISK_SHORT_NORMALIZED = Set.new([
  "i am", "written"
]).freeze
STRONG_LITERARY_FORMS = Set.new(%w[
  novel play poem short_story story novella epic collection drama tragedy
  comedy cycle trilogy tetralogy saga romance fable tale myth scripture
  gospel anthology lyric ode sonnet ballad elegy
]).freeze
CORE_LITERARY_ANSWERLINE_FORMS = Set.new(%w[
  novel play poem short_story story novella epic drama tragedy comedy cycle
  trilogy tetralogy saga romance fable tale myth scripture gospel lyric ode
  sonnet ballad elegy
]).freeze
NON_LITERATURE_TRACKS = Set.new(%w[
  fine_arts social_science geography history science philosophy pop_culture
  current_events trash
]).freeze
LEADING_NOISE_RE = /\A(?:the\s+)?(?:title\s+|aforementioned\s+|another\s+|this\s+|that\s+)+/i
LEADING_BAD_WORD_RE = /\A(?:in|on|at|by|from|to|for|with|and|or|name|identify|this|that|another|other|along|later|extra)\b/i
TRAILING_BAD_WORD_RE = /\b(?:in|on|at|by|from|to|for|with|and|or|the|a|an|of|is|are|was|were)\z/i
PERSON_PREFIX_RE = /\A(?:mr|mrs|ms|dr|professor|captain|general|colonel|king|queen|prince|princess|lord|lady|sir|saint|st)\.?\s+/i

LIT_TYPE_WORDS = %w[
  novel play poem short\ story story novella epic collection book work drama tragedy
  comedy essay memoir autobiography cycle trilogy tetralogy saga romance fable tale
  myth scripture gospel anthology lyric ode sonnet ballad elegy
].freeze
LIT_TYPE_PATTERN = /(?:novel|play|poem|short story|story|novella|epic|collection|book|work|drama|tragedy|comedy|essay|memoir|autobiography|cycle|trilogy|tetralogy|saga|romance|fable|tale|myth|scripture|gospel|anthology|lyric|ode|sonnet|ballad|elegy)/i
LIT_PROMPT_RE = /\b(?:name|identify|give|what is|what are)\s+(?:this|the|these|those|a|an)?\s*(#{LIT_TYPE_PATTERN})\b/i
LIT_CONTEXT_RE = /\b(?:novel|play|poem|story|novella|epic|collection|trilogy|memoir|autobiography|essay|drama|comedy|tragedy|sonnet|ode|ballad|elegy|saga|romance|tale|fable|myth|scripture|gospel|author|writer|poet|novelist|playwright|wrote|written|published|composed|translated|adapted|narrator|protagonist|title character|speaker|opening line|last line)\b/i
QUOTE_TITLE_CONTEXT_RE = /\b(?:entitled|called|named|titled|novel|play|poem|story|short story|work|collection|essay|book|epic|novella|trilogy|tale|fable)\b/i
GENERIC_WORK_FORM_RE = /\A(?:work|book|collection)\z/i
LITERARY_SIGNAL_RE = /\b(?:novel|fiction|play|poem|poetry|short story|story|novella|epic|drama|tragedy|comedy|essay|memoir|autobiography|saga|romance|fable|tale|myth|scripture|gospel|anthology|lyric|ode|sonnet|ballad|elegy|literary|writer|poet|novelist|playwright|character|protagonist|narrator|speaker|stanza|chapter|act|scene)\b/i
NON_LITERARY_CONTEXT_RE = /\b(?:political philosophy|social contract|anthropolog\w*|ethnograph\w*|sociolog\w*|economics?|scientific|mathematical|physics|chemistry|biology|treatise|philosopher|theorist|political theor|political treatise|economic system|kingdom of darkness|book keeping|composer|symphon\w*|orchestral|concerto|sonata|suite|movement|tone poem|painting|sculpture|architect\w*|opera|aria|musical)\b/i

CAP_WORD = /(?:[A-Z][A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*|[A-Z][A-Z]+|[IVXLCM]+|[0-9]+)/
LOWER_CONNECTOR = /(?:of|the|and|a|an|in|on|to|for|with|from|as|at|by|or|nor|but|into|over|under|after|before|through|without|between|against|upon|is|are|was|were|de|du|des|del|della|la|le|les|el|los|las|il|der|die|das|von|van|da|do|dos)/
LOWER_CONNECTOR_WORDS = Set.new(%w[
  of the and a an in on to for with from as at by or nor but into over under
  after before through without between against upon is are was were
  de du des del della la le les el los las il der die das von van da do dos
]).freeze
TITLE_PHRASE_RE = /#{CAP_WORD}(?:(?:\s+#{LOWER_CONNECTOR}|\s+#{CAP_WORD})){0,10}/

HIGH_RISK_TITLE_EXEMPT_NORMALIZED = Set.new([
  "aeneid", "iliad", "odyssey", "ramayana",
  "the aeneid", "the iliad", "the odyssey", "the ramayana"
]).freeze

GENERIC_ANSWERLINE_FORMS = Set.new(%w[book work essay unknown]).freeze
LLM_REVIEW_QUEUE_LIMIT = 500

CandidateStats = Struct.new(
  :normalized_title,
  :display_counts,
  :source_counts,
  :form_counts,
  :answerline_form_counts,
  :track_counts,
  :question_ids,
  :answerline_question_ids,
  :clue_question_ids,
  :set_titles,
  :years,
  :question_type_counts,
  :examples,
  :literary_signal_count,
  :non_literary_signal_count,
  :manual_canonical_title,
  keyword_init: true
)

Seed = Struct.new(:canonical_title, :normalized_title, :variants, :seed_basis, keyword_init: true)

def new_stats(normalized_title)
  CandidateStats.new(
    normalized_title: normalized_title,
    display_counts: Hash.new(0),
    source_counts: Hash.new(0),
    form_counts: Hash.new(0),
    answerline_form_counts: Hash.new(0),
    track_counts: Hash.new(0),
    question_ids: Set.new,
    answerline_question_ids: Set.new,
    clue_question_ids: Set.new,
    set_titles: Set.new,
    years: Set.new,
    question_type_counts: Hash.new(0),
    examples: [],
    literary_signal_count: 0,
    non_literary_signal_count: 0,
    manual_canonical_title: nil
  )
end

def normalize_space(value)
  value.to_s.gsub(/[[:cntrl:]]/, " ").gsub(SPACE_RE, " ").strip
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
  return true if title.length < 3 || title.length > 130
  return true if title.match?(BAD_TITLE_RE)
  return true if title.match?(COMMON_NONWORK_RE)
  return true if obvious_nonwork_title?(title)
  return true if title.include?("://")
  return true if title.count("(") != title.count(")")
  return true if title.scan(/[A-Za-z]/).length < 3
  return true if title.split.length > 16
  return true if title =~ /\A[0-9IVXLCM]+\z/
  return true if title =~ /\A(?:[A-Z]\.){2,}\z/
  return true if title.match?(LEADING_BAD_WORD_RE)
  return true if title.match?(TRAILING_BAD_WORD_RE)
  return true if source != "quoted_lit_context" && title.split.length == 1 && title.length < 4

  false
end

def clean_answerline(raw)
  value = normalize_space(raw)
  value = value.gsub(/<[^>]+>/, " ")
  value = value.gsub(/\A\s*(?:answer|answers?)\s*:?\s*/i, "")
  value = value.gsub(/\s*\[(?:accept|or|prompt|do not accept|do not prompt|reject).*?\]\s*/i, " ")
  value = value.gsub(/\s*\((?:accept|or|prompt|do not accept|do not prompt|reject|pronounced|read).*?\)\s*/i, " ")
  value = value.gsub(/\{[^}]*\}/, " ")
  value = value.split(/\s*;\s*/).first.to_s
  value = value.split(/\s+--\s+/).first.to_s
  value = value.gsub(/\A[_\-\s"'“”‘’]+|[_\-\s"'“”‘’,;:\.!\?]+\z/u, "")
  normalize_space(value)
end

def answerline_variants(raw)
  variants = []
  primary = clean_answerline(raw)
  variants << primary unless primary.empty?

  raw.to_s.scan(/\[(?:accept|or)\s+([^\]]+)\]/i).flatten.each do |variant|
    cleaned = clean_answerline(variant)
    variants << cleaned unless cleaned.empty?
  end

  variants.map { |variant| clean_candidate(variant) }
    .reject { |variant| reject_candidate?(variant, "raw_answerline_work_prompt") }
    .uniq { |variant| normalize_title(variant) }
end

def infer_form(context)
  match = context.to_s.match(LIT_TYPE_PATTERN)
  match ? match[0].downcase.gsub(/\s+/, "_") : "unknown"
end

def prompt_form(context)
  tail = context.to_s[-650, 650].to_s
  match = tail.match(LIT_PROMPT_RE) || context.to_s.match(LIT_PROMPT_RE)
  return nil unless match

  form = match[1].to_s.downcase.gsub(/\s+/, "_")
  if form.match?(GENERIC_WORK_FORM_RE)
    return nil if tail.match?(NON_LITERARY_CONTEXT_RE)
    return nil unless tail.match?(LITERARY_SIGNAL_RE) || context.to_s.match?(LITERARY_SIGNAL_RE)
  end

  form
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

def add_candidate_match(matches, raw_title, source, form_hint, clue_text, start_index)
  title = clean_candidate(raw_title)
  return if reject_candidate?(title, source)

  normalized = normalize_title(title)
  return if normalized.empty?

  matches[normalized] ||= {
    title: title,
    source: source,
    form_hint: form_hint || "unknown",
    snippet: snippet_for(clue_text, start_index || 0)
  }
end

def extract_clue_title_candidates(clue_text)
  matches = {}
  text = clue_text.to_s
  return [] unless text.match?(LIT_CONTEXT_RE)

  text.to_enum(:scan, /["“]([^"”]{3,120})["”]/).each do
    match = Regexp.last_match
    raw = match[1]
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    next unless context.match?(QUOTE_TITLE_CONTEXT_RE)
    next unless title_case_like?(raw)
    next if context =~ /\b(?:line|lines|phrase|quotation|quote|opens|begins|ends|says|states|declares|asks|called out)\b[^"“]{0,35}["“]#{Regexp.escape(raw)}/i

    add_candidate_match(matches, raw, "quoted_lit_context", infer_form(context), text, start_index)
  end

  typed_re = /\b(#{LIT_TYPE_PATTERN})\s+(?:called|titled|named|entitled\s+)?(#{TITLE_PHRASE_RE})/
  text.to_enum(:scan, typed_re).each do
    match = Regexp.last_match
    type_word = match[1]
    raw_title = match[2]
    if type_word.match?(/\A[A-Z]/) && type_word.match?(/\A(?:Elegy|Ode|Sonnet|Ballad|Lyric|Song|Hymn)\z/)
      raw_title = "#{type_word} #{raw_title}"
    end

    add_candidate_match(matches, raw_title, "typed_title", type_word.downcase.gsub(/\s+/, "_"), text, match.begin(2))
  end

  author_re = /\b(?:author of|writer of|poet of|playwright of|wrote|writes|written|published|composed|authored|translated|adapted)\s+(?:a\s+|an\s+|the\s+)?(?:#{LIT_TYPE_PATTERN}\s+)?(?:called|titled|named|entitled\s+)?(#{TITLE_PHRASE_RE})/
  text.to_enum(:scan, author_re).each do
    match = Regexp.last_match
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    add_candidate_match(matches, match[1], "author_verb_title", infer_form(context), text, start_index)
  end

  byline_re = /\b(#{TITLE_PHRASE_RE})\s+by\s+(?:[A-Z][A-Za-z.'-]+(?:\s+[A-Z][A-Za-z.'-]+){0,4})/
  text.to_enum(:scan, byline_re).each do
    match = Regexp.last_match
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    next unless context.match?(LIT_CONTEXT_RE)

    add_candidate_match(matches, match[1], "byline_title", infer_form(context), text, start_index)
  end

  title_context_re = /\b(?:title|eponymous|namesake)\s+(?:character|poem|novel|play|story|work|book|epic|collection|whale|figure|hero|heroine)?(?:\s+of|\s*,)?\s+(#{TITLE_PHRASE_RE})/
  text.to_enum(:scan, title_context_re).each do
    match = Regexp.last_match
    start_index = match.begin(1)
    context = surrounding_text(text, start_index, match.end(1))
    add_candidate_match(matches, match[1], "title_context", infer_form(context), text, start_index)
  end

  matches.values
end

def high_risk_title?(title)
  normalized = normalize_title(title)
  return false if HIGH_RISK_TITLE_EXEMPT_NORMALIZED.include?(normalized)
  return true if HIGH_RISK_SHORT_NORMALIZED.include?(normalized)

  words = normalized.split
  return true if words.length == 1
  return true if words.length == 2 && %w[the a an].include?(words.first)

  false
end

def person_like_title?(title)
  return true if title.match?(PERSON_PREFIX_RE)

  words = title.split
  return true if words.length == 2 && words[0].match?(/\A[A-Z][a-z]+\.?\z/) && words[1].match?(/\A[IVXLCM]+\z/)
  return false unless words.length == 2

  words.all? { |word| word.match?(/\A[A-Z][a-z]+\.?\z/) }
end

def obvious_nonwork_title?(title)
  normalized = normalize_title(title)
  without_article = normalized.sub(/\A(?:the|a|an)\s+/, "")
  OBVIOUS_NONWORK_NORMALIZED.include?(normalized) || OBVIOUS_NONWORK_NORMALIZED.include?(without_article)
end

def strong_literary_title_context?(context)
  context.to_s.match?(LIT_CONTEXT_RE)
end

def possible_combined_title_artifact?(title)
  words = title.to_s.split
  return false if words.length < 5

  words.each_with_index.any? do |word, index|
    next false unless word.downcase == "and"
    next false unless index.positive? && index < words.length - 1

    left_content = words[0...index].reject { |part| LOWER_CONNECTOR_WORDS.include?(part.downcase) }
    right_content = words[(index + 1)..].reject { |part| LOWER_CONNECTOR_WORDS.include?(part.downcase) }
    next false unless left_content.length >= 2 && right_content.length >= 2

    words[index + 1].match?(/\A(?:The|A|An|[A-Z][A-Za-z0-9]+)\z/)
  end
end

def fragment_title_artifact?(title)
  title.match?(/\A(?:Written|Spoken|Sung)\s+(?:in|on|by|for|with)\b/i)
end

def non_literary_context_dominated?(stats)
  return false if literary_answerline_backed?(stats)

  non_literary_signal_count = stats.non_literary_signal_count.to_i
  literary_signal_count = stats.literary_signal_count.to_i
  literature_track_count = track_count(stats, "literature")
  named_non_lit_track_count = named_non_literature_track_count(stats)
  core_form_count = core_literary_answerline_form_count(stats)

  return true if non_literary_signal_count >= 2 && non_literary_signal_count > literary_signal_count
  return true if named_non_lit_track_count >= 5 && literature_track_count.zero? && core_form_count.zero?
  if named_non_lit_track_count >= 10 &&
      named_non_lit_track_count >= [literature_track_count * 3, 10].max &&
      core_form_count < 4
    return true
  end

  false
end

def core_literary_answerline_form_count(stats)
  stats.answerline_form_counts.sum do |form, count|
    CORE_LITERARY_ANSWERLINE_FORMS.include?(form) ? count : 0
  end
end

def core_literary_form_count(stats)
  stats.form_counts.sum do |form, count|
    CORE_LITERARY_ANSWERLINE_FORMS.include?(form) ? count : 0
  end
end

def literary_answerline_backed?(stats)
  return false if stats.answerline_question_ids.length < 4

  core_literary_answerline_form_count(stats) >= 4
end

def clue_only_non_literature_track_dominated?(stats)
  return false unless stats.answerline_question_ids.empty?
  return false if track_count(stats, "literature").positive?
  return false if core_literary_form_count(stats).positive?

  (named_non_literature_track_count(stats) + track_count(stats, "other_academic")) >= 3
end

def section_context_dominated?(stats)
  return false if stats.answerline_question_ids.length.positive?

  snippets = stats.examples.map { |example| example["snippet"].to_s }.join(" ")
  snippets.scan(/\bsections?\b/i).length >= 2
end

def clue_seed_eligible?(stats, title)
  return false if high_risk_title?(title)
  return false if stats.answerline_question_ids.empty? && person_like_title?(title)
  return false if possible_combined_title_artifact?(title)
  return false if fragment_title_artifact?(title)
  return false if non_literary_context_dominated?(stats)
  return false if section_context_dominated?(stats)

  true
end

def exact_match_seed_eligible?(title)
  return true unless high_risk_title?(title)

  HIGH_RISK_TITLE_EXEMPT_NORMALIZED.include?(normalize_title(title))
end

def seed_variant_pattern(title)
  escaped = Regexp.escape(title)
  escaped = escaped.gsub(/\\\s+/, "[\\s\\u00A0]+")
  escaped = escaped.gsub("\\-", "[-\\u2010-\\u2015\\s]+")
  escaped = escaped.gsub("\\'", "['’]")
  escaped
end

def seed_index_variants(variant)
  words = normalize_title(variant).split
  return [] if words.empty?

  variants = [[words, variant]]
  if %w[the a an].include?(words.first) && words.length > 1
    stripped_display = variant.sub(/\A(?:The|A|An)\s+/i, "")
    variants << [words[1..], stripped_display]
  end

  variants
end

def new_seed_trie_node
  { children: {}, entries: [] }
end

def add_seed_trie_entry(root, words, seed, display_variant)
  node = root
  words.each do |word|
    node = node[:children][word] ||= new_seed_trie_node
  end
  node[:entries] << [seed, display_variant]
end

def find_seed_variant_position(text, display_variant)
  match = text.match(/(?<![[:alnum:]])#{seed_variant_pattern(display_variant)}(?![[:alnum:]])/i)
  match ? [match.begin(0), match.end(0), match[0]] : [0, 0, ""]
end

def unreliable_high_risk_seed_match?(text, end_index, matched_text)
  first_alpha = matched_text.to_s[/[A-Za-z]/]
  return true if first_alpha && first_alpha != first_alpha.upcase

  matched_words = normalize_title(matched_text).split
  if matched_words.length <= 2
    following = text[end_index, 40].to_s
    return true if following.match?(/\A\s+[A-Z][A-Za-z]+/)
  end

  false
end

def add_observation(stats_by_key, normalized, display, source, form_hint, row, snippet)
  stats = stats_by_key[normalized] ||= new_stats(normalized)
  stats.display_counts[display] += 1
  stats.source_counts[source] += 1
  stats.form_counts[form_hint || "unknown"] += 1
  track_id = row["track_id"].to_s
  stats.track_counts[track_id] += 1 unless track_id.empty?
  stats.literary_signal_count += snippet.to_s.scan(LITERARY_SIGNAL_RE).length
  stats.non_literary_signal_count += snippet.to_s.scan(NON_LITERARY_CONTEXT_RE).length
  qid = row["id"].to_i
  stats.question_ids << qid
  if source == "raw_answerline_work_prompt"
    stats.answerline_form_counts[form_hint || "unknown"] += 1
    stats.answerline_question_ids << qid
  else
    stats.clue_question_ids << qid
  end
  stats.set_titles << row["set_title"].to_s unless row["set_title"].to_s.empty?
  stats.years << row["year"].to_i if row["year"].to_i.positive?
  stats.question_type_counts[row["question_type"].to_s] += 1

  if stats.examples.length < 5
    stats.examples << {
      "question_id" => qid,
      "set_title" => row["set_title"].to_s,
      "year" => row["year"].to_i,
      "question_type" => row["question_type"].to_s,
      "match_type" => source,
      "snippet" => snippet
    }
  end
end

def merge_counter!(target, source)
  source.each { |key, count| target[key] += count }
end

def merge_stats!(target, source)
  merge_counter!(target.display_counts, source.display_counts)
  merge_counter!(target.source_counts, source.source_counts)
  merge_counter!(target.form_counts, source.form_counts)
  merge_counter!(target.answerline_form_counts, source.answerline_form_counts)
  merge_counter!(target.track_counts, source.track_counts)
  target.question_ids.merge(source.question_ids)
  target.answerline_question_ids.merge(source.answerline_question_ids)
  target.clue_question_ids.merge(source.clue_question_ids)
  target.set_titles.merge(source.set_titles)
  target.years.merge(source.years)
  merge_counter!(target.question_type_counts, source.question_type_counts)
  target.literary_signal_count += source.literary_signal_count
  target.non_literary_signal_count += source.non_literary_signal_count
  target.manual_canonical_title ||= source.manual_canonical_title
  target.examples = (target.examples + source.examples)
    .sort_by { |example| [example["question_id"].to_i, example["match_type"].to_s, example["snippet"].to_s] }
    .first(5)
end

def merge_stats_by_key!(target, source)
  source.each do |normalized, stats|
    if target.key?(normalized)
      merge_stats!(target[normalized], stats)
    else
      target[normalized] = stats
    end
  end
end

def canonical_title(stats)
  return stats.manual_canonical_title unless stats.manual_canonical_title.to_s.empty?

  stats.display_counts.max_by { |title, count| [count, title.length] }&.first || stats.normalized_title
end

def candidate_id_for(title)
  "qb_lit_#{title_slug(title)}_#{Digest::SHA1.hexdigest(normalize_title(title))[0, 8]}"
end

def build_seed_index(candidate_stats, min_count)
  seeds = {}
  seed_basis_counts = Hash.new(0)
  candidate_stats.each do |normalized, stats|
    title = canonical_title(stats)
    answerline_seed = stats.answerline_question_ids.length >= min_count
    clue_seed = stats.clue_question_ids.length >= min_count &&
      stats.set_titles.length >= 3 &&
      clue_seed_eligible?(stats, title)
    next unless answerline_seed || clue_seed

    seed_basis = if answerline_seed && clue_seed
      "answerline_and_clue"
    elsif answerline_seed
      "answerline"
    else
      "clue"
    end

    variants = Set.new([title])
    stats.display_counts.each_key { |variant| variants << variant unless variant.to_s.empty? }
    next unless exact_match_seed_eligible?(title)

    seeds[normalized] = Seed.new(canonical_title: title, normalized_title: normalized, variants: variants, seed_basis: seed_basis)
    seed_basis_counts[seed_basis] += 1
  end

  index = new_seed_trie_node
  seeds.each_value do |seed|
    seed.variants.each do |variant|
      seed_index_variants(variant).each do |words, display_variant|
        add_seed_trie_entry(index, words, seed, display_variant)
      end
    end
  end

  [seeds, index, seed_basis_counts]
end

def find_seed_clue_matches(clue_text, seed_index)
  text = clue_text.to_s
  tokens = normalize_title(text).split
  matches = {}

  tokens.each_index do |start|
    node = seed_index
    cursor = start
    while cursor < tokens.length
      node = node[:children][tokens[cursor]]
      break unless node

      node[:entries].each do |seed, variant|
        raw_start = 0
        if high_risk_title?(variant) || person_like_title?(variant)
          raw_start, raw_end, matched_text = find_seed_variant_position(text, variant)
          context = surrounding_text(text, raw_start, raw_end)
          next if high_risk_title?(variant) && unreliable_high_risk_seed_match?(text, raw_end, matched_text)
          next unless strong_literary_title_context?(context)
        end

        matches[seed.normalized_title] ||= {
          title: seed.canonical_title,
          source: seed.seed_basis == "clue" ? "clue_derived_seed_clue_mention" : "raw_answerline_seed_clue_mention",
          form_hint: seed.seed_basis == "clue" ? "clue_derived_seed" : "answerline_seed",
          snippet: snippet_for(text, raw_start)
        }
      end

      cursor += 1
    end
  end

  matches.values
end

def review_status_for(stats)
  title = canonical_title(stats)
  answerline_count = stats.answerline_question_ids.length
  clue_count = stats.clue_question_ids.length

  return "needs_review_common_or_short_title" if obvious_nonwork_title?(title)
  return "needs_review_possible_combined_title" if possible_combined_title_artifact?(title)
  return "needs_review_fragment_title" if fragment_title_artifact?(title)
  return "rejected_non_literary_context" if non_literary_context_dominated?(stats)
  return "accepted_likely_work" if literary_answerline_backed?(stats)
  return "needs_review_section_or_subwork_title" if clue_count >= 4 && section_context_dominated?(stats)
  return "needs_review_non_literature_track_context" if clue_only_non_literature_track_dominated?(stats)
  return "needs_review_possible_character_or_person" if answerline_count.zero? && person_like_title?(title)
  return "accepted_likely_work" if answerline_count >= 4
  return "needs_review_common_or_short_title" if high_risk_title?(title)
  return "accepted_likely_work" if clue_count >= 4 && stats.set_titles.length >= 3
  return "needs_review_possible_character_or_person" if person_like_title?(title)

  "needs_review_low_evidence"
end

def rejected_review_status?(review_status)
  review_status.to_s.start_with?("rejected_")
end

def needs_review_status?(review_status)
  review_status.to_s.start_with?("needs_review_")
end

def manual_status_from_adjudication(adjudication, base_status)
  return base_status unless adjudication

  explicit_status = adjudication["review_status"] || adjudication["status"]
  return explicit_status.to_s unless explicit_status.to_s.empty?

  decision = adjudication["decision"].to_s.downcase
  reason = normalize_title(adjudication["reason"] || adjudication["category"] || "manual")
    .tr(" ", "_")
  reason = "manual" if reason.empty?

  case decision
  when "accept", "accepted"
    "accepted_likely_work"
  when "reject", "rejected"
    "rejected_#{reason}"
  when "review", "needs_review"
    "needs_review_#{reason}"
  else
    base_status
  end
end

def adjudication_decision(adjudication)
  return "" unless adjudication

  adjudication["decision"].to_s
end

def adjudication_reason(adjudication)
  return "" unless adjudication

  (adjudication["reason"] || adjudication["category"] || adjudication["notes"]).to_s
end

def log1p(value)
  Math.log(value.to_f + 1.0)
end

def salience_score(stats)
  answerline_count = stats.answerline_question_ids.length
  clue_count = stats.clue_question_ids.length
  set_count = stats.set_titles.length
  year_count = stats.years.length
  tossup_count = stats.question_type_counts["tossup"]

  (1.4 * log1p(answerline_count)) +
    log1p(clue_count) +
    (0.8 * log1p(set_count)) +
    (0.5 * log1p(year_count)) +
    (0.25 * log1p(tossup_count))
end

def tier_for(score, review_status, total_count, set_count, year_count)
  return "qb_rejected" if rejected_review_status?(review_status)
  return "qb_candidate" unless review_status == "accepted_likely_work"
  return "qb_core" if score >= 12.5 && total_count >= 80 && set_count >= 25 && year_count >= 10
  return "qb_major" if score >= 8.75 && total_count >= 20 && set_count >= 8
  return "qb_contextual" if total_count >= 4

  "qb_candidate"
end

def safe_tsv(value)
  normalize_space(value).gsub("\t", " ")
end

def repo_relative_path(path)
  expanded = File.expand_path(path)
  root = File.expand_path(ROOT)
  return expanded[(root.length + 1)..] if expanded.start_with?("#{root}#{File::SEPARATOR}")

  path
end

def write_tsv(path, headers, rows)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def write_jsonl(path, rows)
  File.open(path, "w") do |file|
    rows.each { |row| file.puts(JSON.generate(row)) }
  end
end

def load_adjudications(path)
  return {} unless File.exist?(path)

  payload = YAML.load_file(path) || {}
  decisions = payload["decisions"] || []
  by_key = {}
  decisions.each_with_index do |entry, index|
    unless entry.is_a?(Hash)
      warn "Ignoring malformed adjudication entry at index #{index}"
      next
    end

    keys = []
    candidate_id = entry["candidate_id"].to_s
    keys << "id:#{candidate_id}" unless candidate_id.empty?

    normalized = entry["normalized_title"].to_s
    title = entry["canonical_title"] || entry["title"]
    normalized = normalize_title(title) if normalized.empty? && title
    keys << "title:#{normalized}" unless normalized.empty?

    keys.each { |key| by_key[key] = entry }
  end
  by_key
end

def load_alias_rules(path)
  return [{}, {}] unless File.exist?(path)

  payload = YAML.load_file(path) || {}
  decisions = payload["decisions"] || []
  alias_map = {}
  canonical_titles = {}

  decisions.each do |entry|
    next unless entry.is_a?(Hash)

    target_title = entry["alias_of"] || entry["merge_into"]
    next if target_title.to_s.strip.empty?

    source_title = entry["canonical_title"] || entry["title"]
    source_normalized = entry["normalized_title"].to_s
    source_normalized = normalize_title(source_title) if source_normalized.empty? && source_title
    target_normalized = normalize_title(target_title)
    next if source_normalized.empty? || target_normalized.empty? || source_normalized == target_normalized

    alias_map[source_normalized] = target_normalized
    canonical_titles[target_normalized] = target_title.to_s
  end

  [alias_map, canonical_titles]
end

def resolved_alias_target(normalized, alias_map)
  seen = {}
  current = normalized

  while alias_map.key?(current) && !seen[current]
    seen[current] = true
    current = alias_map[current]
  end

  current
end

def apply_alias_rules!(stats_by_key, alias_map, canonical_titles)
  return 0 if alias_map.empty?

  applied = 0
  alias_map.keys.each do |source_normalized|
    target_normalized = resolved_alias_target(source_normalized, alias_map)
    next if source_normalized == target_normalized

    source_stats = stats_by_key[source_normalized]
    next unless source_stats

    target_stats = stats_by_key[target_normalized] ||= new_stats(target_normalized)
    target_stats.normalized_title = target_normalized
    target_stats.manual_canonical_title ||= canonical_titles[target_normalized]
    merge_stats!(target_stats, source_stats)
    target_stats.manual_canonical_title ||= canonical_titles[target_normalized]
    stats_by_key.delete(source_normalized)
    applied += 1
  end

  canonical_titles.each do |normalized, title|
    next unless stats_by_key[normalized]

    stats_by_key[normalized].manual_canonical_title ||= title
  end

  applied
end

def adjudication_for(adjudications, title, work_id)
  adjudications["id:#{work_id}"] || adjudications["title:#{normalize_title(title)}"]
end

def load_track_id_map(db)
  track_by_question_id = {}
  db.execute("SELECT archive_parsed_question_id, track_id FROM archive_practice_questions") do |row|
    question_id = row["archive_parsed_question_id"].to_i
    track_id = row["track_id"].to_s
    track_by_question_id[question_id] = track_id unless track_id.empty?
  end
  track_by_question_id
end

def track_count(stats, track)
  stats.track_counts.fetch(track, 0).to_i
end

def known_track_count(stats)
  stats.track_counts.values.sum
end

def non_literature_track_count(stats)
  known_track_count(stats) - track_count(stats, "literature")
end

def named_non_literature_track_count(stats)
  stats.track_counts.sum do |track, count|
    NON_LITERATURE_TRACKS.include?(track) ? count : 0
  end
end

def dominant_track(stats)
  stats.track_counts.max_by { |track, count| [count, track] }&.first.to_s
end

def strong_answerline_form_count(stats)
  stats.answerline_form_counts.sum do |form, count|
    STRONG_LITERARY_FORMS.include?(form) ? count : 0
  end
end

def generic_answerline_dominated?(stats)
  answerline_total = stats.answerline_form_counts.values.sum
  return false if answerline_total.zero?

  generic_count = stats.answerline_form_counts.sum do |form, count|
    GENERIC_ANSWERLINE_FORMS.include?(form) ? count : 0
  end
  generic_count.positive? && generic_count >= strong_answerline_form_count(stats)
end

def accepted_suspicious?(row)
  return false unless row[:review_status] == "accepted_likely_work"

  stats = row[:stats]
  literature = track_count(stats, "literature")
  non_literature = non_literature_track_count(stats)
  known = known_track_count(stats)
  return true if generic_answerline_dominated?(stats) && row[:score] >= 8.0
  return true if stats.non_literary_signal_count.to_i >= 20
  return true if known >= 25 && literature < 5 && non_literature >= 20
  return true if known >= 50 && non_literature >= [literature * 4, 40].max

  false
end

def rejected_suspicious?(row)
  return false unless rejected_review_status?(row[:review_status])

  stats = row[:stats]
  return true if strong_answerline_form_count(stats) >= 2
  return true if track_count(stats, "literature") >= 10
  return true if row[:score] >= 9.0 && stats.non_literary_signal_count.to_i < stats.literary_signal_count.to_i

  false
end

def audit_queue_specs_for(row)
  status = row[:review_status]
  specs = []

  if accepted_suspicious?(row)
    specs << ["accepted_suspicious", "verify_accept_or_move_to_adjudicated_rejection", "accepted row has weak category/form/context sanity signals"]
  end

  if rejected_suspicious?(row)
    specs << ["rejected_suspicious", "verify_rejection_or_rescue_with_adjudication", "rejected row has literature-track or strong-form rescue signals"]
  end

  if needs_review_status?(status)
    specs << ["high_salience_review", "classify_accept_reject_split_or_merge", "high-salience unresolved review candidate"]
  end

  if status == "needs_review_common_or_short_title" || high_risk_title?(row[:title])
    specs << ["generic_short_title", "disambiguate_short_or_common_title", "short/common title needs identity check"]
  end

  if %w[needs_review_possible_combined_title needs_review_section_or_subwork_title].include?(status)
    specs << ["alias_split_candidate", "decide_split_merge_or_scope", "possible combined title, section, or subwork issue"]
  end

  specs
end

def audit_queue_row(queue_id, queue_name, row, recommended_action, notes)
  stats = row[:stats]
  example = stats.examples.first || {}
  {
    "queue_id" => queue_id,
    "queue_name" => queue_name,
    "priority_score" => format("%.4f", row[:score]),
    "work_id" => candidate_id_for(row[:title]),
    "canonical_title" => safe_tsv(row[:title]),
    "current_status" => row[:review_status],
    "base_status" => row[:base_review_status],
    "tier" => row[:tier],
    "total_question_count" => stats.question_ids.length,
    "answerline_question_count" => stats.answerline_question_ids.length,
    "clue_mention_question_count" => stats.clue_question_ids.length,
    "distinct_set_count" => stats.set_titles.length,
    "literature_track_count" => track_count(stats, "literature"),
    "non_literature_track_count" => non_literature_track_count(stats),
    "dominant_track" => dominant_track(stats),
    "source_counts_json" => JSON.generate(stats.source_counts.sort.to_h),
    "form_counts_json" => JSON.generate(stats.form_counts.sort.to_h),
    "answerline_form_counts_json" => JSON.generate(stats.answerline_form_counts.sort.to_h),
    "track_counts_json" => JSON.generate(stats.track_counts.sort.to_h),
    "literary_signal_count" => stats.literary_signal_count,
    "non_literary_signal_count" => stats.non_literary_signal_count,
    "adjudication_decision" => adjudication_decision(row[:adjudication]),
    "adjudication_reason" => adjudication_reason(row[:adjudication]),
    "recommended_action" => recommended_action,
    "llm_batch_eligible" => "yes",
    "notes" => notes,
    "example_snippet" => safe_tsv(example.fetch("snippet", ""))
  }
end

def build_audit_queue_rows(score_rows)
  queue_rows = []
  score_rows.each do |row|
    audit_queue_specs_for(row).each do |queue_name, action, notes|
      queue_rows << audit_queue_row("", queue_name, row, action, notes)
    end
  end

  queue_rank = {
    "rejected_suspicious" => 0,
    "accepted_suspicious" => 1,
    "high_salience_review" => 2,
    "generic_short_title" => 3,
    "alias_split_candidate" => 4
  }
  queue_rows.sort_by! do |queue_row|
    [queue_rank.fetch(queue_row["queue_name"], 99), -queue_row["priority_score"].to_f, queue_row["canonical_title"]]
  end
  queue_rows.each_with_index do |queue_row, index|
    queue_row["queue_id"] = "qb_lit_audit_#{(index + 1).to_s.rjust(6, "0")}"
  end
end

def build_llm_review_rows(audit_rows)
  audit_rows
    .select { |row| row["adjudication_decision"].to_s.empty? }
    .first(LLM_REVIEW_QUEUE_LIMIT)
    .map do |row|
      {
        "queue_id" => row["queue_id"],
        "queue_name" => row["queue_name"],
        "task" => "Classify this quizbowl-derived literature-canon candidate as accept_literary_work, reject_non_literary, split_or_merge, or needs_human_review. Use the evidence fields only; do not invent bibliography.",
        "canonical_title" => row["canonical_title"],
        "current_status" => row["current_status"],
        "recommended_action" => row["recommended_action"],
        "counts" => {
          "total_questions" => row["total_question_count"],
          "answerline_questions" => row["answerline_question_count"],
          "clue_mentions" => row["clue_mention_question_count"],
          "distinct_sets" => row["distinct_set_count"],
          "literary_signals" => row["literary_signal_count"],
          "non_literary_signals" => row["non_literary_signal_count"]
        },
        "source_counts" => JSON.parse(row["source_counts_json"]),
        "form_counts" => JSON.parse(row["form_counts_json"]),
        "answerline_form_counts" => JSON.parse(row["answerline_form_counts_json"]),
        "quizbowl_track_counts" => JSON.parse(row["track_counts_json"]),
        "example_snippet" => row["example_snippet"]
      }
    end
end

def scan_bounds(db, limit)
  row = db.get_first_row(<<~SQL)
    SELECT MIN(id) AS min_id, MAX(id) AS max_id, COUNT(*) AS row_count
    FROM archive_parsed_questions
    WHERE clue_text IS NOT NULL
      AND answerline IS NOT NULL
  SQL
  min_id = row["min_id"].to_i
  max_id = row["max_id"].to_i
  row_count = row["row_count"].to_i

  if limit && limit < row_count
    max_id = db.get_first_value(
      <<~SQL,
        SELECT id
        FROM archive_parsed_questions
        WHERE clue_text IS NOT NULL
          AND answerline IS NOT NULL
        ORDER BY id
        LIMIT 1 OFFSET ?
      SQL
      limit - 1
    ).to_i
    row_count = limit
  end

  [min_id, max_id, row_count]
end

def chunk_ranges(min_id, max_id, jobs)
  jobs = [jobs.to_i, 1].max
  return [[min_id, max_id]] if jobs == 1 || min_id >= max_id

  step = ((max_id - min_id + 1).to_f / jobs).ceil
  ranges = []
  start_id = min_id
  while start_id <= max_id
    end_id = [start_id + step - 1, max_id].min
    ranges << [start_id, end_id]
    start_id = end_id + 1
  end
  ranges
end

def open_worker_db(path)
  db = SQLite3::Database.new(path, readonly: true)
  db.results_as_hash = true
  db.busy_timeout = 30_000
  db
end

def scan_sql_for_range
  <<~SQL
    SELECT id, set_title, year, question_type, clue_text, answerline
    FROM archive_parsed_questions
    WHERE clue_text IS NOT NULL
      AND answerline IS NOT NULL
      AND id BETWEEN ? AND ?
    ORDER BY id
  SQL
end

def load_marshal(path)
  File.open(path, "rb") { |file| Marshal.load(file) }
end

def dump_marshal(path, payload)
  File.open(path, "wb") { |file| Marshal.dump(payload, file) }
end

def cleanup_paths(paths)
  paths.each do |path|
    FileUtils.rm_f(path)
    FileUtils.rm_f("#{path}.error")
  end
end

def worker_tmp_dir(out_dir)
  File.join(out_dir, ".quizbowl_lit_tmp")
end

def spawn_range_workers(label, ranges, options, extra_args = [])
  tmp_dir = worker_tmp_dir(options[:out_dir])
  FileUtils.mkdir_p(tmp_dir)
  workers = ranges.each_with_index.map do |(start_id, end_id), index|
    path = File.join(tmp_dir, "#{label}_#{index.to_s.rjust(3, "0")}_#{Process.pid}.marshal")
    error_path = "#{path}.error"
    args = [
      RbConfig.ruby,
      File.expand_path(__FILE__),
      "--worker", label,
      "--db", options[:db_path],
      "--out-dir", options[:out_dir],
      "--range-start", start_id.to_s,
      "--range-end", end_id.to_s,
      "--worker-index", (index + 1).to_s,
      "--tmp-path", path,
      "--max-clue-chars", options[:max_clue_chars].to_s,
      "--progress-every", options[:progress_every].to_s
    ] + extra_args.flatten
    pid = Process.spawn(*args)
    { pid: pid, path: path, error_path: error_path, index: index }
  end

  failures = []
  workers.each do |worker|
    _pid, status = Process.wait2(worker[:pid])
    failures << worker unless status.success?
  end

  unless failures.empty?
    messages = failures.map do |worker|
      if File.exist?(worker[:error_path])
        File.read(worker[:error_path])
      else
        "#{label} worker #{worker[:index] + 1} exited unsuccessfully"
      end
    end
    raise messages.join("\n")
  end

  workers.sort_by { |worker| worker[:index] }.map { |worker| worker[:path] }
end

def run_pass1_range(options, track_by_question_id, start_id, end_id, worker_index, started)
  local_stats = {}
  local_answerline_seed_stats = {}
  processed = 0
  skipped_long = 0
  db = open_worker_db(options[:db_path])

  db.execute(scan_sql_for_range, start_id, end_id) do |row|
    processed += 1
    row["track_id"] = track_by_question_id[row["id"].to_i]
    clue_text = row["clue_text"].to_s
    answerline = row["answerline"].to_s
    if clue_text.length > options[:max_clue_chars]
      skipped_long += 1
      next
    end

    if (form = prompt_form(clue_text))
      answerline_variants(answerline).each do |title|
        normalized = normalize_title(title)
        add_observation(local_stats, normalized, title, "raw_answerline_work_prompt", form, row, snippet_for(clue_text, 0))
        add_observation(local_answerline_seed_stats, normalized, title, "raw_answerline_work_prompt", form, row, snippet_for(clue_text, 0))
      end
    end

    unless clue_text.match?(ANSWER_MARKER_RE)
      extract_clue_title_candidates(clue_text).each do |match|
        normalized = normalize_title(match[:title])
        add_observation(local_stats, normalized, match[:title], match[:source], match[:form_hint], row, match[:snippet])
      end
    end

    if options[:progress_every].positive? && (processed % options[:progress_every]).zero?
      warn "  pass1 worker=#{worker_index} processed=#{processed} range=#{start_id}-#{end_id} elapsed=#{(Time.now - started).round(1)}s"
    end
  end

  db.close
  {
    stats_by_key: local_stats,
    answerline_seed_stats: local_answerline_seed_stats,
    processed: processed,
    skipped_long: skipped_long
  }
end

def run_parallel_pass1(options, db, track_by_question_id, started)
  min_id, max_id, row_count = scan_bounds(db, options[:limit])
  db.close
  ranges = chunk_ranges(min_id, max_id, [options[:jobs], row_count].min)
  warn "Pass 1: deriving work-title candidates from raw archive_parsed_questions with #{ranges.length} workers"
  tmp_dir = worker_tmp_dir(options[:out_dir])
  FileUtils.mkdir_p(tmp_dir)
  track_map_path = File.join(tmp_dir, "track_map_#{Process.pid}.marshal")
  dump_marshal(track_map_path, track_by_question_id)
  partial_paths = spawn_range_workers("pass1", ranges, options, ["--track-map", track_map_path])

  stats_by_key = {}
  answerline_seed_stats = {}
  processed = 0
  skipped_long = 0
  begin
    partial_paths.each do |path|
      payload = load_marshal(path)
      merge_stats_by_key!(stats_by_key, payload[:stats_by_key])
      merge_stats_by_key!(answerline_seed_stats, payload[:answerline_seed_stats])
      processed += payload[:processed]
      skipped_long += payload[:skipped_long]
    end
  ensure
    cleanup_paths(partial_paths + [track_map_path])
  end
  warn "  pass1 merged processed=#{processed} candidates=#{stats_by_key.length} answerline_candidates=#{answerline_seed_stats.length} elapsed=#{(Time.now - started).round(1)}s"

  [stats_by_key, answerline_seed_stats, processed, skipped_long]
end

def run_pass2_range(options, seed_index, track_by_question_id, start_id, end_id, worker_index, started)
  matches = []
  processed = 0
  db = open_worker_db(options[:db_path])

  db.execute(scan_sql_for_range, start_id, end_id) do |row|
    processed += 1
    row["track_id"] = track_by_question_id[row["id"].to_i]
    clue_text = row["clue_text"].to_s
    next if clue_text.length > options[:max_clue_chars]
    next if clue_text.match?(ANSWER_MARKER_RE)

    find_seed_clue_matches(clue_text, seed_index).each do |match|
      matches << {
        "normalized" => normalize_title(match[:title]),
        "title" => match[:title],
        "source" => match[:source],
        "form_hint" => match[:form_hint],
        "snippet" => match[:snippet],
        "row" => {
          "id" => row["id"].to_i,
          "set_title" => row["set_title"].to_s,
          "year" => row["year"].to_i,
          "question_type" => row["question_type"].to_s,
          "track_id" => row["track_id"].to_s
        }
      }
    end

    if options[:progress_every].positive? && (processed % options[:progress_every]).zero?
      warn "  pass2 worker=#{worker_index} processed=#{processed} matches=#{matches.length} range=#{start_id}-#{end_id} elapsed=#{(Time.now - started).round(1)}s"
    end
  end

  db.close
  { processed: processed, matches: matches }
end

def run_parallel_pass2(options, seed_index, track_by_question_id, stats_by_key, started)
  bounds_db = open_worker_db(options[:db_path])
  min_id, max_id, row_count = scan_bounds(bounds_db, options[:limit])
  bounds_db.close
  ranges = chunk_ranges(min_id, max_id, [options[:jobs], row_count].min)
  warn "Pass 2: counting clue-text mentions with #{ranges.length} workers"
  tmp_dir = worker_tmp_dir(options[:out_dir])
  FileUtils.mkdir_p(tmp_dir)
  track_map_path = File.join(tmp_dir, "track_map_#{Process.pid}.marshal")
  seed_index_path = File.join(tmp_dir, "seed_index_#{Process.pid}.marshal")
  dump_marshal(track_map_path, track_by_question_id)
  dump_marshal(seed_index_path, seed_index)
  partial_paths = spawn_range_workers(
    "pass2",
    ranges,
    options,
    ["--track-map", track_map_path, "--seed-index", seed_index_path]
  )

  processed = 0
  begin
    partial_paths.each do |path|
      payload = load_marshal(path)
      processed += payload[:processed]
      payload[:matches].each do |match|
        add_observation(
          stats_by_key,
          match["normalized"],
          match["title"],
          match["source"],
          match["form_hint"],
          match["row"],
          match["snippet"]
        )
      end
    end
  ensure
    cleanup_paths(partial_paths + [track_map_path, seed_index_path])
  end
  warn "  pass2 merged processed=#{processed} elapsed=#{(Time.now - started).round(1)}s"
  processed
end

def parse_options
  options = {
    db_path: DEFAULT_DB,
    out_dir: DEFAULT_OUT,
    data_out: DEFAULT_DATA_OUT,
    adjudications_path: DEFAULT_ADJUDICATIONS,
    jobs: 1,
    worker: nil,
    range_start: nil,
    range_end: nil,
    worker_index: 1,
    tmp_path: nil,
    track_map_path: nil,
    seed_index_path: nil,
    threshold: 4,
    limit: nil,
    max_clue_chars: 6_000,
    progress_every: 250_000
  }

  OptionParser.new do |parser|
    parser.on("--db PATH") { |value| options[:db_path] = value }
    parser.on("--out-dir PATH") { |value| options[:out_dir] = value }
    parser.on("--data-out PATH") { |value| options[:data_out] = value }
    parser.on("--adjudications PATH") { |value| options[:adjudications_path] = value }
    parser.on("--jobs N", Integer) { |value| options[:jobs] = value }
    parser.on("--worker NAME") { |value| options[:worker] = value }
    parser.on("--range-start N", Integer) { |value| options[:range_start] = value }
    parser.on("--range-end N", Integer) { |value| options[:range_end] = value }
    parser.on("--worker-index N", Integer) { |value| options[:worker_index] = value }
    parser.on("--tmp-path PATH") { |value| options[:tmp_path] = value }
    parser.on("--track-map PATH") { |value| options[:track_map_path] = value }
    parser.on("--seed-index PATH") { |value| options[:seed_index_path] = value }
    parser.on("--threshold N", Integer) { |value| options[:threshold] = value }
    parser.on("--limit N", Integer) { |value| options[:limit] = value }
    parser.on("--max-clue-chars N", Integer) { |value| options[:max_clue_chars] = value }
    parser.on("--progress-every N", Integer) { |value| options[:progress_every] = value }
  end.parse!

  options
end

def run_worker(options)
  raise "--tmp-path is required for worker mode" unless options[:tmp_path]
  raise "--track-map is required for worker mode" unless options[:track_map_path]
  raise "--range-start and --range-end are required for worker mode" unless options[:range_start] && options[:range_end]

  started = Time.now
  track_by_question_id = load_marshal(options[:track_map_path])
  payload = case options[:worker]
  when "pass1"
    run_pass1_range(
      options,
      track_by_question_id,
      options[:range_start],
      options[:range_end],
      options[:worker_index],
      started
    )
  when "pass2"
    raise "--seed-index is required for pass2 worker mode" unless options[:seed_index_path]

    seed_index = load_marshal(options[:seed_index_path])
    run_pass2_range(
      options,
      seed_index,
      track_by_question_id,
      options[:range_start],
      options[:range_end],
      options[:worker_index],
      started
    )
  else
    raise "Unknown worker mode: #{options[:worker]}"
  end

  dump_marshal(options[:tmp_path], payload)
rescue StandardError => e
  File.write("#{options[:tmp_path]}.error", e.full_message) if options[:tmp_path]
  warn "#{options[:worker]} worker #{options[:worker_index]} failed: #{e.class}: #{e.message}"
  exit 1
end

def main
  options = parse_options
  if options[:worker]
    run_worker(options)
    return
  end

  raise "Missing quizbowl database: #{options[:db_path]}" unless File.exist?(options[:db_path])

  FileUtils.mkdir_p(options[:out_dir])
  FileUtils.mkdir_p(File.dirname(options[:data_out]))

  db = SQLite3::Database.new(options[:db_path], readonly: true)
  db.results_as_hash = true
  db.busy_timeout = 30_000

  adjudications = load_adjudications(options[:adjudications_path])
  alias_map, alias_canonical_titles = load_alias_rules(options[:adjudications_path])
  warn "Loaded #{adjudications.values.uniq.length} adjudications from #{options[:adjudications_path]}"
  warn "Loaded #{alias_map.length} manual alias rules from #{options[:adjudications_path]}" unless alias_map.empty?
  warn "Loading quizbowl category diagnostics from archive_practice_questions"
  track_by_question_id = load_track_id_map(db)
  warn "  loaded track labels for #{track_by_question_id.length} parsed questions"
  started = Time.now
  options[:jobs] = [options[:jobs].to_i, 1].max

  stats_by_key = {}
  answerline_seed_stats = {}
  processed = 0
  skipped_long = 0

  sql = <<~SQL
    SELECT id, set_title, year, question_type, clue_text, answerline
    FROM archive_parsed_questions
    WHERE clue_text IS NOT NULL
      AND answerline IS NOT NULL
    ORDER BY id
  SQL

  if options[:jobs] > 1
    stats_by_key, answerline_seed_stats, processed, skipped_long =
      run_parallel_pass1(options, db, track_by_question_id, started)
  else
    warn "Pass 1: deriving work-title candidates from raw archive_parsed_questions"
    db.execute(sql) do |row|
      break if options[:limit] && processed >= options[:limit]

      processed += 1

      row["track_id"] = track_by_question_id[row["id"].to_i]
      clue_text = row["clue_text"].to_s
      answerline = row["answerline"].to_s
      if clue_text.length > options[:max_clue_chars]
        skipped_long += 1
        next
      end

      if (form = prompt_form(clue_text))
        answerline_variants(answerline).each do |title|
          normalized = normalize_title(title)
          add_observation(stats_by_key, normalized, title, "raw_answerline_work_prompt", form, row, snippet_for(clue_text, 0))
          add_observation(answerline_seed_stats, normalized, title, "raw_answerline_work_prompt", form, row, snippet_for(clue_text, 0))
        end
      end

      unless clue_text.match?(ANSWER_MARKER_RE)
        extract_clue_title_candidates(clue_text).each do |match|
          normalized = normalize_title(match[:title])
          add_observation(stats_by_key, normalized, match[:title], match[:source], match[:form_hint], row, match[:snippet])
        end
      end

      if options[:progress_every].positive? && (processed % options[:progress_every]).zero?
        warn "  pass1 processed=#{processed} candidates=#{stats_by_key.length} answerline_candidates=#{answerline_seed_stats.length} elapsed=#{(Time.now - started).round(1)}s"
      end
    end
  end

  applied_aliases = apply_alias_rules!(stats_by_key, alias_map, alias_canonical_titles)
  apply_alias_rules!(answerline_seed_stats, alias_map, alias_canonical_titles)
  warn "Applied #{applied_aliases} manual alias merges after pass 1" if applied_aliases.positive?

  seeds, seed_index, seed_basis_counts = build_seed_index(stats_by_key, options[:threshold])

  pass2_processed = if options[:jobs] > 1
    warn "Pass 2: counting clue-text mentions for #{seeds.length} work-title seeds from answerlines and clue extraction"
    run_parallel_pass2(options, seed_index, track_by_question_id, stats_by_key, started)
  else
    warn "Pass 2: counting clue-text mentions for #{seeds.length} work-title seeds from answerlines and clue extraction"
    single_pass2_processed = 0
    db.execute(sql) do |row|
      break if options[:limit] && single_pass2_processed >= options[:limit]

      single_pass2_processed += 1

      row["track_id"] = track_by_question_id[row["id"].to_i]
      clue_text = row["clue_text"].to_s
      next if clue_text.length > options[:max_clue_chars]
      next if clue_text.match?(ANSWER_MARKER_RE)

      find_seed_clue_matches(clue_text, seed_index).each do |match|
        normalized = normalize_title(match[:title])
        add_observation(stats_by_key, normalized, match[:title], match[:source], match[:form_hint], row, match[:snippet])
      end

      if options[:progress_every].positive? && (single_pass2_processed % options[:progress_every]).zero?
        warn "  pass2 processed=#{single_pass2_processed} elapsed=#{(Time.now - started).round(1)}s"
      end
    end
    single_pass2_processed
  end

  selected_stats = stats_by_key.values.select { |stats| stats.question_ids.length >= options[:threshold] }
  score_rows = selected_stats.map do |stats|
    title = canonical_title(stats)
    work_id = candidate_id_for(title)
    base_review_status = review_status_for(stats)
    adjudication = adjudication_for(adjudications, title, work_id)
    review_status = manual_status_from_adjudication(adjudication, base_review_status)
    score = salience_score(stats)
    total_count = stats.question_ids.length
    tier = tier_for(score, review_status, total_count, stats.set_titles.length, stats.years.length)
    {
      stats: stats,
      title: title,
      work_id: work_id,
      base_review_status: base_review_status,
      review_status: review_status,
      adjudication: adjudication,
      score: score,
      tier: tier
    }
  end

  score_rows.sort_by! do |row|
    stats = row[:stats]
    [
      -row[:score],
      -stats.answerline_question_ids.length,
      -stats.clue_question_ids.length,
      row[:title]
    ]
  end

  data_rows = []
  score_tsv_rows = []
  candidate_tsv_rows = []
  cluster_tsv_rows = []
  mention_rows = []

  score_rows.each_with_index do |row, index|
    stats = row[:stats]
    title = row[:title]
    work_id = candidate_id_for(title)
    years = stats.years.to_a.sort
    source_counts = stats.source_counts.sort.to_h
    form_counts = stats.form_counts.sort.to_h
    answerline_form_counts = stats.answerline_form_counts.sort.to_h
    track_counts = stats.track_counts.sort.to_h
    examples = stats.examples.first(3)
    answerline_count = stats.answerline_question_ids.length
    clue_count = stats.clue_question_ids.length
    total_count = stats.question_ids.length

    if row[:review_status] == "accepted_likely_work"
      data_rows << {
        "id" => work_id,
        "rank" => data_rows.length + 1,
        "audit_rank" => index + 1,
        "title" => title,
        "tier" => row[:tier],
        "review_status" => row[:review_status],
        "base_review_status" => row[:base_review_status],
        "quizbowl_salience_score" => format("%.4f", row[:score]).to_f,
        "total_question_count" => total_count,
        "answerline_question_count" => answerline_count,
        "clue_mention_question_count" => clue_count,
        "distinct_set_count" => stats.set_titles.length,
        "distinct_year_count" => years.length,
        "first_year" => years.first,
        "last_year" => years.last,
        "tossup_count" => stats.question_type_counts["tossup"],
        "bonus_count" => stats.question_type_counts["bonus_part"] + stats.question_type_counts["bonus"],
        "form_hint" => stats.form_counts.max_by { |_, count| count }&.first || "unknown",
        "quizbowl_track_counts" => track_counts,
        "adjudication_decision" => adjudication_decision(row[:adjudication]),
        "adjudication_reason" => adjudication_reason(row[:adjudication]),
        "evidence_basis" => "raw_archive_parsed_questions_answerlines_and_clue_text",
        "examples" => examples
      }
    end

    score_tsv_rows << {
      "work_id" => work_id,
      "rank" => index + 1,
      "canonical_title" => safe_tsv(title),
      "total_question_count" => total_count,
      "answerline_question_count" => answerline_count,
      "clue_mention_question_count" => clue_count,
      "distinct_set_count" => stats.set_titles.length,
      "distinct_year_count" => years.length,
      "first_year" => years.first,
      "last_year" => years.last,
      "tossup_count" => stats.question_type_counts["tossup"],
      "bonus_count" => stats.question_type_counts["bonus_part"] + stats.question_type_counts["bonus"],
      "quizbowl_salience_score" => format("%.4f", row[:score]),
      "tier" => row[:tier],
      "review_status" => row[:review_status],
      "base_review_status" => row[:base_review_status],
      "source_counts_json" => JSON.generate(source_counts),
      "form_counts_json" => JSON.generate(form_counts),
      "answerline_form_counts_json" => JSON.generate(answerline_form_counts),
      "track_counts_json" => JSON.generate(track_counts),
      "literary_signal_count" => stats.literary_signal_count,
      "non_literary_signal_count" => stats.non_literary_signal_count,
      "adjudication_decision" => adjudication_decision(row[:adjudication]),
      "adjudication_reason" => adjudication_reason(row[:adjudication]),
      "examples_json" => JSON.generate(stats.examples.first(5))
    }

    candidate_tsv_rows << {
      "candidate_id" => work_id,
      "canonical_title" => safe_tsv(title),
      "normalized_title" => stats.normalized_title,
      "form_hint" => stats.form_counts.max_by { |_, count| count }&.first || "unknown",
      "candidate_source" => source_counts.map { |source, count| "#{source}:#{count}" }.join(";"),
      "form_counts_json" => JSON.generate(form_counts),
      "answerline_form_counts_json" => JSON.generate(answerline_form_counts),
      "track_counts_json" => JSON.generate(track_counts),
      "disambiguation_status" => row[:review_status],
      "base_disambiguation_status" => row[:base_review_status],
      "adjudication_decision" => adjudication_decision(row[:adjudication]),
      "adjudication_reason" => adjudication_reason(row[:adjudication]),
      "total_question_count" => total_count,
      "answerline_question_count" => answerline_count,
      "clue_mention_question_count" => clue_count,
      "distinct_set_count" => stats.set_titles.length,
      "distinct_year_count" => years.length,
      "notes" => "Evidence is generated from raw archive_parsed_questions answerlines and clue text; quizbowl track labels are diagnostic metadata only."
    }

    cluster_tsv_rows << {
      "work_id" => work_id,
      "canonical_title" => safe_tsv(title),
      "normalized_title" => stats.normalized_title,
      "title_variants_json" => JSON.generate(stats.display_counts.sort_by { |variant, count| [-count, variant] }.to_h),
      "cluster_status" => "normalized_title_cluster",
      "notes" => "Answerline variants and clue-text title variants are clustered by normalized title."
    }

    stats.examples.each do |example|
      mention_rows << {
        "work_id" => work_id,
        "canonical_title" => safe_tsv(title),
        "question_id" => example["question_id"],
        "set_title" => safe_tsv(example["set_title"]),
        "year" => example["year"],
        "question_type" => example["question_type"],
        "match_type" => example["match_type"],
        "snippet" => safe_tsv(example["snippet"])
      }
    end
  end

  review_rows = score_rows
    .select { |row| !rejected_review_status?(row[:review_status]) && (row[:review_status] != "accepted_likely_work" || high_risk_title?(row[:title]) || person_like_title?(row[:title])) }
    .first(500)
    .map do |row|
      stats = row[:stats]
      {
        "candidate_id" => candidate_id_for(row[:title]),
        "canonical_title" => safe_tsv(row[:title]),
        "review_reason" => row[:review_status],
        "base_review_reason" => row[:base_review_status],
        "total_question_count" => stats.question_ids.length,
        "answerline_question_count" => stats.answerline_question_ids.length,
        "clue_mention_question_count" => stats.clue_question_ids.length,
        "distinct_set_count" => stats.set_titles.length,
        "source_counts_json" => JSON.generate(stats.source_counts.sort.to_h),
        "form_counts_json" => JSON.generate(stats.form_counts.sort.to_h),
        "answerline_form_counts_json" => JSON.generate(stats.answerline_form_counts.sort.to_h),
        "track_counts_json" => JSON.generate(stats.track_counts.sort.to_h),
        "literary_signal_count" => stats.literary_signal_count,
        "non_literary_signal_count" => stats.non_literary_signal_count,
        "adjudication_decision" => adjudication_decision(row[:adjudication]),
        "adjudication_reason" => adjudication_reason(row[:adjudication]),
        "example_snippet" => safe_tsv(stats.examples.first&.fetch("snippet", "") || "")
      }
    end

  rejected_rows = score_rows
    .select { |row| rejected_review_status?(row[:review_status]) }
    .map do |row|
      stats = row[:stats]
      {
        "candidate_id" => candidate_id_for(row[:title]),
        "canonical_title" => safe_tsv(row[:title]),
        "rejection_reason" => row[:review_status],
        "base_rejection_reason" => row[:base_review_status],
        "total_question_count" => stats.question_ids.length,
        "answerline_question_count" => stats.answerline_question_ids.length,
        "clue_mention_question_count" => stats.clue_question_ids.length,
        "distinct_set_count" => stats.set_titles.length,
        "source_counts_json" => JSON.generate(stats.source_counts.sort.to_h),
        "form_counts_json" => JSON.generate(stats.form_counts.sort.to_h),
        "answerline_form_counts_json" => JSON.generate(stats.answerline_form_counts.sort.to_h),
        "track_counts_json" => JSON.generate(stats.track_counts.sort.to_h),
        "literary_signal_count" => stats.literary_signal_count,
        "non_literary_signal_count" => stats.non_literary_signal_count,
        "adjudication_decision" => adjudication_decision(row[:adjudication]),
        "adjudication_reason" => adjudication_reason(row[:adjudication]),
        "example_snippet" => safe_tsv(stats.examples.first&.fetch("snippet", "") || "")
      }
    end

  audit_queue_rows = build_audit_queue_rows(score_rows)
  llm_review_rows = build_llm_review_rows(audit_queue_rows)

  write_tsv(
    File.join(options[:out_dir], "quizbowl_lit_title_candidates.tsv"),
    %w[candidate_id canonical_title normalized_title form_hint candidate_source form_counts_json answerline_form_counts_json track_counts_json disambiguation_status base_disambiguation_status adjudication_decision adjudication_reason total_question_count answerline_question_count clue_mention_question_count distinct_set_count distinct_year_count notes],
    candidate_tsv_rows
  )
  write_tsv(
    File.join(options[:out_dir], "quizbowl_lit_canon_scores.tsv"),
    %w[work_id rank canonical_title total_question_count answerline_question_count clue_mention_question_count distinct_set_count distinct_year_count first_year last_year tossup_count bonus_count quizbowl_salience_score tier review_status base_review_status source_counts_json form_counts_json answerline_form_counts_json track_counts_json literary_signal_count non_literary_signal_count adjudication_decision adjudication_reason examples_json],
    score_tsv_rows
  )
  write_tsv(
    File.join(options[:out_dir], "quizbowl_lit_clusters.tsv"),
    %w[work_id canonical_title normalized_title title_variants_json cluster_status notes],
    cluster_tsv_rows
  )
  write_tsv(
    File.join(options[:out_dir], "quizbowl_lit_mentions.tsv"),
    %w[work_id canonical_title question_id set_title year question_type match_type snippet],
    mention_rows
  )
  write_tsv(
    File.join(options[:out_dir], "quizbowl_lit_false_positive_review.tsv"),
    %w[candidate_id canonical_title review_reason base_review_reason total_question_count answerline_question_count clue_mention_question_count distinct_set_count source_counts_json form_counts_json answerline_form_counts_json track_counts_json literary_signal_count non_literary_signal_count adjudication_decision adjudication_reason example_snippet],
    review_rows
  )
  write_tsv(
    File.join(options[:out_dir], "quizbowl_lit_rejected.tsv"),
    %w[candidate_id canonical_title rejection_reason base_rejection_reason total_question_count answerline_question_count clue_mention_question_count distinct_set_count source_counts_json form_counts_json answerline_form_counts_json track_counts_json literary_signal_count non_literary_signal_count adjudication_decision adjudication_reason example_snippet],
    rejected_rows
  )
  write_tsv(
    File.join(options[:out_dir], "quizbowl_lit_audit_queue.tsv"),
    %w[queue_id queue_name priority_score work_id canonical_title current_status base_status tier total_question_count answerline_question_count clue_mention_question_count distinct_set_count literature_track_count non_literature_track_count dominant_track source_counts_json form_counts_json answerline_form_counts_json track_counts_json literary_signal_count non_literary_signal_count adjudication_decision adjudication_reason recommended_action llm_batch_eligible notes example_snippet],
    audit_queue_rows
  )
  write_jsonl(
    File.join(options[:out_dir], "quizbowl_lit_llm_review_queue.jsonl"),
    llm_review_rows
  )

  File.write(options[:data_out], data_rows.to_yaml)

  summary = {
    "generated_at" => Time.now.utc.iso8601,
    "db_path" => options[:db_path],
    "source_table" => "archive_parsed_questions",
    "evidence_fields" => [
      "archive_parsed_questions.answerline",
      "archive_parsed_questions.clue_text"
    ],
    "diagnostic_fields" => [
      "archive_practice_questions.track_id"
    ],
    "adjudications_path" => repo_relative_path(options[:adjudications_path]),
    "adjudication_count" => adjudications.values.uniq.length,
    "manual_alias_rule_count" => alias_map.length,
    "manual_aliases_applied_after_pass1" => applied_aliases,
    "jobs" => options[:jobs],
    "excluded_processed_inputs" => [
      "archive_canon_refinement_runs",
      "archive_canon_answerline_candidates"
    ],
    "threshold" => options[:threshold],
    "processed_rows" => processed,
    "skipped_long_clue_rows" => skipped_long,
    "raw_answerline_candidate_count" => answerline_seed_stats.length,
    "exact_match_seed_count" => seeds.length,
    "exact_match_seed_basis_counts" => seed_basis_counts.sort.to_h,
    "raw_candidate_count" => stats_by_key.length,
    "threshold_candidate_count" => score_rows.length,
    "public_data_count" => data_rows.length,
    "rejected_candidate_count" => rejected_rows.length,
    "audit_queue_count" => audit_queue_rows.length,
    "llm_review_queue_count" => llm_review_rows.length,
    "mention_rows" => mention_rows.length,
    "tier_counts" => score_rows.group_by { |row| row[:tier] }.transform_values(&:length),
    "review_status_counts" => score_rows.group_by { |row| row[:review_status] }.transform_values(&:length)
  }
  File.write(File.join(options[:out_dir], "quizbowl_lit_summary.json"), JSON.pretty_generate(summary) + "\n")

  method_report = <<~MARKDOWN
    # Quizbowl Literature Canon Method Report

    Generated: #{summary["generated_at"]}

    ## Corpus

    - Database: `#{options[:db_path]}`
    - Source table: `archive_parsed_questions`
    - Rows processed: #{processed}
    - Evidence fields: raw `answerline` and raw `clue_text`
    - Diagnostic field: `archive_practice_questions.track_id` for quizbowl category counts only
    - Adjudication file: `#{repo_relative_path(options[:adjudications_path])}` (#{adjudications.values.uniq.length} decisions)
    - Manual alias rules: #{alias_map.length} loaded, #{applied_aliases} applied after pass 1
    - Worker processes: #{options[:jobs]}
    - Explicitly not used for evidence: `archive_canon_refinement_runs`, `archive_canon_answerline_candidates`
    - Threshold: total distinct quizbowl questions >= #{options[:threshold]}

    ## Candidate Extraction

    - Raw answerline work candidates: #{answerline_seed_stats.length}
    - Exact-match work-title seeds from answerlines and clues: #{seeds.length}
    - Exact-match seed basis counts: #{seed_basis_counts.sort.map { |basis, count| "`#{basis}`=#{count}" }.join(", ")}
    - Raw normalized candidates: #{stats_by_key.length}
    - Candidates clearing threshold: #{score_rows.length}
    - Public YAML rows after accepted-work filtering: #{data_rows.length}
    - Rejected non-literature candidates: #{rejected_rows.length}
    - Audit queue rows: #{audit_queue_rows.length}
    - LLM review queue rows: #{llm_review_rows.length}
    - Evidence/example rows written: #{mention_rows.length}

    ## Review Routing

    - Accepted works require repeated quizbowl evidence and are strongest when raw answerline prompts identify the title as a literary form.
    - Non-literary context signals are counted across all observed snippets, not just displayed examples.
    - Strong raw answerline forms such as novel, play, poem, story, epic, saga, and collection can override noisy clue mentions from music, film, or other adaptation contexts.
    - Generic book/work/essay prompts do not override non-literary context dominance; those candidates are rejected from the public literature canon.

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
    - `quizbowl_lit_rejected.tsv`
    - `quizbowl_lit_audit_queue.tsv`
    - `quizbowl_lit_llm_review_queue.jsonl`
    - `_data/quizbowl_literature_canon.yml`

    ## Caveats

    This is an independent quizbowl-corpus build. It uses answerlines only when the raw question prompt asks for a literary work, then counts both answerline frequency and clue-text mentions. Quizbowl track labels are diagnostic metadata for audit and category sanity checks, not inclusion evidence.
  MARKDOWN
  File.write(File.join(options[:out_dir], "quizbowl_lit_method_report.md"), method_report)

  warn "Done. threshold_candidates=#{score_rows.length} mention_rows=#{mention_rows.length}"
  warn "Wrote #{options[:out_dir]} and #{options[:data_out]}"
end

main if $PROGRAM_NAME == __FILE__
