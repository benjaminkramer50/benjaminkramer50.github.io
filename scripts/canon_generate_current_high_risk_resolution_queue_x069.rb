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

PACKET_ID = "X069"

SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
QUEUE_PATH = File.join(TABLE_DIR, "canon_current_high_risk_resolution_queue.tsv")
WORK_QUEUE_PATH = File.join(TABLE_DIR, "canon_current_high_risk_work_resolution.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_053_x069_current_high_risk_resolution_queue.md")

QUEUE_HEADERS = %w[
  resolution_id residue_id scope_review_id action_id cut_work_id cut_title cut_creator
  source_id source_item_id raw_title raw_creator source_item_form scope_review_class
  high_risk_issue resolution_decision existing_source_item_effect evidence_generation_gate
  source_debt_effect required_external_support reviewer_status next_action rationale
].freeze

WORK_HEADERS = %w[
  work_resolution_id cut_work_id cut_title cut_creator high_risk_source_rows
  source_debt_status dominant_issue work_resolution_decision local_source_resolution
  external_source_strategy next_action rationale
].freeze

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

KNOWN_POEM_TITLES = [
  "a far cry from africa",
  "volcano",
  "the fortunate traveller",
  "child of europe"
].freeze

KNOWN_NON_POEM_OR_WRONG_SCOPE_TITLES = [
  "the two flags",
  "regarding art"
].freeze

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

def normalize(value)
  value.to_s
       .unicode_normalize(:nfkd)
       .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
       .downcase
       .gsub(/[^a-z0-9]+/, " ")
       .strip
       .squeeze(" ")
end

def count_by(rows, key)
  rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch(key)] += 1 }
end

def safe_id(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
end

def story_collection?(title)
  normalize(title).match?(/\b(all fires the fire|blow up and other stories)\b/)
end

def named_poetry_collection?(title)
  normalize(title).match?(/\b(the tenth muse|collected poems 1948 1984)\b/)
end

def generic_poetry_selection?(title)
  normalize(title).match?(/\b(selected poems|collected poems)\b/)
end

def poem_source_item?(row)
  row.fetch("source_item_form") == "poem" ||
    row.fetch("source_id").include?("poetry") ||
    normalize(row.fetch("raw_title")).start_with?("para leer")
end

def known_poem_component?(row)
  KNOWN_POEM_TITLES.include?(normalize(row.fetch("raw_title")))
end

def known_non_poem_or_wrong_scope_component?(row)
  KNOWN_NON_POEM_OR_WRONG_SCOPE_TITLES.include?(normalize(row.fetch("raw_title")))
end

def high_risk_issue(row)
  case row.fetch("scope_review_class")
  when "named_collection_membership_unverified"
    "named_collection_membership_not_proven_by_current_source_item"
  when "creator_exact_component_form_unverified"
    "component_form_not_proven_for_current_selected_work"
  when "creator_exact_form_mismatch"
    "component_form_conflicts_with_current_selected_work"
  else
    "manual_high_risk_scope_issue"
  end
end

def resolution_decision(row)
  title = row.fetch("cut_title")

  if row.fetch("scope_review_class") == "named_collection_membership_unverified"
    return "reject_wrong_form_for_story_collection_support" if story_collection?(title) && poem_source_item?(row)
    return "hold_for_exact_story_collection_membership_source" if story_collection?(title)
    return "hold_for_exact_named_collection_membership_source" if named_poetry_collection?(title)

    return "hold_for_exact_named_collection_membership_source"
  end

  if row.fetch("scope_review_class") == "creator_exact_component_form_unverified"
    return "reject_or_hold_component_form_mismatch" if known_non_poem_or_wrong_scope_component?(row)
    return "needs_verified_poem_form_before_selection_evidence" if generic_poetry_selection?(title) && known_poem_component?(row)

    return "needs_component_form_verification_before_any_evidence"
  end

  "manual_high_risk_resolution_required"
end

def existing_source_item_effect(decision)
  case decision
  when "needs_verified_poem_form_before_selection_evidence"
    "leave_unmatched_until_form_source_confirms_selection_evidence"
  when "reject_wrong_form_for_story_collection_support", "reject_or_hold_component_form_mismatch"
    "do_not_generate_cut_side_evidence_from_current_source_item"
  else
    "leave_unmatched_until_exact_membership_or_external_support"
  end
end

def evidence_generation_gate(decision)
  case decision
  when "needs_verified_poem_form_before_selection_evidence"
    "blocked_until_public_form_verification"
  else
    "blocked_until_external_collection_or_scope_resolution"
  end
end

def required_external_support(row, decision)
  case decision
  when "needs_verified_poem_form_before_selection_evidence"
    "public_source_confirming_component_is_poem; complete_work_or_selected_work_support_still_needed"
  when "hold_for_exact_story_collection_membership_source"
    "public_source_confirming_story_collection_membership_or_independent_complete_collection_support"
  when "hold_for_exact_named_collection_membership_source"
    "public_source_confirming_named_collection_membership_or_independent_complete_collection_support"
  when "reject_wrong_form_for_story_collection_support"
    "independent_short_story_collection_support_for_current_title"
  when "reject_or_hold_component_form_mismatch"
    "independent_complete_work_support_or_corrected_current_work_scope"
  else
    "manual_external_support_review"
  end
end

def next_action(row, decision)
  case decision
  when "needs_verified_poem_form_before_selection_evidence"
    "verify_component_form_then_possible_selection_only_evidence"
  when "reject_wrong_form_for_story_collection_support", "reject_or_hold_component_form_mismatch"
    "skip_current_source_item_and_acquire_external_source_support"
  else
    "acquire_external_named_collection_or_complete_work_support"
  end
end

def rationale(row, decision)
  title = row.fetch("cut_title")
  raw_title = row.fetch("raw_title")

  case decision
  when "reject_wrong_form_for_story_collection_support"
    "#{raw_title} is a poem-level source item and cannot support the current story collection #{title}."
  when "hold_for_exact_story_collection_membership_source"
    "#{raw_title} may be a story-level component, but the current source item does not itself prove membership in #{title}."
  when "hold_for_exact_named_collection_membership_source"
    "#{raw_title} is an individual component row; it cannot establish support for the named collection #{title} without exact membership or separate complete-work support."
  when "needs_verified_poem_form_before_selection_evidence"
    "#{raw_title} is compatible with representative-poetry support, but X069 requires public form verification before accepting selection-only evidence."
  when "reject_or_hold_component_form_mismatch"
    "#{raw_title} is high risk for the current poetry selection and should not be promoted without independent form or work-scope support."
  else
    "High-risk scope class requires manual resolution before evidence generation."
  end
end

def work_resolution_decision(work_id, rows)
  title = rows.first.fetch("cut_title")

  case work_id
  when "work_candidate_mandatory_bradstreet_tenth_muse"
    [
      "external_complete_work_support_needed",
      "Do not treat individual Bradstreet anthology poems as complete-work support for The Tenth Muse.",
      "Acquire work-specific public reference support for The Tenth Muse; use poem rows only after exact membership review.",
      "acquire_external_complete_work_support"
    ]
  when "work_candidate_latcarib_lit_all_fires_fire"
    [
      "external_story_collection_support_needed",
      "Current local rows do not prove membership in All Fires the Fire; poem-level Cortazar source item is wrong form.",
      "Acquire independent support for Todos los fuegos el fuego / All Fires the Fire as Cortazar's 1966 story collection.",
      "acquire_external_story_collection_support"
    ]
  when "work_candidate_latcarib_lit_blow_up"
    [
      "external_story_collection_support_needed",
      "Axolotl may be reviewable only with exact collection-membership support; poem-level Cortazar source item is wrong form.",
      "Acquire public support for Blow-Up and Other Stories and exact Axolotl membership before any selection evidence.",
      "acquire_external_story_collection_support"
    ]
  when "work_candidate_latcarib_lit_walcott_collected_poems"
    [
      "external_collection_support_needed",
      "The current Longman poem rows may become selection-only support after form verification but do not close collection debt.",
      "Acquire public support for Collected Poems 1948-1984 as a collection; then optionally verify poem components.",
      "acquire_external_poetry_collection_support"
    ]
  when "work_candidate_completion_lit_selected_poems_milosz"
    [
      "form_verification_then_selection_only_possible",
      "Child of Europe can be reviewed as a poem component only after public form verification; it still does not close complete-work debt.",
      "Verify poem form and separately acquire selected-work support if this generic title remains in the path.",
      "verify_form_then_acquire_selected_work_support"
    ]
  when "work_candidate_global_lit_nazim_hikmet_poems"
    [
      "external_selected_work_or_form_correction_needed",
      "Regarding Art is high risk as a component for a Selected Poems incumbent and should not be auto-accepted.",
      "Acquire independent Hikmet poetry-collection support or resolve the component form before evidence generation.",
      "acquire_external_selected_work_support"
    ]
  when "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0835_collected_poems"
    [
      "external_collection_support_needed_and_local_row_probable_mismatch",
      "The Two Flags should not support Primo Levi Collected Poems without independent form verification.",
      "Acquire public complete-work support for Levi's Collected Poems and skip the current source item unless form is proven.",
      "acquire_external_poetry_collection_support"
    ]
  else
    [
      "manual_high_risk_resolution_required",
      "Current high-risk rows remain blocked.",
      "Acquire work-specific support or exact component-scope verification.",
      "manual_resolution"
    ]
  end.tap do |decision, _local, _external, _next_action|
    raise "blank work resolution for #{title}" if decision.to_s.empty?
  end
end

def update_packet_status(path, row)
  rows = File.exist?(path) ? read_tsv(path) : []
  rows.reject! { |existing| existing.fetch("packet_id") == PACKET_ID }
  rows << row
  write_tsv(path, PACKET_STATUS_HEADERS, rows, sort_key: "packet_id")
end

def update_manifest(queue_rows, work_rows)
  return unless File.exist?(MANIFEST_PATH)

  manifest = YAML.load_file(MANIFEST_PATH)
  artifacts = manifest.fetch("artifacts")
  counts = manifest.fetch("current_counts")

  manifest["status"] = "current_high_risk_resolution_queue_x069_generated"
  artifacts["current_high_risk_resolution_queue"] = "generated_x069_from_current_high_risk_scope_rows"
  artifacts["current_high_risk_work_resolution"] = "generated_x069_work_level_resolution_plan"
  counts["current_high_risk_resolution_queue_rows"] = queue_rows.size
  counts["current_high_risk_work_resolution_rows"] = work_rows.size

  manifest["current_high_risk_resolution_queue_x069"] = {
    "status" => "generated_from_current_x065_high_risk_rows",
    "resolution_rows" => queue_rows.size,
    "work_resolution_rows" => work_rows.size,
    "decision_counts" => count_by(queue_rows, "resolution_decision"),
    "evidence_rows_added" => 0,
    "complete_work_source_debt_closed" => 0,
    "direct_replacements" => 0
  }

  File.write(MANIFEST_PATH, manifest.to_yaml)
end

def write_report(queue_rows, work_rows)
  FileUtils.mkdir_p(File.dirname(REPORT_PATH))
  decision_counts = count_by(queue_rows, "resolution_decision")
  issue_counts = count_by(queue_rows, "high_risk_issue")

  File.open(REPORT_PATH, "w") do |file|
    file.puts "# X069 Current High-Risk Resolution Queue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X069 converts the remaining current high-risk source-item rescue rows into explicit resolution decisions. It does not write evidence. Its job is to prevent high-risk component rows from being promoted as collection or selected-work support without exact form, membership, or external work-level support."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_current_high_risk_resolution_queue_x069.rb`."
    file.puts "- Added `canon_current_high_risk_resolution_queue.tsv`."
    file.puts "- Added `canon_current_high_risk_work_resolution.tsv`."
    file.puts "- Classified #{queue_rows.size} high-risk source rows across #{work_rows.size} incumbent works."
    file.puts
    file.puts "Issue summary:"
    file.puts
    file.puts "| Issue | Rows |"
    file.puts "|---|---:|"
    issue_counts.sort.each { |issue, count| file.puts "| `#{issue}` | #{count} |" }
    file.puts
    file.puts "Decision summary:"
    file.puts
    file.puts "| Decision | Rows |"
    file.puts "|---|---:|"
    decision_counts.sort.each { |decision, count| file.puts "| `#{decision}` | #{count} |" }
    file.puts
    file.puts "Work-level resolution:"
    file.puts
    file.puts "| Work | Rows | Decision | Next action |"
    file.puts "|---|---:|---|---|"
    work_rows.each do |row|
      file.puts "| `#{row.fetch("cut_work_id")}` | #{row.fetch("high_risk_source_rows")} | `#{row.fetch("work_resolution_decision")}` | `#{row.fetch("next_action")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "The medium-risk lane is empty. The remaining local source rows are not safe evidence writes: they either require named-collection membership, independent collection support, or public component-form verification. X070 should therefore acquire targeted public sources for these seven works rather than continue trying to rescue high-risk rows from anthology components."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

scope_rows = read_tsv(SCOPE_REVIEW_PATH).select { |row| row.fetch("scope_risk") == "high" }
residue_by_scope = read_tsv(RESIDUE_PATH).to_h { |row| [row.fetch("scope_review_id"), row] }
source_debt_by_work = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }

queue_rows = scope_rows.map.with_index(1) do |row, index|
  residue = residue_by_scope.fetch(row.fetch("scope_review_id"))
  decision = resolution_decision(row)

  {
    "resolution_id" => "x069_high_risk_resolution_#{index.to_s.rjust(4, "0")}",
    "residue_id" => residue.fetch("residue_id"),
    "scope_review_id" => row.fetch("scope_review_id"),
    "action_id" => row.fetch("action_id"),
    "cut_work_id" => row.fetch("cut_work_id"),
    "cut_title" => row.fetch("cut_title"),
    "cut_creator" => row.fetch("cut_creator"),
    "source_id" => row.fetch("source_id"),
    "source_item_id" => row.fetch("source_item_id"),
    "raw_title" => row.fetch("raw_title"),
    "raw_creator" => row.fetch("raw_creator"),
    "source_item_form" => row.fetch("source_item_form"),
    "scope_review_class" => row.fetch("scope_review_class"),
    "high_risk_issue" => high_risk_issue(row),
    "resolution_decision" => decision,
    "existing_source_item_effect" => existing_source_item_effect(decision),
    "evidence_generation_gate" => evidence_generation_gate(decision),
    "source_debt_effect" => "does_not_close_source_debt",
    "required_external_support" => required_external_support(row, decision),
    "reviewer_status" => "reviewed_blocked",
    "next_action" => next_action(row, decision),
    "rationale" => rationale(row, decision)
  }
end

work_rows = queue_rows.group_by { |row| row.fetch("cut_work_id") }.sort.map.with_index(1) do |(work_id, rows), index|
  decision, local_resolution, external_strategy, next_action = work_resolution_decision(work_id, rows)
  source_debt = source_debt_by_work.fetch(work_id)
  dominant_issue = count_by(rows, "high_risk_issue").max_by { |_issue, count| count }.first

  {
    "work_resolution_id" => "x069_work_resolution_#{index.to_s.rjust(4, "0")}_#{safe_id(work_id)}",
    "cut_work_id" => work_id,
    "cut_title" => rows.first.fetch("cut_title"),
    "cut_creator" => rows.first.fetch("cut_creator"),
    "high_risk_source_rows" => rows.size.to_s,
    "source_debt_status" => source_debt.fetch("source_debt_status"),
    "dominant_issue" => dominant_issue,
    "work_resolution_decision" => decision,
    "local_source_resolution" => local_resolution,
    "external_source_strategy" => external_strategy,
    "next_action" => next_action,
    "rationale" => "X069 keeps evidence blocked until #{external_strategy.downcase}"
  }
end

write_tsv(QUEUE_PATH, QUEUE_HEADERS, queue_rows)
write_tsv(WORK_QUEUE_PATH, WORK_HEADERS, work_rows)

update_packet_status(
  PACKET_STATUS_PATH,
  {
    "packet_id" => PACKET_ID,
    "packet_family" => "X",
    "scope" => "current high-risk rescue resolution queue",
    "status" => "current_high_risk_resolution_queue_generated",
    "gate" => "evidence_blocked_pending_external_scope_support",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_current_high_risk_resolution_queue.tsv",
      "_planning/canon_build/tables/canon_current_high_risk_work_resolution.tsv",
      "scripts/canon_generate_current_high_risk_resolution_queue_x069.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_053_x069_current_high_risk_resolution_queue.md"
    ].join(";"),
    "next_action" => "acquire_targeted_external_sources_for_7_high_risk_works",
    "notes" => "#{queue_rows.size} high-risk rows classified; #{work_rows.size} work-level source-acquisition plans generated; no evidence or public canon change"
  }
)

update_manifest(queue_rows, work_rows)
write_report(queue_rows, work_rows)

puts "wrote #{QUEUE_PATH.sub(ROOT + "/", "")} (#{queue_rows.size} rows)"
puts "wrote #{WORK_QUEUE_PATH.sub(ROOT + "/", "")} (#{work_rows.size} rows)"
count_by(queue_rows, "resolution_decision").sort.each do |decision, count|
  puts "#{decision}: #{count}"
end
