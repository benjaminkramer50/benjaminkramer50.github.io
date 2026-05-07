#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "json"
require "optparse"
require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DEFAULT_CANON = File.join(ROOT, "_data", "quizbowl_literature_canon.yml")
DEFAULT_OUT_DIR = File.join(ROOT, "_planning", "quizbowl_lit_canon")

CREATOR_RISK_TSV = "quizbowl_lit_creator_risk.tsv"
DUPLICATE_RISK_TSV = "quizbowl_lit_duplicate_risk.tsv"
BOUNDARY_RISK_TSV = "quizbowl_lit_boundary_risk.tsv"
RELEASE_QUEUE_TSV = "quizbowl_lit_release_queue.tsv"
SUMMARY_MD = "quizbowl_lit_release_gates.md"
SUMMARY_JSON = "quizbowl_lit_release_gate_summary.json"

CREATOR_HEADERS = %w[
  rank title total_question_count tier creator_source creator_confidence creators
  risk_level risk_reasons suggested_action
].freeze

DUPLICATE_HEADERS = %w[
  rank title total_question_count tier matched_title matched_rank matched_count
  match_type risk_reason suggested_action
].freeze

BOUNDARY_HEADERS = %w[
  rank title total_question_count tier boundary_domain boundary_reason dominant_quizbowl_track
  quizbowl_track_profile literature_track_count non_literature_track_count work_form
  reading_unit region_or_tradition suggested_action
].freeze

RELEASE_HEADERS = %w[
  rank title total_question_count tier gate_reasons issue_buckets creator_source
  creators chronology_label chronology_source duplicate_matches boundary_domains suggested_action
].freeze

COUNTRY_OR_LANGUAGE_RE = /\b(?:afghanistan|africa|america|arabic|argentina|australia|austrian|bengali|britain|canada|chinese|czech|egypt|england|english|france|french|german|greece|greek|india|indian|ireland|irish|italian|japan|japanese|latin|persian|poland|polish|russia|russian|sanskrit|scotland|spanish|sudan|turkish|united states|wales|welsh)\b/i
FRAGMENT_CREATOR_RE = /(?:\d|~|\?|!|\bpoints?\b|\banswer\b|\bbonus\b|\btossup\b|\baccept\b|\bprompt\b)/i
ORG_OR_PLACE_RE = /\b(?:academy|association|city|college|committee|country|empire|kingdom|nation|province|quarter|republic|school|society|state|university)\b/i

SCRIPTURE_RE = /\b(?:adi granth|apocrypha|avesta|bhagavad gita|bible|biblical|book of (?:daniel|ecclesiastes|genesis|isaiah|job|jonah|luke|ruth)|dhammapada|ecclesiastes|epistle|gospel|qur'?an|scripture|sutra|tanakh|upanishad|veda|zohar)\b/i
MYTH_OR_ORAL_RE = /\b(?:aesop|edda|epic|fairy|folklore|gilgamesh|kalevala|mabinogion|mahabharata|manas|myth|oral|popol vuh|ramayana|saga|sundiata|tale cycle)\b/i
PHIL_SOCSCI_RE = /\b(?:anthropology|civilization|communist manifesto|critique|discipline and punish|economics|feminism|gender|interpretation of dreams|linguistics|myth of sisyphus|orientalism|political|psychology|social|society|sociology|state|theory|wealth of nations)\b/i
MUSIC_PERFORMANCE_RE = /\b(?:aria|cantata|concerto|flute|music|opera|oratorio|requiem|sonata|song cycle|symphony|winterreise)\b/i

def parse_options
  options = {
    canon: DEFAULT_CANON,
    out_dir: DEFAULT_OUT_DIR
  }

  OptionParser.new do |parser|
    parser.on("--canon PATH") { |value| options[:canon] = value }
    parser.on("--out-dir PATH") { |value| options[:out_dir] = value }
  end.parse!

  options
end

def normalize_title(value)
  value.to_s
       .unicode_normalize(:nfkd)
       .downcase
       .gsub(/['’]/, "")
       .gsub(/&/, " and ")
       .gsub(/[^[:alnum:]]+/, " ")
       .gsub(/\s+/, " ")
       .strip
end

def normalize_articleless(value)
  normalize_title(value).sub(/\A(?:the|a|an)\s+/, "")
end

def track_counts(row)
  row["quizbowl_track_counts"].is_a?(Hash) ? row["quizbowl_track_counts"] : {}
end

def literature_count(row)
  track_counts(row)["literature"].to_i
end

def non_literature_count(row)
  track_counts(row).reject { |track, _| track == "literature" }.values.sum(&:to_i)
end

def creator_string(row)
  Array(row["creators"]).compact.join("; ")
end

def creator_ready?(row)
  row["creator_source"].to_s != "unknown" &&
    row["creator_source"].to_s != "quizbowl_author_answerline" &&
    Array(row["creators"]).any? { |creator| !creator.to_s.strip.empty? }
end

def chronology_ready?(row)
  row["chronology_source"].to_s != "unknown" && !row["chronology_needs_review"]
end

def default_path?(row)
  row["review_status"] == "accepted_likely_work" && creator_ready?(row) && chronology_ready?(row)
end

def creator_risk_reasons(row, public_title_keys)
  reasons = []
  source = row["creator_source"].to_s
  confidence = row["creator_confidence"].to_s
  creators = creator_string(row)
  normalized_creator = normalize_title(creators)

  reasons << "quizbowl_author_answerline_creator" if source == "quizbowl_author_answerline"
  reasons << "low_confidence_creator" if row["creator_confidence"].to_s == "low"
  reasons << "country_or_language_creator" if creators.match?(COUNTRY_OR_LANGUAGE_RE) && (source == "quizbowl_author_answerline" || confidence == "low")
  reasons << "answerline_fragment_creator" if creators.match?(FRAGMENT_CREATOR_RE)
  reasons << "organization_or_place_creator" if creators.match?(ORG_OR_PLACE_RE)
  reasons << "creator_matches_public_title" if source == "quizbowl_author_answerline" && public_title_keys.include?(normalized_creator)

  reasons
end

def creator_risk_level(row, reasons)
  return "high" if reasons.any? { |reason| reason != "quizbowl_author_answerline_creator" }
  return "high" if row["tier"] == "qb_core" || row["tier"] == "qb_major" || row["total_question_count"].to_i >= 40
  return "medium" if row["creator_source"].to_s == "quizbowl_author_answerline"

  "low"
end

def creator_risks(rows, public_title_keys)
  risks = []
  rows.each do |row|
    reasons = creator_risk_reasons(row, public_title_keys)
    next if reasons.empty?

    risks << {
      "rank" => row["rank"],
      "title" => row["title"],
      "total_question_count" => row["total_question_count"],
      "tier" => row["tier"],
      "creator_source" => row["creator_source"],
      "creator_confidence" => row["creator_confidence"],
      "creators" => creator_string(row),
      "risk_level" => creator_risk_level(row, reasons),
      "risk_reasons" => reasons.join("; "),
      "suggested_action" => "Replace with reviewed/manual/Wikidata creator or suppress from default path."
    }
  end

  risks.sort_by { |row| [row["risk_level"] == "high" ? 0 : 1, -row["total_question_count"].to_i, row["rank"].to_i] }
end

def title_components(title)
  components = []
  raw = title.to_s
  components << raw.sub(/\s*\(.+?\)\s*\z/, "") if raw.match?(/\(.+?\)\s*\z/)
  components.concat(raw.split(/\s+or\s+/i)) if raw.match?(/\s+or\s+/i)
  components.concat(raw.split(/\s*\/\s*/)) if raw.include?("/")
  if raw.include?(":")
    before, after = raw.split(":", 2)
    components << before
    components.concat(after.to_s.split(/\s+or\s+/i))
  end

  components
    .map { |component| component.gsub(/\A\s*(?:or|and)\s*,?\s*/i, "").strip }
    .reject { |component| normalize_title(component).length < 4 }
    .uniq
end

def duplicate_risks(rows)
  by_normalized = {}
  by_articleless = Hash.new { |hash, key| hash[key] = [] }

  rows.each do |row|
    key = normalize_title(row["title"])
    by_normalized[key] ||= row
    by_articleless[normalize_articleless(row["title"])] << row
  end

  risks = []
  rows.each do |row|
    title_components(row["title"]).each do |component|
      match = by_normalized[normalize_title(component)]
      next unless match
      next if match["id"] == row["id"]

      risks << duplicate_risk_row(row, match, "component_title_match", "Title component already exists as accepted public row.")
    end
  end

  by_articleless.each_value do |group|
    next unless group.length > 1

    group.combination(2).each do |a, b|
      next if protected_article_collision?(a["title"], b["title"])

      primary, matched = [a, b].sort_by { |row| row["rank"].to_i }
      risks << duplicate_risk_row(primary, matched, "article_variant_match", "Titles differ only by leading article.")
    end
  end

  risks
    .uniq { |row| [row["title"], row["matched_title"], row["match_type"]] }
    .sort_by { |row| [-row["total_question_count"].to_i, row["rank"].to_i, row["title"].to_s] }
end

def protected_article_collision?(title_a, title_b)
  pair = [normalize_title(title_a), normalize_title(title_b)].sort
  [
    ["invisible man", "the invisible man"],
    ["pearl", "the pearl"],
    ["stranger", "the stranger"],
    ["trial", "the trial"]
  ].include?(pair)
end

def duplicate_risk_row(row, match, match_type, reason)
  {
    "rank" => row["rank"],
    "title" => row["title"],
    "total_question_count" => row["total_question_count"],
    "tier" => row["tier"],
    "matched_title" => match["title"],
    "matched_rank" => match["rank"],
    "matched_count" => match["total_question_count"],
    "match_type" => match_type,
    "risk_reason" => reason,
    "suggested_action" => "Review as merge, alias, split, or protected title collision before release."
  }
end

def boundary_domain(row)
  text = [
    row["title"],
    row["work_form"],
    row["reading_unit"],
    row["region_or_tradition"],
    row["dominant_quizbowl_track"],
    creator_string(row)
  ].join(" ")

  track = row["dominant_quizbowl_track"].to_s
  return ["religion", "scripture_or_religious_text_signal"] if track == "religion" || text.match?(SCRIPTURE_RE)
  return ["philosophy_social_science", "philosophy_or_social_science_signal"] if %w[philosophy social_science].include?(track) || text.match?(PHIL_SOCSCI_RE)
  return ["mythology", "myth_or_oral_tradition_signal"] if track == "mythology" || text.match?(MYTH_OR_ORAL_RE)
  return ["music_performance", "music_or_performance_signal"] if %w[fine_arts pop_culture].include?(track) || text.match?(MUSIC_PERFORMANCE_RE)

  if row["quizbowl_track_profile"] == "non_literature_context" &&
     row["answerline_question_count"].to_i < 3 &&
     literature_count(row) < 10 &&
     non_literature_count(row) >= 40
    return ["adjacent_non_literature", "non_literature_context_dominates"]
  end

  nil
end

def boundary_risks(rows)
  risks = []
  rows.each do |row|
    domain_reason = boundary_domain(row)
    next unless domain_reason

    domain, reason = domain_reason
    next unless row["tier"] == "qb_core" || row["tier"] == "qb_major" || row["total_question_count"].to_i >= 20

    risks << {
      "rank" => row["rank"],
      "title" => row["title"],
      "total_question_count" => row["total_question_count"],
      "tier" => row["tier"],
      "boundary_domain" => domain,
      "boundary_reason" => reason,
      "dominant_quizbowl_track" => row["dominant_quizbowl_track"],
      "quizbowl_track_profile" => row["quizbowl_track_profile"],
      "literature_track_count" => literature_count(row),
      "non_literature_track_count" => non_literature_count(row),
      "work_form" => row["work_form"],
      "reading_unit" => row["reading_unit"],
      "region_or_tradition" => row["region_or_tradition"],
      "suggested_action" => "Set explicit boundary disposition: keep as literature, cross-list, route to sibling list, or reject."
    }
  end

  risks.sort_by { |row| [-row["total_question_count"].to_i, row["rank"].to_i] }
end

def release_queue(rows, creator_rows, duplicate_rows, boundary_rows)
  creator_by_title = creator_rows.group_by { |row| row["title"] }
  duplicate_by_title = duplicate_rows.group_by { |row| row["title"] }
  boundary_by_title = boundary_rows.group_by { |row| row["title"] }

  queue = []
  rows.each do |row|
    gate_reasons = []
    issue_buckets = []

    if row["rank"].to_i <= 1000 && row["chronology_source"].to_s == "unknown"
      gate_reasons << "rank_le_1000_unresolved_chronology"
      issue_buckets << "chronology"
    end
    if row["total_question_count"].to_i >= 40 && row["chronology_source"].to_s == "unknown"
      gate_reasons << "count_ge_40_unresolved_chronology"
      issue_buckets << "chronology"
    end
    if row["tier"] == "qb_major" && row["chronology_source"].to_s == "unknown"
      gate_reasons << "qb_major_unresolved_chronology"
      issue_buckets << "chronology"
    end
    if creator_by_title.key?(row["title"]) && (row["tier"] != "qb_contextual" || row["total_question_count"].to_i >= 40)
      gate_reasons << "creator_risk"
      issue_buckets << "creator"
    end
    if duplicate_by_title.key?(row["title"]) && (row["tier"] != "qb_contextual" || row["total_question_count"].to_i >= 40)
      gate_reasons << "duplicate_title_risk"
      issue_buckets << "duplicate"
    end
    if boundary_by_title.key?(row["title"]) && (row["tier"] != "qb_contextual" || row["total_question_count"].to_i >= 40)
      gate_reasons << "boundary_risk"
      issue_buckets << "boundary"
    end

    next if gate_reasons.empty?

    queue << {
      "rank" => row["rank"],
      "title" => row["title"],
      "total_question_count" => row["total_question_count"],
      "tier" => row["tier"],
      "gate_reasons" => gate_reasons.uniq.join("; "),
      "issue_buckets" => issue_buckets.uniq.join("; "),
      "creator_source" => row["creator_source"],
      "creators" => creator_string(row),
      "chronology_label" => row["chronology_label"],
      "chronology_source" => row["chronology_source"],
      "duplicate_matches" => Array(duplicate_by_title[row["title"]]).map { |risk| risk["matched_title"] }.uniq.join("; "),
      "boundary_domains" => Array(boundary_by_title[row["title"]]).map { |risk| risk["boundary_domain"] }.uniq.join("; "),
      "suggested_action" => release_action_for(issue_buckets)
    }
  end

  queue.sort_by { |row| [row["rank"].to_i, -row["total_question_count"].to_i, row["title"].to_s] }
end

def release_action_for(issue_buckets)
  buckets = issue_buckets.uniq
  return "Review duplicate/alias/split first, then rerun gates." if buckets.include?("duplicate")
  return "Set boundary disposition or route to sibling list before default release." if buckets.include?("boundary")
  return "Replace/suppress creator before default release." if buckets.include?("creator")
  return "Add conservative date metadata or keep outside default path." if buckets.include?("chronology")

  "Review before release."
end

def write_tsv(path, headers, rows)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def write_summary_md(path, summary, release_rows)
  top_rows = release_rows.first(30)
  lines = []
  lines << "# Quizbowl Literature Release Gates"
  lines << ""
  lines << "Generated from `_data/quizbowl_literature_canon.yml`."
  lines << ""
  lines << "## Counts"
  lines << ""
  lines << "- Public accepted rows: `#{summary.fetch("public_rows")}`"
  lines << "- Chronology-ready rows: `#{summary.fetch("chronology_ready_rows")}`"
  lines << "- Creator-ready rows: `#{summary.fetch("creator_ready_rows")}`"
  lines << "- Default reading-path rows: `#{summary.fetch("default_path_rows")}`"
  lines << "- Creator-risk rows: `#{summary.fetch("creator_risk_rows")}`"
  lines << "- Duplicate-risk rows: `#{summary.fetch("duplicate_risk_rows")}`"
  lines << "- Boundary-risk rows: `#{summary.fetch("boundary_risk_rows")}`"
  lines << "- Mandatory release-queue rows: `#{summary.fetch("release_queue_rows")}`"
  lines << ""
  lines << "## Stop Rule"
  lines << ""
  lines << "Do not manually clear the full unplaced backlog for v1. Resolve the mandatory release queue, fix the default-path UI, and leave the low-salience long tail in the Unplaced view."
  lines << ""
  lines << "## Top Release Queue"
  lines << ""
  lines << "| Rank | Count | Tier | Title | Gate Reasons | Issue Buckets | Action |"
  lines << "| ---: | ---: | --- | --- | --- | --- | --- |"
  top_rows.each do |row|
    lines << "| #{row["rank"]} | #{row["total_question_count"]} | `#{row["tier"]}` | #{row["title"]} | #{row["gate_reasons"]} | #{row["issue_buckets"]} | #{row["suggested_action"]} |"
  end
  lines << ""
  lines << "## Output Files"
  lines << ""
  lines << "- `#{CREATOR_RISK_TSV}`"
  lines << "- `#{DUPLICATE_RISK_TSV}`"
  lines << "- `#{BOUNDARY_RISK_TSV}`"
  lines << "- `#{RELEASE_QUEUE_TSV}`"
  lines << "- `#{SUMMARY_JSON}`"

  File.write(path, lines.join("\n") + "\n")
end

def main
  options = parse_options
  FileUtils.mkdir_p(options[:out_dir])

  rows = YAML.load_file(options[:canon]).select { |row| row["review_status"] == "accepted_likely_work" }
  public_title_keys = rows.map { |row| normalize_title(row["title"]) }.to_set

  creator_rows = creator_risks(rows, public_title_keys)
  duplicate_rows = duplicate_risks(rows)
  boundary_rows = boundary_risks(rows)
  release_rows = release_queue(rows, creator_rows, duplicate_rows, boundary_rows)

  summary = {
    "public_rows" => rows.length,
    "chronology_ready_rows" => rows.count { |row| chronology_ready?(row) },
    "creator_ready_rows" => rows.count { |row| creator_ready?(row) },
    "default_path_rows" => rows.count { |row| default_path?(row) },
    "creator_risk_rows" => creator_rows.length,
    "duplicate_risk_rows" => duplicate_rows.length,
    "boundary_risk_rows" => boundary_rows.length,
    "release_queue_rows" => release_rows.length,
    "release_queue_issue_counts" => release_rows
      .flat_map { |row| row["issue_buckets"].split(/;\s*/) }
      .each_with_object(Hash.new(0)) { |bucket, counts| counts[bucket] += 1 }
      .sort
      .to_h
  }

  write_tsv(File.join(options[:out_dir], CREATOR_RISK_TSV), CREATOR_HEADERS, creator_rows)
  write_tsv(File.join(options[:out_dir], DUPLICATE_RISK_TSV), DUPLICATE_HEADERS, duplicate_rows)
  write_tsv(File.join(options[:out_dir], BOUNDARY_RISK_TSV), BOUNDARY_HEADERS, boundary_rows)
  write_tsv(File.join(options[:out_dir], RELEASE_QUEUE_TSV), RELEASE_HEADERS, release_rows)
  File.write(File.join(options[:out_dir], SUMMARY_JSON), JSON.pretty_generate(summary) + "\n")
  write_summary_md(File.join(options[:out_dir], SUMMARY_MD), summary, release_rows)

  warn "Wrote release gates to #{options[:out_dir]}"
end

main if $PROGRAM_NAME == __FILE__
