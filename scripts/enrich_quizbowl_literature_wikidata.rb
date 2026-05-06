#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "csv"
require "fileutils"
require "json"
require "net/http"
require "optparse"
require "set"
require "time"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DEFAULT_CANON = File.join(ROOT, "_data", "quizbowl_literature_canon.yml")
DEFAULT_OUT = File.join(ROOT, "_data", "quizbowl_literature_metadata_overrides.yml")
DEFAULT_REPORT = File.join(ROOT, "_planning", "quizbowl_lit_canon", "quizbowl_lit_wikidata_candidates.tsv")
REPORT_HEADERS = %w[
  title
  rank
  total_question_count
  wikidata_id
  wikidata_label
  wikidata_description
  creators
  sort_year
  date_label
  confidence
  decision
].freeze

LITERARY_DESCRIPTION_RE = /\b(?:novel|novella|poem|poetry|play|drama|tragedy|comedy|short stor(?:y|ies)|story|literary work|book|epic|saga|romance|memoir|autobiography|essay|fable|fairy tale|myth|scripture|gospel|sutra|anthology|poetry collection|graphic novel)\b/i
NON_LITERARY_DESCRIPTION_RE = /\b(?:film|movie|television|tv|tv series|episode|album|song|single|opera|oratorio|cantata|symphony|composition|concerto|sonata|painting|sculpture|woodcuts?|video game|board game|manga series|anime|band|musical group|book imprint|imprint|publisher|publishing house|book review|critical edition|book edition|edition of|translation of|magazine article|journal article|newspaper article|title character|fictional character|character of|character in|protagonist of)\b/i
DESCRIPTION_FORM_GROUPS = {
  "poetry" => /\b(?:poem|poetry|poetry collection|verse|lyric|ode|sonnet|ballad|elegy)\b/i,
  "drama" => /\b(?:play|drama|tragedy|comedy|theatrical)\b/i,
  "fiction" => /\b(?:novel|novella|fiction|romance)\b/i,
  "short_fiction" => /\b(?:short stor(?:y|ies)|story|fairy tale|fable)\b/i,
  "collection" => /\b(?:anthology|collection|cycle)\b/i,
  "nonfiction" => /\b(?:memoir|autobiography|essay)\b/i
}.freeze
REJECT_INSTANCE_QIDS = Set.new(%w[
  Q5
])

def normalize_space(value)
  value.to_s.gsub(/\s+/, " ").strip
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
    .gsub(/\s+/, " ")
    .strip
end

def title_keys(title)
  normalized = normalize_title(title)
  return Set.new if normalized.empty?

  keys = Set.new([normalized])
  stripped = normalized.sub(/\A(?:the|a|an)\s+/, "")
  keys << stripped unless stripped.empty?
  keys << "the #{stripped}" unless stripped.empty? || stripped == normalized
  keys
end

def http_json(url, attempts: 3)
  uri = URI(url)

  attempts.times do |attempt|
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "quizbowl-literature-canon-metadata/1.0 (https://benjaminkramer50.github.io/)"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", read_timeout: 30) do |http|
      http.request(request)
    end
    raise "HTTP #{response.code} for #{url}" unless response.is_a?(Net::HTTPSuccess)

    return JSON.parse(response.body)
  rescue StandardError
    raise if attempt == attempts - 1

    sleep 0.5 * (attempt + 1)
  end
end

def wikidata_search(title, limit)
  query = CGI.escape(title)
  url = "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=#{query}&language=en&format=json&limit=#{limit}"
  http_json(url).fetch("search", [])
rescue StandardError => e
  warn "search failed title=#{title.inspect}: #{e.class}: #{e.message}"
  []
end

def wikidata_entity(qid)
  url = "https://www.wikidata.org/wiki/Special:EntityData/#{CGI.escape(qid)}.json"
  http_json(url).fetch("entities").fetch(qid)
rescue StandardError => e
  warn "entity failed qid=#{qid}: #{e.class}: #{e.message}"
  nil
end

def entity_label(entity)
  entity.dig("labels", "en", "value").to_s
end

def entity_description(entity)
  entity.dig("descriptions", "en", "value").to_s
end

def entity_aliases(entity)
  Array(entity.dig("aliases", "en")).map { |alias_item| alias_item["value"].to_s }
end

def claim_values(entity, property)
  Array(entity.dig("claims", property)).map do |claim|
    claim.dig("mainsnak", "datavalue", "value")
  end.compact
end

def item_ids_from_claims(entity, *properties)
  properties.flat_map do |property|
    claim_values(entity, property).map do |value|
      value["id"] if value.is_a?(Hash) && value["id"].to_s.match?(/\AQ\d+\z/)
    end.compact
  end.uniq
end

def labels_for_qids(qids)
  return {} if qids.empty?

  labels = {}
  qids.each_slice(50) do |slice|
    ids = CGI.escape(slice.join("|"))
    url = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{ids}&props=labels&languages=en&format=json"
    entities = http_json(url).fetch("entities", {})
    entities.each do |qid, entity|
      labels[qid] = entity.dig("labels", "en", "value").to_s
    end
  rescue StandardError => e
    warn "label batch failed ids=#{slice.join(",")}: #{e.class}: #{e.message}"
  end
  labels
end

def year_from_wikidata_time(value)
  return nil unless value.is_a?(Hash)

  time = value["time"].to_s
  match = time.match(/\A([+-])(\d+)-/)
  return nil unless match

  year = match[2].to_i
  return nil if year.zero?

  match[1] == "-" ? -year : year
end

def date_label_for_year(year)
  year = year.to_i
  return "" if year.zero?
  return "#{year.abs} BCE" if year.negative?

  year.to_s
end

def entity_sort_year(entity)
  %w[P577 P571].each do |property|
    years = claim_values(entity, property).map { |value| year_from_wikidata_time(value) }.compact
    return years.min unless years.empty?
  end
  nil
end

def year_from_description(description)
  value = description.to_s
  bce_match = value.match(/\b(\d{1,4})\s*(?:BCE|BC)\b/i)
  return -bce_match[1].to_i if bce_match

  ce_match = value.match(/\b(1[0-9]{3}|20[0-2][0-9])\b/)
  ce_match ? ce_match[1].to_i : nil
end

def title_match?(title, entity)
  keys = title_keys(title)
  entity_keys = title_keys(entity_label(entity))
  entity_aliases(entity).each { |value| entity_keys.merge(title_keys(value)) }
  !(keys & entity_keys).empty?
end

def creator_last_name(normalized_name)
  parts = normalized_name.to_s.split
  return "" if parts.length < 2

  parts.last
end

def creator_names_match?(left, right)
  return true if left == right || left.include?(right) || right.include?(left)

  left_last = creator_last_name(left)
  right_last = creator_last_name(right)
  !left_last.empty? && left_last.length >= 4 && left_last == right_last
end

def row_evidence_text(row)
  examples = Array(row["examples"]).map { |example| example["snippet"].to_s if example.is_a?(Hash) }
  normalize_title(([row["title"]] + examples.compact).join(" "))
end

def creator_match?(row, creator_labels, description)
  row_creators = Array(row["creators"]).map { |creator| normalize_title(creator) }.reject(&:empty?)
  return true if row_creators.empty?

  description_text = normalize_title(description)
  return true if row_creators.any? do |row_creator|
    description_text.include?(row_creator) ||
      (!creator_last_name(row_creator).empty? && description_text.split.include?(creator_last_name(row_creator)))
  end

  return false if creator_labels.empty?

  wikidata_creators = creator_labels.map { |creator| normalize_title(creator) }.reject(&:empty?)
  return true if row_creators.any? do |row_creator|
    wikidata_creators.any? do |wikidata_creator|
      creator_names_match?(row_creator, wikidata_creator)
    end
  end

  evidence_text = row_evidence_text(row)
  wikidata_creators.any? { |wikidata_creator| evidence_text.include?(wikidata_creator) }
end

def description_form_group(description)
  DESCRIPTION_FORM_GROUPS.each do |group, pattern|
    return group if description.to_s.match?(pattern)
  end
  nil
end

def compatible_work_form?(row, description)
  expected_groups = case row["work_form"].to_s
                    when "poetry"
                      %w[poetry collection]
                    when "drama"
                      %w[drama]
                    when "long_fiction", "epic_or_romance"
                      %w[fiction short_fiction collection]
                    when "short_fiction"
                      %w[short_fiction fiction collection]
                    when "collection_or_cycle"
                      %w[collection poetry short_fiction fiction]
                    when "essay_memoir_nonfiction"
                      %w[nonfiction]
                    else
                      []
                    end
  return true if expected_groups.empty?

  actual_group = description_form_group(description)
  actual_group.nil? || expected_groups.include?(actual_group)
end

def risky_low_evidence_overlay?(row)
  return false unless Array(row["creators"]).empty?
  return false if row["answerline_question_count"].to_i >= 3

  track_counts = row["quizbowl_track_counts"].is_a?(Hash) ? row["quizbowl_track_counts"] : {}
  literature_count = track_counts["literature"].to_i
  non_literature_count = track_counts.reject { |track, _| track == "literature" }.values.sum(&:to_i)
  non_literature_count >= [literature_count * 4, 40].max
end

def refined_creator_labels(row, creator_labels, description)
  return creator_labels if creator_labels.empty?

  row_creators = Array(row["creators"]).map { |creator| normalize_title(creator) }.reject(&:empty?)
  return creator_labels if row_creators.empty?

  evidence_text = [row_evidence_text(row), normalize_title(description)].join(" ")
  refined = creator_labels.select do |creator|
    normalized_creator = normalize_title(creator)
    row_creators.any? { |row_creator| creator_names_match?(row_creator, normalized_creator) } ||
      evidence_text.include?(normalized_creator) ||
      (!creator_last_name(normalized_creator).empty? && evidence_text.split.include?(creator_last_name(normalized_creator)))
  end
  refined.empty? ? creator_labels : refined
end

def plausible_literary_entity?(search_result, entity)
  return false if (item_ids_from_claims(entity, "P31").to_set & REJECT_INSTANCE_QIDS).any?

  description = [
    search_result["description"],
    entity_description(entity)
  ].compact.join(" ")
  return false if description.match?(NON_LITERARY_DESCRIPTION_RE)
  return true if description.match?(LITERARY_DESCRIPTION_RE)

  false
end

def candidate_for(row, search_limit)
  return nil if risky_low_evidence_overlay?(row)

  title = row.fetch("title").to_s
  wikidata_search(title, search_limit).each do |result|
    qid = result["id"].to_s
    next unless qid.match?(/\AQ\d+\z/)

    entity = wikidata_entity(qid)
    next unless entity
    next unless title_match?(title, entity)
    next unless plausible_literary_entity?(result, entity)

    description = entity_description(entity)
    next unless compatible_work_form?(row, description)

    creator_ids = item_ids_from_claims(entity, "P50", "P170")
    creator_labels = labels_for_qids(creator_ids).values.map { |value| normalize_space(value) }.reject(&:empty?).uniq
    next unless creator_match?(row, creator_labels, description)

    creator_labels = refined_creator_labels(row, creator_labels, description)
    sort_year = year_from_description(description) || entity_sort_year(entity)
    next if creator_labels.empty? && sort_year.nil?

    confidence = sort_year && !creator_labels.empty? ? "high" : "medium"
    return {
      "title" => title,
      "normalized_title" => normalize_title(title),
      "wikidata_id" => qid,
      "wikidata_label" => entity_label(entity),
      "wikidata_description" => description,
      "creators" => creator_labels,
      "sort_year" => sort_year,
      "date_label" => sort_year ? date_label_for_year(sort_year) : "",
      "source" => "wikidata_metadata_overlay",
      "confidence" => confidence,
      "notes" => "Exact normalized title or alias match; Wikidata description matched literary-work filter."
    }
  end
  nil
end

def parse_options
  options = {
    canon: DEFAULT_CANON,
    out: DEFAULT_OUT,
    report: DEFAULT_REPORT,
    limit: 500,
    search_limit: 8,
    sleep: 0.05,
    only_unplaced: true
  }
  OptionParser.new do |parser|
    parser.on("--canon PATH") { |value| options[:canon] = value }
    parser.on("--out PATH") { |value| options[:out] = value }
    parser.on("--report PATH") { |value| options[:report] = value }
    parser.on("--limit N", Integer) { |value| options[:limit] = value }
    parser.on("--search-limit N", Integer) { |value| options[:search_limit] = value }
    parser.on("--sleep SECONDS", Float) { |value| options[:sleep] = value }
    parser.on("--all-gaps") { options[:only_unplaced] = false }
  end.parse!
  options
end

def prefer_metadata_row(existing, candidate)
  return candidate unless existing

  existing_manual = existing["source"] == "codex_manual_metadata_correction"
  candidate_manual = candidate["source"] == "codex_manual_metadata_correction"
  return candidate if candidate_manual && !existing_manual
  return existing if existing_manual && !candidate_manual

  existing_has_date = !existing["sort_year"].nil? && existing["sort_year"].to_s != ""
  candidate_has_date = !candidate["sort_year"].nil? && candidate["sort_year"].to_s != ""
  existing_has_creator = Array(existing["creators"]).any?
  candidate_has_creator = Array(candidate["creators"]).any?
  if (!existing_has_date && candidate_has_date) || (!existing_has_creator && candidate_has_creator)
    merged = existing.merge(candidate)
    merged["sort_year"] = existing["sort_year"] if existing_has_date && !candidate_has_date
    merged["date_label"] = existing["date_label"] if existing_has_date && !candidate_has_date
    merged["creators"] = existing["creators"] if existing_has_creator && !candidate_has_creator
    return merged
  end

  existing
end

def main
  options = parse_options
  data = YAML.load_file(options[:canon])
  existing = File.exist?(options[:out]) ? (YAML.load_file(options[:out]) || []) : []
  existing_keys = existing.map { |row| normalize_title(row["title"]) }.to_set

  rows = data.select do |row|
    next false if existing_keys.include?(normalize_title(row["title"]))
    next false if options[:only_unplaced] && row["chronology_source"].to_s != "unknown"

    row["review_status"] == "accepted_likely_work"
  end.sort_by { |row| row["rank"].to_i }.first(options[:limit])

  FileUtils.mkdir_p(File.dirname(options[:out]))
  FileUtils.mkdir_p(File.dirname(options[:report]))

  new_overrides = []
  report_rows = []
  rows.each_with_index do |row, index|
    warn "wikidata #{index + 1}/#{rows.length}: #{row["title"]}"
    candidate = candidate_for(row, options[:search_limit])
    if candidate
      new_overrides << candidate
      report_rows << {
        "title" => row["title"],
        "rank" => row["rank"],
        "total_question_count" => row["total_question_count"],
        "wikidata_id" => candidate["wikidata_id"],
        "wikidata_label" => candidate["wikidata_label"],
        "wikidata_description" => candidate["wikidata_description"],
        "creators" => candidate["creators"].join("; "),
        "sort_year" => candidate["sort_year"],
        "date_label" => candidate["date_label"],
        "confidence" => candidate["confidence"],
        "decision" => "accepted_overlay"
      }
    else
      report_rows << {
        "title" => row["title"],
        "rank" => row["rank"],
        "total_question_count" => row["total_question_count"],
        "decision" => "no_high_confidence_match"
      }
    end
    sleep options[:sleep] if options[:sleep].positive?
  end

  combined_by_key = {}
  (existing + new_overrides).each do |row|
    key = normalize_title(row["title"])
    combined_by_key[key] = prefer_metadata_row(combined_by_key[key], row)
  end
  combined = combined_by_key.values
  File.write(options[:out], combined.to_yaml)

  write_header = !File.exist?(options[:report])
  CSV.open(options[:report], write_header ? "w" : "a", col_sep: "\t", write_headers: write_header, headers: REPORT_HEADERS) do |csv|
    report_rows.each { |row| csv << REPORT_HEADERS.map { |header| row.fetch(header, "") } }
  end

  warn "Wrote #{new_overrides.length} new overrides; total=#{combined.length}"
end

main if $PROGRAM_NAME == __FILE__
