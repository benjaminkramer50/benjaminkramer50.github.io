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
GAP_DIAGNOSTICS_FILE = File.join(TABLE_DIR, "canon_gap_diagnostics.tsv")
RED_CELL_QUEUE_FILE = File.join(TABLE_DIR, "canon_red_cell_audit_queue.tsv")
PACKET_STATUS_FILE = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_FILE = File.join(MANIFEST_DIR, "canon_build_manifest.yml")

TRIAGE_FILE = File.join(TABLE_DIR, "canon_red_cell_triage.tsv")
REPORT_FILE = File.join(REPORT_DIR, "x_batch_013_x029_red_cell_triage.md")

PACKET_ID = "X029"

TRIAGE_HEADERS = %w[
  triage_id queue_id diagnostic_id severity priority_score subject diagnostic_type triage_class
  confidence source_item_count source_ids matched_work_ids possible_work_ids representative_titles
  representative_creators rationale recommended_action
].freeze

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

GENERIC_TITLE_TOKENS = Set.new(%w[
  a an and book chapter canto from in of on part poem poems selected song songs the to
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
  return "graphic_visual_narrative" if text.match?(/\b(graphic|graphic novel|graphic narrative|comic book|comic books|comics|manga|manhwa|manhua)\b/)
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

def source_region(row)
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

def source_form(row)
  infer_form({
    "form_bucket" => "",
    "canonical_title" => row["raw_title"],
    "creator_display" => row["raw_creator"],
    "date_label" => row["raw_date"],
    "unit_type" => row["evidence_type"],
    "notes" => source_text_blob(row)
  })
end

def cluster_keys(row)
  [row["raw_title"], row["raw_title"].to_s.sub(/\Afrom\s+/i, "")]
    .map { |title| normalize(title) }
    .reject(&:empty?)
    .uniq
end

def non_generic_tokens(text)
  normalize(text).split.reject { |token| GENERIC_TITLE_TOKENS.include?(token) || token.length < 3 }
end

def creator_match?(left, right)
  left_norm = normalize(left)
  right_norm = normalize(right)
  return false if left_norm.empty? || right_norm.empty?

  left_norm.include?(right_norm) || right_norm.include?(left_norm)
end

def possible_creator_title_variants(items, works)
  creators = items.map { |item| item["raw_creator"] }.reject { |creator| normalize(creator).empty? }.uniq
  cluster_tokens = items.flat_map { |item| non_generic_tokens(item["raw_title"]) }.to_set
  return [] if creators.empty?

  works.select do |work|
    creators.any? { |creator| creator_match?(creator, work["creator_display"]) } &&
      (non_generic_tokens(work["canonical_title"]).to_set & cluster_tokens).any?
  end.map { |work| work.fetch("work_id") }.uniq.first(12)
end

def source_creators(items)
  items.map { |item| item["raw_creator"] }
       .map { |creator| normalize(creator) }
       .reject(&:empty?)
       .uniq
end

def triage_source_cluster(items, selected_work_ids, exact_work_ids, possible_work_ids, works_by_id)
  source_ids = items.map { |item| item.fetch("source_id") }.uniq
  creators = source_creators(items)
  creator_matching_exact_ids = exact_work_ids.select do |work_id|
    work_creator = normalize(works_by_id.fetch(work_id, {})["creator_display"])
    creators.empty? || creators.any? { |creator| creator_match?(creator, work_creator) }
  end
  selected_exact_ids = creator_matching_exact_ids.select { |work_id| selected_work_ids.include?(work_id) }
  if selected_exact_ids.any?
    return ["existing_current_match_or_alias_gap", "high", "Cluster title already has a current-path candidate; unmatched source rows likely need alias/match review.", "add_alias_or_update_match_review_decision"]
  end

  if exact_work_ids.any? && creator_matching_exact_ids.empty? && creators.any?
    return ["homonymous_title_collision_review", "medium", "Exact title exists, but source creators do not match the existing candidate creators.", "split_by_creator_before_alias_or_candidate_creation"]
  end

  if creator_matching_exact_ids.any?
    return ["existing_candidate_not_integrated", "high", "Cluster title already exists as a non-selected candidate; review scoring and source debt before integration.", "review_candidate_source_debt_and_boundary_status"]
  end

  selected_possible_ids = possible_work_ids.select { |work_id| selected_work_ids.include?(work_id) }
  if selected_possible_ids.any?
    return ["possible_variant_alias_to_current_work", "medium", "Same-creator candidate exists in the current path but the source title is not an exact alias.", "manual_variant_alias_review"]
  end

  if creators.size > 1
    return ["homonymous_title_collision_review", "medium", "Repeated bare title has multiple source creators and must be split before any omission claim.", "split_by_creator_before_candidate_creation"]
  end

  if source_ids.size >= 3
    return ["high_source_diversity_omission_candidate", "high", "Unmatched title appears across at least three independent source layers.", "create_or_review_omission_candidate"]
  end

  if items.any? { |item| item["evidence_type"] == "representative_selection" } ||
     items.any? { |item| source_text_blob(item).match?(/\b(poem|poetry|selection|excerpt|from)\b/i) }
    return ["subwork_or_selection_scope_review", "medium", "Repeated source title may be an individual poem, excerpt, or anthology sub-selection rather than a full work.", "review_scope_before_candidate_creation"]
  end

  ["source_backed_omission_candidate", "medium", "Repeated unmatched title has source support and no exact current candidate.", "manual_match_or_create_candidate_review"]
end

def triage_coverage_cell(items, diagnostic)
  if diagnostic["severity"] == "critical"
    return ["coverage_gap_red_cell", "high", "Coverage cell has source pressure but zero selected works.", "audit_cell_sources_and_open_omission_or_boundary_decisions"]
  end

  if items.size >= 100
    return ["source_debt_and_taxonomy_pressure", "medium", "Large cell has many unmatched source observations; likely needs taxonomy/matching rather than one-off manual additions.", "batch_match_and_taxonomy_review"]
  end

  ["coverage_cell_review", "medium", "Coverage cell remains flagged after diagnostic scoring.", "review_representative_source_items"]
end

works = read_tsv(WORK_CANDIDATES_FILE)
aliases = read_tsv(ALIASES_FILE)
path_selection = read_tsv(PATH_SELECTION_FILE)
source_items = read_tsv(SOURCE_ITEMS_FILE)
gap_diagnostics = read_tsv(GAP_DIAGNOSTICS_FILE)
red_cells = read_tsv(RED_CELL_QUEUE_FILE)

selected_work_ids = path_selection.select { |row| row["selected"] == "true" }.map { |row| row.fetch("work_id") }.to_set
works_by_id = works.to_h { |row| [row.fetch("work_id"), row] }
diagnostics_by_id = gap_diagnostics.to_h { |row| [row.fetch("diagnostic_id"), row] }

work_indexes = Hash.new { |hash, key| hash[key] = Set.new }
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

source_items_with_diagnostics = source_items.map do |item|
  item.merge(
    "_cluster_keys" => cluster_keys(item),
    "_region" => source_region(item),
    "_form" => source_form(item)
  )
end

unmatched_source_items = source_items_with_diagnostics.select do |item|
  item["match_status"] == "unmatched" && item["evidence_type"] != "boundary_context"
end

triage_rows = red_cells.map.with_index(1) do |red_cell, index|
  diagnostic = diagnostics_by_id.fetch(red_cell.fetch("diagnostic_id"), {})
  diagnostic_type = diagnostic.fetch("diagnostic_type", red_cell.fetch("audit_namespace"))
  cell_key = diagnostic.fetch("cell_key", "")
  items =
    if diagnostic_type == "source_backed_unmatched_cluster"
      unmatched_source_items.select { |item| item["_cluster_keys"].include?(cell_key) }
    else
      case diagnostic.fetch("axis", "")
      when "macro_region"
        unmatched_source_items.select { |item| item["_region"] == cell_key }
      when "form_bucket"
        unmatched_source_items.select { |item| item["_form"] == cell_key }
      when "region_form"
        unmatched_source_items.select { |item| "#{item["_region"]}|#{item["_form"]}" == cell_key }
      else
        []
      end
    end

  exact_work_ids = work_indexes.fetch(cell_key, Set.new).to_a
  possible_work_ids = diagnostic_type == "source_backed_unmatched_cluster" ? possible_creator_title_variants(items, works) : []
  triage_class, confidence, rationale, action =
    if diagnostic_type == "source_backed_unmatched_cluster"
      triage_source_cluster(items, selected_work_ids, exact_work_ids, possible_work_ids, works_by_id)
    else
      triage_coverage_cell(items, diagnostic)
    end

  representative_titles = items.map { |item| item.fetch("raw_title") }.uniq.first(8)
  representative_creators = items.map { |item| item.fetch("raw_creator") }.reject { |creator| normalize(creator).empty? }.uniq.first(8)
  source_ids = items.map { |item| item.fetch("source_id") }.uniq.sort

  {
    "triage_id" => "x029_triage_#{index.to_s.rjust(4, "0")}",
    "queue_id" => red_cell.fetch("queue_id"),
    "diagnostic_id" => red_cell.fetch("diagnostic_id"),
    "severity" => red_cell.fetch("severity"),
    "priority_score" => red_cell.fetch("priority_score"),
    "subject" => red_cell.fetch("subject"),
    "diagnostic_type" => diagnostic_type,
    "triage_class" => triage_class,
    "confidence" => confidence,
    "source_item_count" => items.size,
    "source_ids" => source_ids.join(";"),
    "matched_work_ids" => exact_work_ids.join(";"),
    "possible_work_ids" => possible_work_ids.join(";"),
    "representative_titles" => representative_titles.join("; "),
    "representative_creators" => representative_creators.join("; "),
    "rationale" => rationale,
    "recommended_action" => action
  }
end

write_tsv(TRIAGE_FILE, TRIAGE_HEADERS, triage_rows)

class_counts = triage_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("triage_class")] += 1 }
confidence_counts = triage_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("confidence")] += 1 }

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row.fetch("packet_id") == PACKET_ID }
packet_rows << {
  "packet_id" => PACKET_ID,
  "packet_family" => "X",
  "scope" => "red-cell audit queue machine triage",
  "status" => "triage_generated",
  "gate" => "manual_review_required_before_candidate_changes",
  "output_artifact" => "_planning/canon_build/tables/canon_red_cell_triage.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_013_x029_red_cell_triage.md",
  "next_action" => "review_high_confidence_omission_candidates_and_variant_alias_rows",
  "notes" => "#{triage_rows.size} red-cell rows triaged; public canon unchanged"
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows.sort_by { |row| row.fetch("packet_id") })

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x029_red_cell_triage_generated"
manifest["artifacts"]["red_cell_triage"] = "generated_x029"
manifest["red_cell_triage_x029"] = {
  "triage_rows" => triage_rows.size,
  "triage_class_counts" => class_counts.sort.to_h,
  "confidence_counts" => confidence_counts.sort.to_h,
  "direct_replacements" => 0
}
File.write(MANIFEST_FILE, manifest.to_yaml)

report = <<~MARKDOWN
  # X Batch 13 Report: X029 Red-Cell Queue Triage

  Date: 2026-05-03

  Status: triage generated; public canon unchanged.

  ## Summary

  X029 classifies every row in `canon_red_cell_audit_queue.tsv` so the next pass can review specific actions instead of manually searching the raw source tables.

  | Triage class | Rows |
  |---|---:|
  #{class_counts.sort.map { |klass, count| "| #{klass} | #{count} |" }.join("\n")}

  | Confidence | Rows |
  |---|---:|
  #{confidence_counts.sort.map { |klass, count| "| #{klass} | #{count} |" }.join("\n")}

  ## Top Triage Rows

  | Queue | Class | Confidence | Subject | Action |
  |---|---|---|---|---|
  #{triage_rows.first(25).map { |row| "| #{row.fetch("queue_id")} | #{row.fetch("triage_class")} | #{row.fetch("confidence")} | #{row.fetch("subject").gsub("|", "/")} | #{row.fetch("recommended_action")} |" }.join("\n")}

  ## Interpretation

  This is a routing layer, not a final canon decision. A high-confidence omission candidate still needs source scope, boundary, duplicate, and coverage review before any public-path change. A variant row should usually resolve as an alias or match-decision update, not a new work.

  ## Next Actions

  1. Review `source_backed_omission_candidate` rows that look like complete works before poem/excerpt rows.
  2. Review `possible_variant_alias_to_current_work` and `existing_current_match_or_alias_gap` rows before creating candidates.
  3. Split `homonymous_title_collision_review` rows by creator before treating repeated bare titles as omissions.
  4. Use coverage and source-debt rows to open focused C/D/I audits after the title-level rows.
MARKDOWN
File.write(REPORT_FILE, report)

puts "wrote #{TRIAGE_FILE.sub(ROOT + "/", "")} (#{triage_rows.size} rows)"
puts "wrote #{REPORT_FILE.sub(ROOT + "/", "")}"
