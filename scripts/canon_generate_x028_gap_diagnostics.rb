#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")

WORK_CANDIDATES_FILE = File.join(TABLE_DIR, "canon_work_candidates.tsv")
ALIASES_FILE = File.join(TABLE_DIR, "canon_aliases.tsv")
PATH_SELECTION_FILE = File.join(TABLE_DIR, "canon_path_selection.tsv")
SOURCE_ITEMS_FILE = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_FILE = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_FILE = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
SENTINEL_TARGETS_FILE = File.join(TABLE_DIR, "canon_sentinel_targets.yml")
PACKET_STATUS_FILE = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_FILE = File.join(MANIFEST_DIR, "canon_build_manifest.yml")

COVERAGE_MATRIX_FILE = File.join(TABLE_DIR, "canon_coverage_matrix.tsv")
SENTINEL_CHECKS_FILE = File.join(TABLE_DIR, "canon_sentinel_checks.tsv")
GAP_DIAGNOSTICS_FILE = File.join(TABLE_DIR, "canon_gap_diagnostics.tsv")
RED_CELL_QUEUE_FILE = File.join(TABLE_DIR, "canon_red_cell_audit_queue.tsv")
REPORT_FILE = File.join(REPORT_DIR, "x_batch_012_x028_gap_diagnostics.md")

PACKET_ID = "X028"

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

COVERAGE_HEADERS = %w[
  axis cell_key selected_count candidate_count source_item_unmatched_count evidence_count
  no_evidence_selected_count provisional_external_selected_count risk_level diagnostic_reason next_action
].freeze

SENTINEL_HEADERS = %w[
  sentinel_id title creator_hint category severity present_in_current_path present_as_candidate
  matched_work_ids source_item_count evidence_count source_ids risk_level diagnosis next_action
].freeze

GAP_HEADERS = %w[
  diagnostic_id diagnostic_type subject axis cell_key severity priority_score selected_count candidate_count
  source_item_count evidence_count matched_work_ids source_ids rationale next_action
].freeze

RED_CELL_HEADERS = %w[
  queue_id diagnostic_id audit_namespace severity priority_score subject rationale next_action
].freeze

GENERIC_SOURCE_TITLES = Set.new([
  "bibliography",
  "chapter",
  "children",
  "comedy",
  "conclusion",
  "creation",
  "credits",
  "crosscurrents",
  "from confessions",
  "hymns",
  "index",
  "introduction",
  "lyrics",
  "fish",
  "ode",
  "odes",
  "poem",
  "poems",
  "preface",
  "prologue",
  "resonance",
  "resonances",
  "selected poems",
  "song",
  "songs",
  "still life",
  "stories",
  "tales",
  "to reader",
  "tragedy",
  "translations",
  "woman"
]).freeze

GENERIC_SENTINEL_VARIANTS = Set.new([
  "complete poems",
  "collected poems",
  "essays",
  "poems",
  "selected poems"
]).freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def normalize(value)
  value.to_s
       .downcase
       .gsub(/&/, " and ")
       .gsub(/[[:punct:]]+/, " ")
       .gsub(/\b(the|a|an|le|la|les|el|los|las|il|lo|gli|i|der|die|das)\b/, " ")
       .gsub(/\s+/, " ")
       .strip
end

def count_by(rows, key)
  rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch(key, "")] += 1 }
end

def add_packet_id(packet_ids, packet_id)
  (packet_ids.to_s.split(";").reject(&:empty?) + [packet_id]).uniq.join(";")
end

def text_blob(row)
  [
    row["canonical_title"],
    row["sort_title"],
    row["original_title"],
    row["creator_display"],
    row["date_label"],
    row["macro_region"],
    row["subregion"],
    row["original_language"],
    row["literary_tradition"],
    row["period_bucket"],
    row["form_bucket"],
    row["unit_type"],
    row["boundary_flags"],
    row["notes"]
  ].join(" ")
end

def infer_region(row)
  return row["macro_region"] if row["macro_region"].to_s != "" && row["macro_region"] != "taxonomy_pending"

  text = normalize(text_blob(row))
  return "oceania_arctic" if text.match?(/\b(aboriginal|maori|pacific|oceanian|polynesian|arctic|inuit|hawaiian|samoan|marshallese)\b/)
  return "americas" if text.match?(/\b(american|canadian|caribbean|brazilian|maya|kiche|quechua|nahuatl|mapuche|zapotec|kichwa|mephaa|chicano|cuban|dominican|mexican|latin american|native american|indigenous)\b/)
  return "africa" if text.match?(/\b(african|swahili|yoruba|hausa|somali|amharic|zulu|ghanaian|kenyan|nigerian|mande|ethiopic|geez|south african|west african|east african|north african|central african)\b/)
  return "east_asia" if text.match?(/\b(chinese|japanese|korean|taiwanese|mongolian|tibetan|sinophone)\b/)
  return "south_asia" if text.match?(/\b(sanskrit|pali|prakrit|tamil|telugu|malayalam|bengali|hindi|urdu|punjabi|marathi|kannada|odia|assamese|nepali|sinhala|south asian|indian|jain|sikh)\b/)
  return "southeast_asia" if text.match?(/\b(thai|vietnamese|khmer|burmese|malay|indonesian|filipino|javanese|southeast asian)\b/)
  return "middle_east_central_asia" if text.match?(/\b(arabic|persian|turkic|turkish|kurdish|hebrew|syriac|armenian|georgian|central asian|egyptian|mesopotamian|sumerian|akkadian|ugaritic|hittite|zoroastrian|islamic|hadith|aramaic)\b/)
  return "europe" if text.match?(/\b(greek|roman|latin|italian|french|francophone|spanish|portuguese|german|austrian|british|english|irish|scottish|welsh|dutch|scandinavian|norwegian|swedish|danish|icelandic|russian|polish|czech|slovak|hungarian|romanian|balkan|baltic|bulgarian|slovenian|albanian|ukrainian|european)\b/)

  "unknown"
end

def infer_form(row)
  return row["form_bucket"] if row["form_bucket"].to_s != "" && row["form_bucket"] != "taxonomy_pending"

  text = normalize(text_blob(row))
  unit_type = normalize(row["unit_type"])
  return "children_young_adult" if text.match?(/\b(children|childrens|young adult)\b/)
  return "graphic_visual_narrative" if text.match?(/\b(graphic|comic|comics|manga)\b/)
  return "speculative_genre" if text.match?(/\b(science fiction|fantasy|horror|weird|crime|detective|gothic)\b/)
  return "drama_performance" if text.match?(/\b(play|drama|theater|theatre|tragedy|comedy|satyr|noh|bunraku|performance|pansori)\b/) || unit_type.include?("play")
  return "sacred_myth_ritual" if text.match?(/\b(scripture|religion|religious|myth|mythology|ritual|funerary|liturgical|sutra|bible|qur|hadith|buddhist|hindu|jain|sikh|zoroastrian|apocalyptic)\b/)
  return "epic_oral_folk" if text.match?(/\b(epic|oral|saga|folklore|fable|fairy tale|ballad|trickster|beast)\b/)
  return "poetry" if text.match?(/\b(poem|poems|poetry|poetic|lyric|hymn|ghazal|haiku|song|verse|ode|elegy|sonnet)\b/) || unit_type.include?("poem")
  return "essays_memoir_testimony" if text.match?(/\b(memoir|autobiography|testimonio|essay|confession|diary|travel|chronicle|history|dialogue|wisdom|letters?|epistolary|philosophy|philosophical|prose)\b/)

  "fiction_narrative_prose"
end

def source_text_blob(row)
  [
    row["raw_title"],
    row["raw_creator"],
    row["raw_date"],
    row["source_section"],
    row["source_citation"],
    row["source_id"],
    row["supports"],
    row["notes"]
  ].join(" ")
end

def infer_source_region(row)
  infer_region({
    "macro_region" => "",
    "canonical_title" => row["raw_title"],
    "creator_display" => row["raw_creator"],
    "date_label" => row["raw_date"],
    "literary_tradition" => source_text_blob(row),
    "unit_type" => row["evidence_type"],
    "notes" => source_text_blob(row)
  })
end

def infer_source_form(row)
  infer_form({
    "form_bucket" => "",
    "canonical_title" => row["raw_title"],
    "creator_display" => row["raw_creator"],
    "date_label" => row["raw_date"],
    "unit_type" => row["evidence_type"],
    "notes" => source_text_blob(row)
  })
end

def generic_source_title?(title)
  normalized = normalize(title)
  return true if normalized.empty?
  return true if normalized.length < 4
  return true if GENERIC_SOURCE_TITLES.include?(normalized)

  normalized.match?(/\A(?:book|chapter|canto|sura|psalm|act|scene)\s+\d+\z/) ||
    normalized.match?(/\Abook\s+(?:\d+|one|two|three|four|five|six|seven|eight|nine|ten)\b/)
end

def generic_sentinel_variant?(variant)
  GENERIC_SENTINEL_VARIANTS.include?(normalize(variant))
end

def creator_matches_hint?(row, creator_hint)
  hint = creator_hint.to_s
  normalized_hint = normalize(hint)
  return true if normalized_hint.empty?

  creator = normalize(row.fetch("creator_display", ""))
  return false if creator.empty?
  return true if creator.include?(normalized_hint) || normalized_hint.include?(creator)

  hint.split(/\s+and\s+|;|,/i)
      .map { |fragment| normalize(fragment) }
      .reject { |fragment| fragment.length < 5 }
      .any? { |fragment| creator.include?(fragment) || fragment.include?(creator) }
end

def source_creator_matches_hint?(row, creator_hint)
  hint = creator_hint.to_s
  normalized_hint = normalize(hint)
  return true if normalized_hint.empty?

  creator = normalize(row.fetch("raw_creator", ""))
  return false if creator.empty?
  return true if creator.include?(normalized_hint) || normalized_hint.include?(creator)

  hint.split(/\s+and\s+|;|,/i)
      .map { |fragment| normalize(fragment) }
      .reject { |fragment| fragment.length < 5 }
      .any? { |fragment| creator.include?(fragment) || fragment.include?(creator) }
end

def risk_for_coverage(selected_count, source_pressure, no_evidence_count)
  return "critical" if selected_count.zero? && source_pressure >= 8
  return "high" if selected_count.zero? && source_pressure >= 3
  return "high" if selected_count <= 2 && source_pressure >= 10
  return "medium" if no_evidence_count >= 20 && selected_count.positive?
  return "low" if selected_count.zero?

  "ok"
end

def score_for_risk(risk)
  { "critical" => 100, "high" => 75, "medium" => 45, "low" => 20, "ok" => 0 }.fetch(risk, 0)
end

works = read_tsv(WORK_CANDIDATES_FILE)
aliases = read_tsv(ALIASES_FILE)
path_selection = read_tsv(PATH_SELECTION_FILE)
source_items = read_tsv(SOURCE_ITEMS_FILE)
evidence_rows = read_tsv(EVIDENCE_FILE)
source_debt_rows = read_tsv(SOURCE_DEBT_FILE)
sentinel_targets = YAML.load_file(SENTINEL_TARGETS_FILE).fetch("targets")

selected_work_ids = path_selection.select { |row| row["selected"] == "true" }.map { |row| row.fetch("work_id") }.to_set
evidence_by_work = count_by(evidence_rows, "work_id")
debt_by_work = source_debt_rows.to_h { |row| [row.fetch("work_id"), row] }

work_indexes = Hash.new { |hash, key| hash[key] = Set.new }
works_by_id = works.to_h { |row| [row.fetch("work_id"), row] }
creator_heading_keys = works.map { |row| normalize(row.fetch("creator_display", "")) }
                           .reject { |creator| creator.empty? || creator.length < 6 }
                           .to_set
works.each do |work|
  [work["canonical_title"], work["sort_title"], work["original_title"]].each do |title|
    normalized = normalize(title)
    work_indexes[normalized] << work.fetch("work_id") unless normalized.empty?
  end
end
aliases.each do |alias_row|
  normalized = normalize(alias_row["alias"])
  work_indexes[normalized] << alias_row.fetch("work_id") unless normalized.empty?
end

works_with_diagnostics = works.map do |work|
  region = infer_region(work)
  form = infer_form(work)
  work.merge(
    "_selected" => selected_work_ids.include?(work.fetch("work_id")) ? "true" : "false",
    "_region" => region,
    "_form" => form,
    "_period" => work.fetch("period_bucket", "unknown").to_s.empty? ? "unknown" : work.fetch("period_bucket"),
    "_evidence_count" => evidence_by_work.fetch(work.fetch("work_id"), 0),
    "_debt_status" => debt_by_work.fetch(work.fetch("work_id"), {})["source_debt_status"].to_s
  )
end

source_items_with_diagnostics = source_items.map do |item|
  item.merge(
    "_region" => infer_source_region(item),
    "_form" => infer_source_form(item),
    "_source_cluster_key" => normalize(item.fetch("raw_title", ""))
  )
end

unmatched_source_items = source_items_with_diagnostics.select do |item|
  item["match_status"] == "unmatched" &&
    item["evidence_type"] != "boundary_context" &&
    !generic_source_title?(item["raw_title"])
end

source_pressure_by_region = count_by(unmatched_source_items, "_region")
source_pressure_by_form = count_by(unmatched_source_items, "_form")
source_pressure_by_region_form = unmatched_source_items.each_with_object(Hash.new(0)) do |item, counts|
  counts["#{item["_region"]}|#{item["_form"]}"] += 1
end

coverage_rows = []
coverage_specs = [
  ["period", ->(work) { work["_period"] }, Hash.new(0)],
  ["macro_region", ->(work) { work["_region"] }, source_pressure_by_region],
  ["form_bucket", ->(work) { work["_form"] }, source_pressure_by_form],
  ["region_form", ->(work) { "#{work["_region"]}|#{work["_form"]}" }, source_pressure_by_region_form]
]

coverage_specs.each do |axis, key_fn, source_pressure|
  grouped = works_with_diagnostics.group_by { |work| key_fn.call(work) }
  source_pressure.keys.each { |key| grouped[key] ||= [] }
  grouped.each do |cell_key, cell_works|
    selected = cell_works.select { |work| work["_selected"] == "true" }
    evidence_count = selected.sum { |work| work["_evidence_count"].to_i }
    no_evidence_count = selected.count { |work| work["_debt_status"] == "open_no_evidence" }
    provisional_count = selected.count { |work| work["_debt_status"] == "open_provisional_external_support" }
    pressure = source_pressure.fetch(cell_key, 0)
    risk = risk_for_coverage(selected.size, pressure, no_evidence_count)
    coverage_rows << {
      "axis" => axis,
      "cell_key" => cell_key,
      "selected_count" => selected.size,
      "candidate_count" => cell_works.size,
      "source_item_unmatched_count" => pressure,
      "evidence_count" => evidence_count,
      "no_evidence_selected_count" => no_evidence_count,
      "provisional_external_selected_count" => provisional_count,
      "risk_level" => risk,
      "diagnostic_reason" => "selected=#{selected.size}; unmatched_source_pressure=#{pressure}; no_evidence_selected=#{no_evidence_count}",
      "next_action" => risk == "ok" ? "no_manual_audit_unless_sentinel_fails" : "review_red_cell_before_manual_packet_sweep"
    }
  end
end
coverage_rows.sort_by! { |row| [-score_for_risk(row["risk_level"]), row["axis"], row["cell_key"]] }
write_tsv(COVERAGE_MATRIX_FILE, COVERAGE_HEADERS, coverage_rows)

source_title_index = Hash.new { |hash, key| hash[key] = [] }
source_items.each do |item|
  [item["raw_title"], item["raw_title"].to_s.sub(/\Afrom\s+/i, "")].each do |title|
    normalized = normalize(title)
    source_title_index[normalized] << item unless normalized.empty?
  end
end

sentinel_rows = sentinel_targets.map do |target|
  variants = ([target.fetch("title")] + Array(target["variants"])).map { |title| normalize(title) }.reject(&:empty?).uniq
  matched_work_ids = variants.flat_map { |variant| work_indexes.fetch(variant, Set.new).to_a }.uniq
  matched_source_items = variants.flat_map { |variant| source_title_index.fetch(variant, []) }.uniq { |row| row.fetch("source_item_id") }
  creator_hint = target.fetch("creator_hint", "")
  if creator_hint.to_s != "" && (matched_work_ids.size > 1 || variants.any? { |variant| generic_sentinel_variant?(variant) })
    creator_filtered_work_ids = matched_work_ids.select { |work_id| creator_matches_hint?(works_by_id.fetch(work_id), creator_hint) }
    matched_work_ids = creator_filtered_work_ids unless creator_filtered_work_ids.empty?
  end
  if creator_hint.to_s != "" && (matched_source_items.size > 1 || variants.any? { |variant| generic_sentinel_variant?(variant) })
    creator_filtered_source_items = matched_source_items.select { |item| source_creator_matches_hint?(item, creator_hint) }
    matched_source_items = creator_filtered_source_items unless creator_filtered_source_items.empty?
  end
  present_current = matched_work_ids.any? { |work_id| selected_work_ids.include?(work_id) }
  present_candidate = matched_work_ids.any?
  evidence_count = matched_work_ids.sum { |work_id| evidence_by_work.fetch(work_id, 0) }
  source_ids = matched_source_items.map { |row| row.fetch("source_id") }.uniq.sort
  severity = target.fetch("severity", "medium")
  risk =
    if present_current
      "ok"
    elsif matched_source_items.any? || present_candidate
      severity == "critical" ? "critical" : "high"
    else
      severity == "critical" ? "high" : "medium"
    end

  diagnosis =
    if present_current
      "sentinel_present_in_current_path"
    elsif present_candidate
      "sentinel_has_candidate_but_not_current_path"
    elsif matched_source_items.any?
      "sentinel_seen_in_source_items_but_not_matched_to_current_path"
    else
      "sentinel_not_found_in_current_indexes"
    end

  {
    "sentinel_id" => target.fetch("sentinel_id"),
    "title" => target.fetch("title"),
    "creator_hint" => creator_hint,
    "category" => target.fetch("category", ""),
    "severity" => severity,
    "present_in_current_path" => present_current ? "true" : "false",
    "present_as_candidate" => present_candidate ? "true" : "false",
    "matched_work_ids" => matched_work_ids.join(";"),
    "source_item_count" => matched_source_items.size,
    "evidence_count" => evidence_count,
    "source_ids" => source_ids.join(";"),
    "risk_level" => risk,
    "diagnosis" => diagnosis,
    "next_action" => risk == "ok" ? "no_action" : "manual_sentinel_review_or_source_extraction"
  }
end
sentinel_rows.sort_by! { |row| [-score_for_risk(row["risk_level"]), row["category"], row["title"]] }
write_tsv(SENTINEL_CHECKS_FILE, SENTINEL_HEADERS, sentinel_rows)

source_clusters = unmatched_source_items.group_by { |item| item["_source_cluster_key"] }
source_cluster_diagnostics = []
source_clusters.each do |cluster_key, items|
  next if generic_source_title?(cluster_key)
  next if creator_heading_keys.include?(cluster_key)

  source_ids = items.map { |item| item.fetch("source_id") }.uniq.sort
  next if source_ids.size < 2 && items.size < 3

  examples = items.map { |item| item.fetch("raw_title") }.uniq.first(3)
  risk = source_ids.size >= 2 ? "high" : "medium"
  score = score_for_risk(risk) + (source_ids.size * 8) + [items.size, 20].min
  source_cluster_diagnostics << {
    "diagnostic_id" => "x028_source_cluster_#{cluster_key.gsub(/[^a-z0-9]+/, "_")[0, 70]}",
    "diagnostic_type" => "source_backed_unmatched_cluster",
    "subject" => examples.join(" | "),
    "axis" => "source_cluster",
    "cell_key" => cluster_key,
    "severity" => risk,
    "priority_score" => score,
    "selected_count" => 0,
    "candidate_count" => 0,
    "source_item_count" => items.size,
    "evidence_count" => 0,
    "matched_work_ids" => "",
    "source_ids" => source_ids.join(";"),
    "rationale" => "Unmatched source-title cluster appears in #{source_ids.size} source(s) and #{items.size} source item(s).",
    "next_action" => "manual_match_or_create_candidate_review"
  }
end

sentinel_diagnostics = sentinel_rows.reject { |row| row["risk_level"] == "ok" }.map do |row|
  score = score_for_risk(row["risk_level"]) + row["source_item_count"].to_i + row["evidence_count"].to_i
  {
    "diagnostic_id" => "x028_sentinel_#{row.fetch("sentinel_id")}",
    "diagnostic_type" => "sentinel_check",
    "subject" => "#{row.fetch("title")} -- #{row.fetch("creator_hint")}",
    "axis" => "sentinel",
    "cell_key" => row.fetch("category"),
    "severity" => row.fetch("risk_level"),
    "priority_score" => score,
    "selected_count" => row.fetch("present_in_current_path") == "true" ? 1 : 0,
    "candidate_count" => row.fetch("present_as_candidate") == "true" ? 1 : 0,
    "source_item_count" => row.fetch("source_item_count"),
    "evidence_count" => row.fetch("evidence_count"),
    "matched_work_ids" => row.fetch("matched_work_ids"),
    "source_ids" => row.fetch("source_ids"),
    "rationale" => row.fetch("diagnosis"),
    "next_action" => row.fetch("next_action")
  }
end

coverage_diagnostics = coverage_rows.reject { |row| %w[ok low].include?(row["risk_level"]) }.map.with_index(1) do |row, index|
  pressure_bonus = [row["source_item_unmatched_count"].to_i, 60].min
  selected_penalty = [row["selected_count"].to_i / 25, 60].min
  score = [score_for_risk(row["risk_level"]) + pressure_bonus - selected_penalty, 1].max
  score = [score, 74].min if row["risk_level"] == "medium"
  score = [score, 99].min if row["risk_level"] == "high"
  {
    "diagnostic_id" => "x028_coverage_#{index.to_s.rjust(4, "0")}",
    "diagnostic_type" => "coverage_red_cell",
    "subject" => "#{row.fetch("axis")}: #{row.fetch("cell_key")}",
    "axis" => row.fetch("axis"),
    "cell_key" => row.fetch("cell_key"),
    "severity" => row.fetch("risk_level"),
    "priority_score" => score,
    "selected_count" => row.fetch("selected_count"),
    "candidate_count" => row.fetch("candidate_count"),
    "source_item_count" => row.fetch("source_item_unmatched_count"),
    "evidence_count" => row.fetch("evidence_count"),
    "matched_work_ids" => "",
    "source_ids" => "",
    "rationale" => row.fetch("diagnostic_reason"),
    "next_action" => row.fetch("next_action")
  }
end

diagnostic_rows = (sentinel_diagnostics + source_cluster_diagnostics + coverage_diagnostics)
diagnostic_rows.sort_by! { |row| [-row["priority_score"].to_i, row["diagnostic_type"], row["subject"]] }
write_tsv(GAP_DIAGNOSTICS_FILE, GAP_HEADERS, diagnostic_rows)

red_cell_rows = diagnostic_rows.first(120).map.with_index(1) do |row, index|
  namespace =
    case row.fetch("diagnostic_type")
    when "sentinel_check" then "F_sentinel"
    when "coverage_red_cell"
      case row.fetch("axis")
      when "period" then "B_period"
      when "macro_region" then "C_region"
      when "form_bucket" then "D_form"
      else "I_intersection"
      end
    else
      "C_source_cluster"
    end
  {
    "queue_id" => "x028_red_#{index.to_s.rjust(4, "0")}",
    "diagnostic_id" => row.fetch("diagnostic_id"),
    "audit_namespace" => namespace,
    "severity" => row.fetch("severity"),
    "priority_score" => row.fetch("priority_score"),
    "subject" => row.fetch("subject"),
    "rationale" => row.fetch("rationale"),
    "next_action" => row.fetch("next_action")
  }
end
write_tsv(RED_CELL_QUEUE_FILE, RED_CELL_HEADERS, red_cell_rows)

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row.fetch("packet_id") == PACKET_ID }
packet_rows << {
  "packet_id" => PACKET_ID,
  "packet_family" => "X",
  "scope" => "diagnostic-first coverage and sentinel gap triage",
  "status" => "diagnostics_generated",
  "gate" => "manual_red_cell_review_required",
  "output_artifact" => [
    "_planning/canon_build/tables/canon_coverage_matrix.tsv",
    "_planning/canon_build/tables/canon_sentinel_checks.tsv",
    "_planning/canon_build/tables/canon_gap_diagnostics.tsv",
    "_planning/canon_build/tables/canon_red_cell_audit_queue.tsv",
    "_planning/canon_build/source_crosswalk_reports/x_batch_012_x028_gap_diagnostics.md"
  ].join(";"),
  "next_action" => "review_top_red_cells_then_expand_sentinel_targets_and_source_extraction",
  "notes" => "#{diagnostic_rows.size} diagnostics generated; #{red_cell_rows.size} red-cell audit queue rows; public canon unchanged"
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows.sort_by { |row| row.fetch("packet_id") })

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x028_gap_diagnostics_generated"
manifest["artifacts"]["coverage_matrix"] = "generated_x028"
manifest["artifacts"]["sentinel_checks"] = "generated_x028"
manifest["artifacts"]["gap_diagnostics"] = "generated_x028"
manifest["artifacts"]["red_cell_audit_queue"] = "generated_x028"
manifest["diagnostic_first_validation_x028"] = {
  "coverage_matrix_rows" => coverage_rows.size,
  "sentinel_targets" => sentinel_targets.size,
  "sentinel_failures_or_reviews" => sentinel_diagnostics.size,
  "source_backed_unmatched_clusters" => source_cluster_diagnostics.size,
  "coverage_red_cells" => coverage_diagnostics.size,
  "gap_diagnostics_rows" => diagnostic_rows.size,
  "red_cell_audit_queue_rows" => red_cell_rows.size,
  "direct_replacements" => 0
}
File.write(MANIFEST_FILE, manifest.to_yaml)

report = <<~MARKDOWN
  # X Batch 12 Report: X028 Diagnostic-First Gap Triage

  Date: 2026-05-03

  Status: diagnostics generated; public canon unchanged.

  ## Summary

  X028 replaces the slow default of hand-auditing every B/C/D/F/I packet in sequence. The B/C/D/F/I packets remain the coverage namespace, but the first pass is now automated:

  - `canon_coverage_matrix.tsv` ranks period, region, form, and intersection cells by selected coverage, source pressure, evidence, and source debt.
  - `canon_sentinel_checks.tsv` checks maintained sentinel works against current path candidates, aliases, source items, and evidence.
  - `canon_gap_diagnostics.tsv` merges sentinel failures, source-backed unmatched clusters, and red coverage cells.
  - `canon_red_cell_audit_queue.tsv` gives the prioritized manual-review queue.

  ## Counts

  | Artifact | Rows |
  |---|---:|
  | Coverage matrix | #{coverage_rows.size} |
  | Sentinel targets checked | #{sentinel_targets.size} |
  | Sentinel failures/reviews | #{sentinel_diagnostics.size} |
  | Source-backed unmatched clusters | #{source_cluster_diagnostics.size} |
  | Coverage red cells | #{coverage_diagnostics.size} |
  | Gap diagnostics | #{diagnostic_rows.size} |
  | Red-cell audit queue | #{red_cell_rows.size} |

  ## Top Red Cells

  | Priority | Severity | Subject | Rationale |
  |---:|---|---|---|
  #{red_cell_rows.first(20).map { |row| "| #{row.fetch("priority_score")} | #{row.fetch("severity")} | #{row.fetch("subject").gsub("|", "/")} | #{row.fetch("rationale").gsub("|", "/")} |" }.join("\n")}

  ## Interpretation

  These diagnostics are triage, not final judgments. They are designed to make the remaining audit faster by showing where manual review is actually needed. A flagged row can resolve as an alias, contained selection, source extraction gap, true omission, or justified exclusion.

  ## Next Actions

  1. Review the highest-priority `canon_red_cell_audit_queue.tsv` rows before starting any broad B/C/D/F/I packet sweep.
  2. Expand `canon_sentinel_targets.yml` by region/tradition after reviewing the first failures.
  3. Continue high-yield source extraction where diagnostics show source gaps, including E006 Bedford fragments and later American/British anthology rows.
MARKDOWN
File.write(REPORT_FILE, report)

puts "wrote #{COVERAGE_MATRIX_FILE.sub(ROOT + "/", "")} (#{coverage_rows.size} rows)"
puts "wrote #{SENTINEL_CHECKS_FILE.sub(ROOT + "/", "")} (#{sentinel_rows.size} rows)"
puts "wrote #{GAP_DIAGNOSTICS_FILE.sub(ROOT + "/", "")} (#{diagnostic_rows.size} rows)"
puts "wrote #{RED_CELL_QUEUE_FILE.sub(ROOT + "/", "")} (#{red_cell_rows.size} rows)"
