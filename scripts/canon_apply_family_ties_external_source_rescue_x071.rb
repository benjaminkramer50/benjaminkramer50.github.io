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

PACKET_ID = "X071"
TARGET_WORK_ID = "work_candidate_latcarib_lit_family_ties"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x071.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_055_x071_family_ties_external_source_rescue.md")

APPLIED_HEADERS = %w[
  applied_id work_id title creator source_id source_item_id evidence_id source_type
  evidence_type evidence_strength reviewer_status source_debt_status_before
  source_debt_status_after action_lane_after resolution_status next_action rationale
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
    "source_id" => "x071_britannica_family_ties_reference",
    "source_title" => "Britannica: Family Ties",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Work-specific Britannica entry for Clarice Lispector's Family Ties / Lacos de familia",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopaedia Britannica, Family Ties, https://www.britannica.com/topic/Family-Ties-by-Lispector",
    "edition" => "online reference entry",
    "editors_or_authors" => "Encyclopaedia Britannica",
    "publisher" => "Encyclopaedia Britannica",
    "coverage_limits" => "Work-specific reference support only",
    "extraction_method" => "Targeted X071 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Confirms Family Ties as a work by Lispector and gives the Portuguese title Lacos de familia."
  },
  {
    "source_id" => "x071_britannica_brazilian_literature_reference",
    "source_title" => "Britannica: Brazilian literature, The short story",
    "source_type" => "language_literary_history",
    "source_scope" => "Britannica Brazilian literature overview with work-specific Family Ties discussion",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopaedia Britannica, Brazilian literature: The short story, https://www.britannica.com/art/Brazilian-literature/The-short-story",
    "edition" => "online literary-history overview",
    "editors_or_authors" => "Encyclopaedia Britannica",
    "publisher" => "Encyclopaedia Britannica",
    "coverage_limits" => "Literary-history overview; supports work identity, form, and reception context",
    "extraction_method" => "Targeted X071 public literary-history review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Identifies Lacos de familia (1960; Family Ties) as perhaps Lispector's most famous story collection."
  },
  {
    "source_id" => "x071_encyclopedia_com_lispector_reference",
    "source_title" => "Encyclopedia.com: Lispector, Clarice",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Encyclopedia.com author entry listing Lacos de familia / Family Ties and discussing the collection",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopedia.com, Lispector, Clarice, https://www.encyclopedia.com/arts/encyclopedias-almanacs-transcripts-and-maps/lispector-clarice",
    "edition" => "online reference entry",
    "editors_or_authors" => "Encyclopedia.com / Gale",
    "publisher" => "Encyclopedia.com / Gale",
    "coverage_limits" => "Author reference entry; supports publication history and collection context",
    "extraction_method" => "Targeted X071 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Lists Lacos de familia, 1960, translated as Family Ties in 1972, under Lispector's short stories."
  },
  {
    "source_id" => "x071_ebsco_family_ties_research_starter",
    "source_title" => "EBSCO Research Starters: Family Ties by Clarice Lispector",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Public EBSCO literature research starter for Family Ties with contents and reception summary",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "EBSCO Research Starters, Family Ties by Clarice Lispector, https://www.ebsco.com/research-starters/literature-and-writing/family-ties-clarice-lispector",
    "edition" => "online literature reference summary",
    "editors_or_authors" => "Keith H. Brower / EBSCO Research Starters",
    "publisher" => "EBSCO",
    "coverage_limits" => "Reference summary; useful for exact contents and reception, not a teaching-anthology vote",
    "extraction_method" => "Targeted X071 public contents/reception review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Confirms Family Ties as a thirteen-story collection and lists both local component-row titles among its contents."
  }
].freeze

SOURCE_ITEM_ROWS = [
  {
    "source_id" => "x071_britannica_family_ties_reference",
    "source_item_id" => "x071_britannica_family_ties",
    "raw_title" => "Family Ties / Lacos de familia",
    "raw_creator" => "Clarice Lispector",
    "raw_date" => "1960",
    "source_rank" => "",
    "source_section" => "Family Ties entry",
    "source_url" => "https://www.britannica.com/topic/Family-Ties-by-Lispector",
    "source_citation" => "Encyclopaedia Britannica, Family Ties",
    "matched_work_id" => TARGET_WORK_ID,
    "match_method" => "x071_exact_work_specific_public_reference_alias",
    "match_confidence" => "0.98",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X071 accepted as external work-level support; local story rows remain selection/component evidence."
  },
  {
    "source_id" => "x071_britannica_brazilian_literature_reference",
    "source_item_id" => "x071_britannica_brazilian_literature_family_ties",
    "raw_title" => "Lacos de familia / Family Ties",
    "raw_creator" => "Clarice Lispector",
    "raw_date" => "1960",
    "source_rank" => "",
    "source_section" => "Brazilian literature: The short story",
    "source_url" => "https://www.britannica.com/art/Brazilian-literature/The-short-story",
    "source_citation" => "Encyclopaedia Britannica, Brazilian literature: The short story",
    "matched_work_id" => TARGET_WORK_ID,
    "match_method" => "x071_literary_history_exact_work_reference",
    "match_confidence" => "0.97",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "language_literary_history_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X071 accepted as independent literary-history support for the named collection."
  },
  {
    "source_id" => "x071_encyclopedia_com_lispector_reference",
    "source_item_id" => "x071_encyclopedia_com_lispector_family_ties",
    "raw_title" => "Lacos de familia; Family Ties",
    "raw_creator" => "Clarice Lispector",
    "raw_date" => "1960; English 1972",
    "source_rank" => "",
    "source_section" => "Publications: Short Stories",
    "source_url" => "https://www.encyclopedia.com/arts/encyclopedias-almanacs-transcripts-and-maps/lispector-clarice",
    "source_citation" => "Encyclopedia.com, Lispector, Clarice",
    "matched_work_id" => TARGET_WORK_ID,
    "match_method" => "x071_exact_author_bibliography_reference",
    "match_confidence" => "0.96",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "reference_publication_history_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X071 accepted as independent reference support for title, creator, publication date, and English title."
  },
  {
    "source_id" => "x071_ebsco_family_ties_research_starter",
    "source_item_id" => "x071_ebsco_family_ties_research_starter",
    "raw_title" => "Family Ties",
    "raw_creator" => "Clarice Lispector",
    "raw_date" => "1960; English translation 1972",
    "source_rank" => "",
    "source_section" => "Family Ties by Clarice Lispector",
    "source_url" => "https://www.ebsco.com/research-starters/literature-and-writing/family-ties-clarice-lispector",
    "source_citation" => "EBSCO Research Starters, Family Ties by Clarice Lispector",
    "matched_work_id" => TARGET_WORK_ID,
    "match_method" => "x071_exact_work_contents_reference",
    "match_confidence" => "0.96",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "reference_contents_and_reception_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X071 confirms collection contents include Preciousness and The Crime of the Mathematics Professor; this still does not promote the local component rows as complete-work evidence."
  }
].freeze

EVIDENCE_ROWS = SOURCE_ITEM_ROWS.map do |row|
  {
    "evidence_id" => "x071_ev_#{row.fetch("source_item_id").sub(/\Ax071_/, "")}",
    "work_id" => row.fetch("matched_work_id"),
    "source_id" => row.fetch("source_id"),
    "source_item_id" => row.fetch("source_item_id"),
    "evidence_type" => "inclusion",
    "evidence_strength" => "moderate",
    "page_or_section" => row.fetch("source_section"),
    "quote_or_note" => "",
    "packet_id" => PACKET_ID,
    "supports_tier" => "",
    "supports_boundary_policy_id" => "",
    "reviewer_status" => "accepted",
    "notes" => "X071 accepted targeted public source support for Family Ties; not a cut approval or public-canon replacement."
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

def update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows)
  return unless File.exist?(MANIFEST_PATH)

  manifest = YAML.load_file(MANIFEST_PATH)
  artifacts = manifest.fetch("artifacts")
  counts = manifest.fetch("current_counts")
  source_item_rows = read_tsv(SOURCE_ITEMS_PATH)
  scoring_input_rows = read_tsv(File.join(TABLE_DIR, "canon_scoring_inputs.tsv"))

  manifest["status"] = "family_ties_external_source_rescue_x071_applied"
  artifacts["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_x025_x026_x027_x036_x043_x064_x066_x067_x068_x070_and_x071_source_items"
  artifacts["evidence"] = "e001_ingested_x001_x006_pilot_plus_x017_policy_aware_rows_after_x043_plus_x058_x062_x066_x067_x068_representative_selection_x064_complete_work_support_x070_external_support_and_x071_family_ties_support"
  artifacts["source_debt_status"] = "refreshed_after_x071_family_ties_external_source_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x071_family_ties_external_source_rescue"
  artifacts["scores"] = "regenerated_x071_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x071_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x071_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x071_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x071_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x071_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x071_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x071"] = "generated_x071_for_family_ties_source_rescue"

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
  counts["x071_external_source_rescue_rows"] = applied_rows.size
  counts["x071_family_ties_source_debt_closed"] = source_debt_after.fetch(TARGET_WORK_ID).fetch("source_debt_status").start_with?("open_") ? 0 : 1
  counts["current_high_risk_residue_rows_after_x071"] = high_risk_rows.size

  manifest["targeted_external_source_rescue_x071"] = {
    "status" => "applied_public_sources_for_family_ties",
    "target_work_rows" => 1,
    "source_registry_rows_added_or_updated" => REGISTRY_ROWS.size,
    "source_item_rows_added_or_updated" => SOURCE_ITEM_ROWS.size,
    "evidence_rows_added_or_updated" => EVIDENCE_ROWS.size,
    "target_source_debt_closed_after_refresh" => counts["x071_family_ties_source_debt_closed"],
    "lane_counts_after_refresh" => lane_counts,
    "current_high_risk_residue_rows_after_refresh" => high_risk_rows.size,
    "direct_replacements" => 0
  }

  File.write(MANIFEST_PATH, manifest.to_yaml)
end

def write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)
  FileUtils.mkdir_p(File.dirname(REPORT_PATH))
  after_status = source_debt_after.fetch(TARGET_WORK_ID).fetch("source_debt_status")

  File.open(REPORT_PATH, "w") do |file|
    file.puts "# X071 Family Ties External Source Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X071 closes the `Family Ties` source-debt blocker with work-level public evidence. It does not use the local story-selection rows as complete-work support, even though the EBSCO reference confirms those story titles belong to the collection."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_apply_family_ties_external_source_rescue_x071.rb`."
    file.puts "- Added `canon_external_source_rescue_evidence_applied_x071.tsv`."
    file.puts "- Added or updated #{REGISTRY_ROWS.size} source-registry rows, #{SOURCE_ITEM_ROWS.size} source-item rows, and #{EVIDENCE_ROWS.size} accepted evidence rows."
    file.puts "- Refreshed source-debt, scoring, cut-side, current-scope, and high-risk residue tables."
    file.puts
    file.puts "Source debt after X071: `#{after_status}`."
    file.puts
    file.puts "Evidence summary:"
    file.puts
    file.puts "| Source | Evidence row | Strength |"
    file.puts "|---|---|---|"
    applied_rows.each do |row|
      file.puts "| `#{row.fetch("source_id")}` | `#{row.fetch("evidence_id")}` | `#{row.fetch("evidence_strength")}` |"
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
    file.puts "Family Ties is no longer a source-debt blocker. Any future cut decision still requires normal pair, duplicate, chronology, boundary, and selection-basis review; X071 approves no cut and no replacement."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

source_debt_before = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }

registry_rows = upsert_rows(read_tsv(SOURCE_REGISTRY_PATH), REGISTRY_ROWS, "source_id")
source_item_rows = upsert_rows(read_tsv(SOURCE_ITEMS_PATH), SOURCE_ITEM_ROWS, "source_item_id")
evidence_rows = upsert_rows(read_tsv(EVIDENCE_PATH), EVIDENCE_ROWS, "evidence_id")

write_tsv(SOURCE_REGISTRY_PATH, tsv_headers(SOURCE_REGISTRY_PATH), registry_rows, sort_key: "source_id")
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_item_rows)
write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_rows)

refresh_downstream!

source_debt_after = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
actions_by_work = read_tsv(ACTION_QUEUE_PATH).to_h { |row| [row.fetch("cut_work_id"), row] }
lane_counts = read_tsv(ACTION_QUEUE_PATH).each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("current_lane")] += 1 }
high_risk_rows = read_tsv(HIGH_RISK_RESIDUE_PATH).select { |row| row.fetch("residue_status") == "current_high_risk_scope_blocker" }
source_type_by_id = REGISTRY_ROWS.to_h { |row| [row.fetch("source_id"), row.fetch("source_type")] }

applied_rows = EVIDENCE_ROWS.map.with_index(1) do |evidence, index|
  source_item = SOURCE_ITEM_ROWS.find { |row| row.fetch("source_item_id") == evidence.fetch("source_item_id") }
  before_status = source_debt_before.fetch(TARGET_WORK_ID).fetch("source_debt_status")
  after_status = source_debt_after.fetch(TARGET_WORK_ID).fetch("source_debt_status")
  action_lane = actions_by_work[TARGET_WORK_ID]&.fetch("current_lane").to_s
  resolution_status =
    if !after_status.start_with?("open_")
      "source_debt_closed_after_external_support"
    elsif after_status != before_status
      "source_debt_partially_improved"
    else
      "source_debt_still_open_after_external_support"
    end

  {
    "applied_id" => "x071_external_source_rescue_#{index.to_s.rjust(4, "0")}",
    "work_id" => TARGET_WORK_ID,
    "title" => source_item.fetch("raw_title"),
    "creator" => source_item.fetch("raw_creator"),
    "source_id" => evidence.fetch("source_id"),
    "source_item_id" => evidence.fetch("source_item_id"),
    "evidence_id" => evidence.fetch("evidence_id"),
    "source_type" => source_type_by_id.fetch(evidence.fetch("source_id")),
    "evidence_type" => evidence.fetch("evidence_type"),
    "evidence_strength" => evidence.fetch("evidence_strength"),
    "reviewer_status" => evidence.fetch("reviewer_status"),
    "source_debt_status_before" => before_status,
    "source_debt_status_after" => after_status,
    "action_lane_after" => action_lane,
    "resolution_status" => resolution_status,
    "next_action" => action_lane.empty? ? "review_cut_side_scoring_after_refresh" : actions_by_work.fetch(TARGET_WORK_ID).fetch("next_action"),
    "rationale" => "External work-level source support added; local component rows were not promoted to complete-work evidence."
  }
end

write_tsv(APPLIED_PATH, APPLIED_HEADERS, applied_rows)

after_status = source_debt_after.fetch(TARGET_WORK_ID).fetch("source_debt_status")
closed_count = after_status.start_with?("open_") ? 0 : 1

update_packet_status(
  {
    "packet_id" => PACKET_ID,
    "packet_family" => "X",
    "scope" => "targeted external source rescue for Family Ties by Clarice Lispector",
    "status" => "targeted_external_source_rescue_applied",
    "gate" => "cut_and_replacement_review_still_required",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x071.tsv",
      "scripts/canon_apply_family_ties_external_source_rescue_x071.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_055_x071_family_ties_external_source_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_after_family_ties_rescue",
    "notes" => "#{EVIDENCE_ROWS.size} accepted external evidence rows applied for Family Ties; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X071 Family Ties external source evidence rows"
puts "Family Ties source debt status: #{after_status}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
