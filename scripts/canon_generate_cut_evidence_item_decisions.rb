#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

CUT_RESCUE_SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_cut_rescue_scope_review.tsv")
CUT_EVIDENCE_PROPOSALS_PATH = File.join(TABLE_DIR, "canon_cut_evidence_proposals.tsv")
CUT_EVIDENCE_ITEM_DECISIONS_PATH = File.join(TABLE_DIR, "canon_cut_evidence_item_decisions.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_040_x056_cut_evidence_item_decisions.md")

HEADERS = %w[
  item_decision_id proposal_id scope_review_id rescue_id cut_work_id cut_title cut_creator
  source_id source_item_id raw_title scope_review_class scope_risk item_decision
  decision_reason evidence_effect reviewer_status next_action
].freeze

NAMED_COLLECTION_PATTERNS = [
  /\bcollected poems\b/,
  /\blyrics of lowly life\b/,
  /\bthe weary blues and selected poems\b/
].freeze

NON_POEM_TITLE_PATTERNS = [
  /\bdialogue between\b/,
  /\bregarding art\b/
].freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def normalize(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip.squeeze(" ")
end

def named_collection_title?(title)
  normalized = normalize(title)
  NAMED_COLLECTION_PATTERNS.any? { |pattern| normalized.match?(pattern) }
end

def likely_non_poem_title?(raw_title)
  normalized = normalize(raw_title)
  NON_POEM_TITLE_PATTERNS.any? { |pattern| normalized.match?(pattern) }
end

def item_decision(row)
  return "blocked_high_scope_risk" if row.fetch("scope_risk") == "high"
  return "existing_evidence_scope_review_required" if row.fetch("scope_review_class") == "existing_linked_selection_evidence_review"
  return "blocked_named_collection_exact_support_required" if named_collection_title?(row.fetch("cut_title"))
  return "needs_form_review_before_representative_evidence" if likely_non_poem_title?(row.fetch("raw_title"))

  case row.fetch("scope_review_class")
  when "title_family_match_ode_source_item", "representative_poetry_selection_review"
    "ready_for_representative_selection_evidence_review"
  else
    "manual_item_scope_review_required"
  end
end

def decision_reason(decision)
  case decision
  when "blocked_high_scope_risk"
    "High-risk membership or form mismatch rows must be resolved before evidence generation."
  when "existing_evidence_scope_review_required"
    "Evidence already exists; update status only after confirming representative-selection scope."
  when "blocked_named_collection_exact_support_required"
    "Individual anthology source items do not establish exact support for a named collection."
  when "needs_form_review_before_representative_evidence"
    "The source item title appears non-poetic or mixed-form and needs form review."
  when "ready_for_representative_selection_evidence_review"
    "The source item is compatible with representative-selection evidence, subject to reviewer acceptance."
  else
    "Manual item-level scope review required."
  end
end

def evidence_effect(decision)
  case decision
  when "ready_for_representative_selection_evidence_review"
    "may_generate_review_gated_representative_selection_evidence"
  when "existing_evidence_scope_review_required"
    "may_update_existing_evidence_status_after_scope_review"
  else
    "no_evidence_change"
  end
end

def next_action(decision)
  case decision
  when "ready_for_representative_selection_evidence_review"
    "review_and_accept_or_reject_item_evidence"
  when "existing_evidence_scope_review_required"
    "review_existing_evidence_status"
  when "blocked_named_collection_exact_support_required"
    "find_exact_collection_support_or_keep_cut_candidate_source_debt_open"
  when "needs_form_review_before_representative_evidence"
    "review_item_form_before_any_evidence_generation"
  else
    "resolve_scope_blocker_before_evidence_generation"
  end
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  decision_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("item_decision")] += 1 }
  effect_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("evidence_effect")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X056 Cut Evidence Item Decisions"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X056 adjudicates X054 source-item rescue rows at item level. This avoids accepting an entire grouped proposal when only some source items are scope-compatible."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_cut_evidence_item_decisions.rb`."
    file.puts "- Added `canon_cut_evidence_item_decisions.tsv`."
    file.puts "- Generated #{rows.size} item-decision rows."
    file.puts
    file.puts "Item decision summary:"
    file.puts
    file.puts "| Decision | Rows |"
    file.puts "|---|---:|"
    decision_counts.sort.each { |decision, count| file.puts "| `#{decision}` | #{count} |" }
    file.puts
    file.puts "Evidence effect summary:"
    file.puts
    file.puts "| Effect | Rows |"
    file.puts "|---|---:|"
    effect_counts.sort.each { |effect, count| file.puts "| `#{effect}` | #{count} |" }
    file.puts
    file.puts "Ready-for-review item rows:"
    file.puts
    file.puts "| Decision ID | Cut title | Creator | Raw title | Source |"
    file.puts "|---|---|---|---|---|"
    rows.select { |row| row.fetch("item_decision") == "ready_for_representative_selection_evidence_review" }.first(14).each do |row|
      file.puts "| `#{row.fetch("item_decision_id")}` | #{row.fetch("cut_title")} | #{row.fetch("cut_creator")} | #{row.fetch("raw_title")} | `#{row.fetch("source_id")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "This packet still does not write accepted evidence. It identifies which source items can proceed to evidence review and which remain blocked because they support a different form, a named collection only indirectly, or a high-risk membership question."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

scope_rows = read_tsv(CUT_RESCUE_SCOPE_REVIEW_PATH)
proposal_by_scope_review = {}
read_tsv(CUT_EVIDENCE_PROPOSALS_PATH).each do |proposal|
  proposal.fetch("scope_review_ids").split(";").each do |scope_review_id|
    proposal_by_scope_review[scope_review_id] = proposal.fetch("proposal_id")
  end
end

decision_rows = scope_rows.map.with_index(1) do |row, index|
  decision = item_decision(row)
  {
    "item_decision_id" => "x056_cut_item_decision_#{index.to_s.rjust(4, "0")}",
    "proposal_id" => proposal_by_scope_review.fetch(row.fetch("scope_review_id"), ""),
    "scope_review_id" => row.fetch("scope_review_id"),
    "rescue_id" => row.fetch("rescue_id"),
    "cut_work_id" => row.fetch("cut_work_id"),
    "cut_title" => row.fetch("cut_title"),
    "cut_creator" => row.fetch("cut_creator"),
    "source_id" => row.fetch("source_id"),
    "source_item_id" => row.fetch("source_item_id"),
    "raw_title" => row.fetch("raw_title"),
    "scope_review_class" => row.fetch("scope_review_class"),
    "scope_risk" => row.fetch("scope_risk"),
    "item_decision" => decision,
    "decision_reason" => decision_reason(decision),
    "evidence_effect" => evidence_effect(decision),
    "reviewer_status" => "needs_manual_review",
    "next_action" => next_action(decision)
  }
end

write_tsv(CUT_EVIDENCE_ITEM_DECISIONS_PATH, HEADERS, decision_rows)
write_report(REPORT_PATH, decision_rows)

puts "wrote #{CUT_EVIDENCE_ITEM_DECISIONS_PATH.sub(ROOT + "/", "")} (#{decision_rows.size} rows)"
decision_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("item_decision")] += 1 }.sort.each do |decision, count|
  puts "#{decision}: #{count}"
end
