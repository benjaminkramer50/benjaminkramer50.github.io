#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")

PACKET_ID = "X072"
WORK_ID = "work_candidate_bloom_reviewed_hughes_poems"
OLD_TITLE = "The Weary Blues and Selected Poems"
OLD_DATE_LABEL = "20th century; includes Harlem Renaissance collections from 1926 onward"
OLD_SORT_YEAR = "1950"
OLD_DATE_PRECISION = "century"
OLD_FORM_BUCKET = "taxonomy_pending"
BEFORE_SOURCE_DEBT_STATUS = "open_selection_only"
X072_NOTE = "X072 build-layer title/scope correction: public sources support The Weary Blues, not the former composite selected-poems label."

WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
CORRECTION_PATH = File.join(TABLE_DIR, "canon_title_scope_corrections_x072.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_056_x072_hughes_title_scope_rescue.md")

CORRECTION_HEADERS = %w[
  correction_id work_id old_title corrected_title creator old_date_label corrected_date_label
  old_sort_year corrected_sort_year old_date_precision corrected_date_precision old_form_bucket
  corrected_form_bucket source_ids evidence_ids source_debt_status_before source_debt_status_after
  action_lane_after correction_status next_action rationale
].freeze

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

DOWNSTREAM_SCRIPTS = %w[
  scripts/canon_report_source_debt_status.rb
  scripts/canon_generate_scoring_inputs.rb
  scripts/canon_generate_scores.rb
  scripts/canon_generate_cut_candidates.rb
  scripts/canon_generate_replacement_pairings.rb
  scripts/canon_generate_pair_review_queue.rb
  scripts/canon_generate_cut_review_work_orders.rb
  scripts/canon_generate_generic_selection_basis_review.rb
  scripts/canon_generate_cut_side_post_x058_action_queue.rb
  scripts/canon_generate_current_rescue_scope_refresh_x065.rb
  scripts/canon_generate_high_risk_rescue_residue_x063.rb
  scripts/canon_report_source_item_progress.rb
].freeze

REGISTRY_ROWS = [
  {
    "source_id" => "x072_poets_org_weary_blues_book_page",
    "source_title" => "Academy of American Poets: The Weary Blues",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Academy of American Poets book page for Langston Hughes's The Weary Blues",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Academy of American Poets, The Weary Blues, https://poets.org/book/weary-blues",
    "edition" => "online book reference page",
    "editors_or_authors" => "Academy of American Poets",
    "publisher" => "Academy of American Poets",
    "coverage_limits" => "Book page; supports corrected complete-work scope, contents, publisher, and reception",
    "extraction_method" => "Targeted X072 public title-scope review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Identifies The Weary Blues as Hughes's 1926 debut poetry collection and an American classic."
  },
  {
    "source_id" => "x072_poets_org_weary_blues_essay",
    "source_title" => "Academy of American Poets: On Langston Hughes's The Weary Blues",
    "source_type" => "prize_or_reception_layer",
    "source_scope" => "Kevin Young essay on the literary significance of The Weary Blues",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Kevin Young, On Langston Hughes's The Weary Blues, Academy of American Poets, https://poets.org/text/langston-hughess-weary-blues",
    "edition" => "online critical essay",
    "editors_or_authors" => "Kevin Young",
    "publisher" => "Academy of American Poets",
    "coverage_limits" => "Reception/context layer; supports significance and corrected title scope, not anthology selection",
    "extraction_method" => "Targeted X072 public reception review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Describes The Weary Blues as Hughes's first book, published by Knopf in 1926, and a Harlem Renaissance/modernist high point."
  },
  {
    "source_id" => "x072_britannica_weary_blues_reference",
    "source_title" => "Britannica: The Weary Blues",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Work-specific Britannica page for The Weary Blues",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopaedia Britannica, The Weary Blues, https://www.britannica.com/topic/The-Weary-Blues",
    "edition" => "online reference entry",
    "editors_or_authors" => "Encyclopaedia Britannica",
    "publisher" => "Encyclopaedia Britannica",
    "coverage_limits" => "Work-specific reference support only",
    "extraction_method" => "Targeted X072 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Identifies The Weary Blues as poetry by Hughes and links it to 1926 publication contexts."
  },
  {
    "source_id" => "x072_britannica_hughes_biography_reference",
    "source_title" => "Britannica: Langston Hughes",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Britannica biography passage identifying The Weary Blues as the Knopf 1926 collection",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopaedia Britannica, Langston Hughes, https://www.britannica.com/biography/Langston-Hughes",
    "edition" => "online biography",
    "editors_or_authors" => "Encyclopaedia Britannica",
    "publisher" => "Encyclopaedia Britannica",
    "coverage_limits" => "Author biography; supports publication identity and date for corrected scope",
    "extraction_method" => "Targeted X072 public biography review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Confirms Knopf accepted the collection published as The Weary Blues in 1926."
  }
].freeze

SOURCE_ITEM_ROWS = [
  {
    "source_id" => "x072_poets_org_weary_blues_book_page",
    "source_item_id" => "x072_poets_org_weary_blues",
    "raw_title" => "The Weary Blues",
    "raw_creator" => "Langston Hughes",
    "raw_date" => "1926",
    "source_rank" => "",
    "source_section" => "The Weary Blues book page",
    "source_url" => "https://poets.org/book/weary-blues",
    "source_citation" => "Academy of American Poets, The Weary Blues",
    "matched_work_id" => WORK_ID,
    "match_method" => "x072_corrected_title_exact_book_reference",
    "match_confidence" => "0.98",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "corrected_scope_complete_poetry_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X072 support for corrected build-layer title The Weary Blues; does not support the former composite selected-poems label."
  },
  {
    "source_id" => "x072_poets_org_weary_blues_essay",
    "source_item_id" => "x072_poets_org_weary_blues_essay",
    "raw_title" => "The Weary Blues",
    "raw_creator" => "Langston Hughes",
    "raw_date" => "1926",
    "source_rank" => "",
    "source_section" => "On Langston Hughes's The Weary Blues",
    "source_url" => "https://poets.org/text/langston-hughess-weary-blues",
    "source_citation" => "Kevin Young, On Langston Hughes's The Weary Blues",
    "matched_work_id" => WORK_ID,
    "match_method" => "x072_corrected_title_reception_reference",
    "match_confidence" => "0.96",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.35",
    "supports" => "corrected_scope_reception_poetry_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X072 reception support for corrected complete-work scope."
  },
  {
    "source_id" => "x072_britannica_weary_blues_reference",
    "source_item_id" => "x072_britannica_weary_blues",
    "raw_title" => "The Weary Blues",
    "raw_creator" => "Langston Hughes",
    "raw_date" => "1926",
    "source_rank" => "",
    "source_section" => "The Weary Blues entry",
    "source_url" => "https://www.britannica.com/topic/The-Weary-Blues",
    "source_citation" => "Encyclopaedia Britannica, The Weary Blues",
    "matched_work_id" => WORK_ID,
    "match_method" => "x072_corrected_title_public_reference",
    "match_confidence" => "0.97",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "corrected_scope_reference_poetry_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X072 exact work reference for corrected title scope."
  },
  {
    "source_id" => "x072_britannica_hughes_biography_reference",
    "source_item_id" => "x072_britannica_hughes_biography_weary_blues",
    "raw_title" => "The Weary Blues",
    "raw_creator" => "Langston Hughes",
    "raw_date" => "1926",
    "source_rank" => "",
    "source_section" => "Langston Hughes biography: From Joplin to Harlem",
    "source_url" => "https://www.britannica.com/biography/Langston-Hughes",
    "source_citation" => "Encyclopaedia Britannica, Langston Hughes",
    "matched_work_id" => WORK_ID,
    "match_method" => "x072_corrected_title_biography_reference",
    "match_confidence" => "0.95",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "corrected_scope_biography_poetry_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X072 biography support for corrected title and publication year."
  }
].freeze

EVIDENCE_ROWS = SOURCE_ITEM_ROWS.map do |row|
  {
    "evidence_id" => "x072_ev_#{row.fetch("source_item_id").sub(/\Ax072_/, "")}",
    "work_id" => row.fetch("matched_work_id"),
    "source_id" => row.fetch("source_id"),
    "source_item_id" => row.fetch("source_item_id"),
    "evidence_type" => "inclusion",
    "evidence_strength" => row.fetch("evidence_weight").to_f >= 0.55 ? "moderate" : "weak",
    "page_or_section" => row.fetch("source_section"),
    "quote_or_note" => "",
    "packet_id" => PACKET_ID,
    "supports_tier" => "",
    "supports_boundary_policy_id" => "",
    "reviewer_status" => "accepted",
    "notes" => "X072 accepted after correcting build-layer scope from the composite selected-poems label to The Weary Blues; not a cut approval or public-canon replacement."
  }
end.freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def tsv_headers(path)
  CSV.open(path, col_sep: "\t", &:readline)
end

def write_tsv(path, headers, rows, sort_key: nil)
  FileUtils.mkdir_p(File.dirname(path))
  rows = rows.sort_by { |row| row.fetch(sort_key).to_s } if sort_key
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def upsert_rows(existing_rows, new_rows, key)
  by_key = existing_rows.each_with_object({}) { |row, memo| memo[row.fetch(key)] = row }
  new_rows.each { |row| by_key[row.fetch(key)] = row }
  by_key.values
end

def normalize_title(value)
  value.to_s
       .unicode_normalize(:nfkd)
       .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
       .downcase
       .gsub(/[^a-z0-9]+/, " ")
       .strip
       .squeeze(" ")
end

def refresh_downstream!
  DOWNSTREAM_SCRIPTS.each do |script|
    ok = system("ruby", File.join(ROOT, script))
    raise "Downstream refresh failed at #{script}" unless ok
  end
end

def update_packet_status(row)
  rows = File.exist?(PACKET_STATUS_PATH) ? read_tsv(PACKET_STATUS_PATH) : []
  rows.reject! { |existing| existing.fetch("packet_id") == PACKET_ID }
  rows << row
  write_tsv(PACKET_STATUS_PATH, PACKET_STATUS_HEADERS, rows, sort_key: "packet_id")
end

def update_manifest(correction_row, source_debt_after, lane_counts, high_risk_rows)
  return unless File.exist?(MANIFEST_PATH)

  manifest = YAML.load_file(MANIFEST_PATH)
  artifacts = manifest.fetch("artifacts")
  counts = manifest.fetch("current_counts")
  source_item_rows = read_tsv(SOURCE_ITEMS_PATH)
  scoring_input_rows = read_tsv(File.join(TABLE_DIR, "canon_scoring_inputs.tsv"))

  manifest["status"] = "hughes_title_scope_rescue_x072_applied"
  artifacts["work_candidates"] = "build_layer_hughes_title_scope_corrected_x072_public_path_unchanged"
  artifacts["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_x025_x026_x027_x036_x043_x064_x066_x067_x068_x070_x071_and_x072_source_items"
  artifacts["evidence"] = "e001_ingested_x001_x006_pilot_plus_x017_policy_aware_rows_after_x043_plus_x058_x062_x066_x067_x068_representative_selection_x064_complete_work_support_x070_x071_external_support_and_x072_hughes_title_scope_support"
  artifacts["source_debt_status"] = "refreshed_after_x072_hughes_title_scope_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x072_hughes_title_scope_rescue"
  artifacts["scores"] = "regenerated_x072_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x072_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x072_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x072_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x072_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x072_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x072_from_current_x065_high_risk_rows"
  artifacts["title_scope_corrections_x072"] = "generated_x072_hughes_composite_title_to_weary_blues"

  counts["source_registry_rows"] = read_tsv(SOURCE_REGISTRY_PATH).size
  counts["source_items"] = source_item_rows.size
  counts["evidence_rows"] = read_tsv(EVIDENCE_PATH).size
  counts["source_debt_status_rows"] = source_debt_after.size
  counts["scoring_input_rows"] = scoring_input_rows.size
  counts["scoring_ready_rows"] = scoring_input_rows.count { |row| row.fetch("scoring_readiness") == "ready_for_score_computation" }
  counts["scoring_blocked_rows"] = scoring_input_rows.count { |row| row.fetch("scoring_readiness") == "blocked_from_score_computation" }
  counts["score_rows"] = read_tsv(File.join(TABLE_DIR, "canon_scores.tsv")).size
  counts["replacement_candidate_rows"] = read_tsv(File.join(TABLE_DIR, "canon_replacement_candidates.tsv")).size
  counts["replacement_pair_review_queue_rows"] = read_tsv(File.join(TABLE_DIR, "canon_replacement_pair_review_queue.tsv")).size
  counts["cut_review_work_order_rows"] = read_tsv(File.join(TABLE_DIR, "canon_cut_review_work_orders.tsv")).size
  counts["generic_selection_basis_review_rows"] = read_tsv(File.join(TABLE_DIR, "canon_generic_selection_basis_review.tsv")).size
  counts["cut_side_post_x058_action_queue_rows"] = read_tsv(ACTION_QUEUE_PATH).size
  counts["current_rescue_scope_review_rows"] = read_tsv(SCOPE_REVIEW_PATH).size
  counts["high_risk_rescue_residue_rows"] = read_tsv(HIGH_RISK_RESIDUE_PATH).size
  counts["cut_candidate_rows"] = read_tsv(File.join(TABLE_DIR, "canon_cut_candidates.tsv")).size
  counts["source_items_matched_current_path"] = source_item_rows.count { |row| row.fetch("match_status") == "matched_current_path" }
  counts["source_items_matched_candidate"] = source_item_rows.count { |row| row.fetch("match_status") == "matched_candidate" }
  counts["source_items_represented_by_selection"] = source_item_rows.count { |row| row.fetch("match_status") == "represented_by_selection" }
  counts["source_items_out_of_scope"] = source_item_rows.count { |row| row.fetch("match_status") == "out_of_scope" }
  counts["source_items_unmatched"] = source_item_rows.count { |row| row.fetch("match_status") == "unmatched" }
  counts["x072_title_scope_correction_rows"] = 1
  counts["x072_evidence_rows_added_or_updated"] = EVIDENCE_ROWS.size
  counts["x072_hughes_source_debt_closed"] = correction_row.fetch("source_debt_status_after").start_with?("open_") ? 0 : 1
  counts["current_high_risk_residue_rows_after_x072"] = high_risk_rows.size

  manifest["title_scope_rescue_x072"] = {
    "status" => "applied_hughes_build_layer_title_scope_correction",
    "target_work_rows" => 1,
    "old_title" => correction_row.fetch("old_title"),
    "corrected_title" => correction_row.fetch("corrected_title"),
    "source_registry_rows_added_or_updated" => REGISTRY_ROWS.size,
    "source_item_rows_added_or_updated" => SOURCE_ITEM_ROWS.size,
    "evidence_rows_added_or_updated" => EVIDENCE_ROWS.size,
    "source_debt_status_after_refresh" => correction_row.fetch("source_debt_status_after"),
    "lane_counts_after_refresh" => lane_counts,
    "current_high_risk_residue_rows_after_refresh" => high_risk_rows.size,
    "direct_replacements" => 0
  }

  File.write(MANIFEST_PATH, manifest.to_yaml)
end

def write_report(correction_row, lane_counts, high_risk_rows)
  FileUtils.mkdir_p(File.dirname(REPORT_PATH))

  File.open(REPORT_PATH, "w") do |file|
    file.puts "# X072 Hughes Title-Scope Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X072 resolves the Hughes title/scope blocker held in X064. The old build-layer label `The Weary Blues and Selected Poems` was a composite convenience label; public sources support `The Weary Blues` as Hughes's 1926 debut poetry collection."
    file.puts
    file.puts "## Correction"
    file.puts
    file.puts "| Work ID | Old title | Corrected title | Source debt after X072 | Lane after refresh |"
    file.puts "|---|---|---|---|---|"
    file.puts "| `#{correction_row.fetch("work_id")}` | #{correction_row.fetch("old_title")} | #{correction_row.fetch("corrected_title")} | `#{correction_row.fetch("source_debt_status_after")}` | `#{correction_row.fetch("action_lane_after")}` |"
    file.puts
    file.puts "Evidence added:"
    file.puts
    file.puts "| Source | Evidence row |"
    file.puts "|---|---|"
    SOURCE_ITEM_ROWS.zip(EVIDENCE_ROWS).each do |source_item, evidence|
      file.puts "| `#{source_item.fetch("source_id")}` | `#{evidence.fetch("evidence_id")}` |"
    end
    file.puts
    file.puts "Cut-side lane summary after refresh:"
    file.puts
    file.puts "| Lane | Rows |"
    file.puts "|---|---:|"
    lane_counts.sort.each { |lane, count| file.puts "| `#{lane}` | #{count} |" }
    file.puts
    file.puts "Current high-risk residue after refresh: #{high_risk_rows.size}."
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "The Hughes row is no longer a source-debt or selected-work-scope blocker in the build layer. Residual generic/duplicate risk inherited from the older audit outputs still requires normal cut-side review before any pair can advance."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

work_rows = read_tsv(WORK_CANDIDATES_PATH)
source_debt_before = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
old_work = work_rows.find { |row| row.fetch("work_id") == WORK_ID }
raise "Missing target work #{WORK_ID}" unless old_work

work_rows = work_rows.map do |row|
  next row unless row.fetch("work_id") == WORK_ID

  base_notes = row.fetch("notes").sub(/\s+#{Regexp.escape(X072_NOTE)}\z/, "")
  row.merge(
    "canonical_title" => "The Weary Blues",
    "sort_title" => normalize_title("The Weary Blues"),
    "date_label" => "1926",
    "sort_year" => "1926",
    "date_precision" => "exact_year",
    "form_bucket" => "poetry_collection",
    "unit_type" => "poetry_collection",
    "selection_basis" => "Read the complete 1926 poetry collection.",
    "completion_unit" => "complete_work",
    "source_status" => "source_reviewed",
    "review_status" => "source_reviewed",
    "confidence" => "source_backed_after_x072",
    "notes" => "#{base_notes} #{X072_NOTE}"
  )
end

registry_rows = upsert_rows(read_tsv(SOURCE_REGISTRY_PATH), REGISTRY_ROWS, "source_id")
source_item_rows = upsert_rows(read_tsv(SOURCE_ITEMS_PATH), SOURCE_ITEM_ROWS, "source_item_id")
evidence_rows = upsert_rows(read_tsv(EVIDENCE_PATH), EVIDENCE_ROWS, "evidence_id")

write_tsv(WORK_CANDIDATES_PATH, tsv_headers(WORK_CANDIDATES_PATH), work_rows)
write_tsv(SOURCE_REGISTRY_PATH, tsv_headers(SOURCE_REGISTRY_PATH), registry_rows, sort_key: "source_id")
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_item_rows)
write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_rows)

refresh_downstream!

source_debt_after = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
actions_by_work = read_tsv(ACTION_QUEUE_PATH).to_h { |row| [row.fetch("cut_work_id"), row] }
lane_counts = read_tsv(ACTION_QUEUE_PATH).each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("current_lane")] += 1 }
high_risk_rows = read_tsv(HIGH_RISK_RESIDUE_PATH).select { |row| row.fetch("residue_status") == "current_high_risk_scope_blocker" }

before_status = BEFORE_SOURCE_DEBT_STATUS
after_status = source_debt_after.fetch(WORK_ID).fetch("source_debt_status")
action_lane = actions_by_work[WORK_ID]&.fetch("current_lane").to_s

correction_row = {
  "correction_id" => "x072_title_scope_0001",
  "work_id" => WORK_ID,
  "old_title" => OLD_TITLE,
  "corrected_title" => "The Weary Blues",
  "creator" => old_work.fetch("creator_display"),
  "old_date_label" => OLD_DATE_LABEL,
  "corrected_date_label" => "1926",
  "old_sort_year" => OLD_SORT_YEAR,
  "corrected_sort_year" => "1926",
  "old_date_precision" => OLD_DATE_PRECISION,
  "corrected_date_precision" => "exact_year",
  "old_form_bucket" => OLD_FORM_BUCKET,
  "corrected_form_bucket" => "poetry_collection",
  "source_ids" => REGISTRY_ROWS.map { |row| row.fetch("source_id") }.join(";"),
  "evidence_ids" => EVIDENCE_ROWS.map { |row| row.fetch("evidence_id") }.join(";"),
  "source_debt_status_before" => before_status,
  "source_debt_status_after" => after_status,
  "action_lane_after" => action_lane,
  "correction_status" => after_status.start_with?("open_") ? "scope_corrected_source_debt_still_open" : "scope_corrected_source_debt_closed",
  "next_action" => action_lane.empty? ? "review_cut_side_scoring_after_refresh" : actions_by_work.fetch(WORK_ID).fetch("next_action"),
  "rationale" => "Corrected build-layer scope to the sourced 1926 book; old composite title remains unsupported as complete-work scope."
}

write_tsv(CORRECTION_PATH, CORRECTION_HEADERS, [correction_row])

update_packet_status(
  {
    "packet_id" => PACKET_ID,
    "packet_family" => "X",
    "scope" => "Hughes build-layer title/scope correction and source rescue",
    "status" => "title_scope_rescue_applied",
    "gate" => "public_path_update_and_cut_review_still_required",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_title_scope_corrections_x072.tsv",
      "scripts/canon_apply_hughes_title_scope_rescue_x072.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_056_x072_hughes_title_scope_rescue.md"
    ].join(";"),
    "next_action" => "review_source_debt_closed_cut_side_rows_then_continue_external_acquisition_queue",
    "notes" => "Corrected Hughes build-layer title from The Weary Blues and Selected Poems to The Weary Blues; #{EVIDENCE_ROWS.size} evidence rows applied; source debt after refresh=#{after_status}; public canon unchanged"
  }
)

update_manifest(correction_row, source_debt_after, lane_counts, high_risk_rows)
write_report(correction_row, lane_counts, high_risk_rows)

puts "applied X072 Hughes title/scope correction"
puts "Hughes source debt status: #{after_status}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
