#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

CUT_EVIDENCE_ITEM_DECISIONS_PATH = File.join(TABLE_DIR, "canon_cut_evidence_item_decisions.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
CUT_EVIDENCE_WRITE_PLAN_PATH = File.join(TABLE_DIR, "canon_cut_evidence_write_plan.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_041_x057_cut_evidence_write_plan.md")

HEADERS = %w[
  write_plan_id item_decision_id target_action proposed_evidence_id existing_evidence_id
  work_id source_id source_item_id evidence_type evidence_strength reviewer_status
  page_or_section packet_id write_gate write_rationale next_action
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

def evidence_strength_for(row)
  return "moderate" if row.fetch("source_id").include?("norton") || row.fetch("source_id").include?("longman")
  return "moderate" if row.fetch("source_id").include?("fsg") || row.fetch("source_id").include?("oxford")

  "weak"
end

def safe_id(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  action_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("target_action")] += 1 }
  strength_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("evidence_strength")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X057 Cut Evidence Write Plan"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X057 turns X056 ready item decisions into a proposed evidence write plan. It does not modify `canon_evidence.tsv`; each row is review-gated."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_cut_evidence_write_plan.rb`."
    file.puts "- Added `canon_cut_evidence_write_plan.tsv`."
    file.puts "- Generated #{rows.size} evidence write-plan rows."
    file.puts
    file.puts "Target action summary:"
    file.puts
    file.puts "| Target action | Rows |"
    file.puts "|---|---:|"
    action_counts.sort.each { |action, count| file.puts "| `#{action}` | #{count} |" }
    file.puts
    file.puts "Evidence strength summary:"
    file.puts
    file.puts "| Strength | Rows |"
    file.puts "|---|---:|"
    strength_counts.sort.each { |strength, count| file.puts "| `#{strength}` | #{count} |" }
    file.puts
    file.puts "First planned writes:"
    file.puts
    file.puts "| Write plan ID | Work | Source item | Action | Gate |"
    file.puts "|---|---|---|---|---|"
    rows.first(12).each do |row|
      file.puts "| `#{row.fetch("write_plan_id")}` | `#{row.fetch("work_id")}` | `#{row.fetch("source_item_id")}` | `#{row.fetch("target_action")}` | `#{row.fetch("write_gate")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "This is a staging table. The evidence ledger should be updated only after review acceptance, then source debt and cut-side scoring can be recomputed."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

evidence_by_source_item = read_tsv(EVIDENCE_PATH).group_by { |row| [row.fetch("work_id"), row.fetch("source_item_id")] }
ready_items = read_tsv(CUT_EVIDENCE_ITEM_DECISIONS_PATH).select do |row|
  row.fetch("item_decision") == "ready_for_representative_selection_evidence_review"
end

write_rows = ready_items.map.with_index(1) do |row, index|
  existing = evidence_by_source_item.fetch([row.fetch("cut_work_id"), row.fetch("source_item_id")], []).first
  target_action = existing ? "update_existing_evidence_status_after_review" : "create_new_evidence_after_review"
  proposed_id = existing ? "" : "x057_ev_#{safe_id(row.fetch("source_item_id"))}"

  {
    "write_plan_id" => "x057_cut_evidence_write_#{index.to_s.rjust(4, "0")}",
    "item_decision_id" => row.fetch("item_decision_id"),
    "target_action" => target_action,
    "proposed_evidence_id" => proposed_id,
    "existing_evidence_id" => existing ? existing.fetch("evidence_id") : "",
    "work_id" => row.fetch("cut_work_id"),
    "source_id" => row.fetch("source_id"),
    "source_item_id" => row.fetch("source_item_id"),
    "evidence_type" => "representative_selection",
    "evidence_strength" => evidence_strength_for(row),
    "reviewer_status" => "needs_manual_acceptance",
    "page_or_section" => "source item: #{row.fetch("raw_title")}",
    "packet_id" => "X057",
    "write_gate" => "review_required_before_evidence_table_update",
    "write_rationale" => "X056 item decision marked source item ready for representative-selection evidence review.",
    "next_action" => "accept_or_reject_write_plan_row_before_evidence_ledger_update"
  }
end

write_tsv(CUT_EVIDENCE_WRITE_PLAN_PATH, HEADERS, write_rows)
write_report(REPORT_PATH, write_rows)

puts "wrote #{CUT_EVIDENCE_WRITE_PLAN_PATH.sub(ROOT + "/", "")} (#{write_rows.size} rows)"
write_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("target_action")] += 1 }.sort.each do |action, count|
  puts "#{action}: #{count}"
end
