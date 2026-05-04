#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
CUT_EVIDENCE_WRITE_PLAN_PATH = File.join(TABLE_DIR, "canon_cut_evidence_write_plan.tsv")
CUT_EVIDENCE_APPLIED_ROWS_PATH = File.join(TABLE_DIR, "canon_cut_evidence_applied_rows.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_042_x058_cut_evidence_apply.md")

APPLIED_HEADERS = %w[
  applied_id write_plan_id evidence_id work_id source_id source_item_id evidence_action
  source_item_action evidence_type evidence_strength reviewer_status next_action
].freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def tsv_headers(path)
  CSV.open(path, col_sep: "\t", &:readline)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def append_note(existing, note)
  return existing if existing.to_s.include?(note)
  return note if existing.to_s.empty?

  "#{existing} #{note}"
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  action_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("evidence_action")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X058 Cut Evidence Apply"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X058 applies the review-gated X057 write plan to `canon_evidence.tsv` as accepted representative-selection evidence and links the relevant source items to their cut-side work candidates. Representative-selection evidence does not close complete-work source debt under the current source-debt rules."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_apply_cut_evidence_write_plan.rb`."
    file.puts "- Added `canon_cut_evidence_applied_rows.tsv`."
    file.puts "- Confirmed #{rows.size} evidence rows present after apply."
    file.puts
    file.puts "Evidence action summary:"
    file.puts
    file.puts "| Action | Rows |"
    file.puts "|---|---:|"
    action_counts.sort.each { |action, count| file.puts "| `#{action}` | #{count} |" }
    file.puts
    file.puts "Applied evidence rows:"
    file.puts
    file.puts "| Applied ID | Work | Source item | Evidence ID |"
    file.puts "|---|---|---|---|"
    rows.first(16).each do |row|
      file.puts "| `#{row.fetch("applied_id")}` | `#{row.fetch("work_id")}` | `#{row.fetch("source_item_id")}` | `#{row.fetch("evidence_id")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "This improves cut-side evidence accounting but still does not approve any cut or replacement. Source debt remains selection-only unless complete-work or independently closing inclusion evidence is added."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

works_by_id = read_tsv(WORK_CANDIDATES_PATH).to_h { |row| [row.fetch("work_id"), row] }
source_items = read_tsv(SOURCE_ITEMS_PATH)
source_items_by_id = source_items.to_h { |row| [row.fetch("source_item_id"), row] }
evidence_rows = read_tsv(EVIDENCE_PATH)
evidence_by_work_item = evidence_rows.to_h { |row| [[row.fetch("work_id"), row.fetch("source_item_id")], row] }
evidence_ids = evidence_rows.map { |row| row.fetch("evidence_id") }.to_h { |id| [id, true] }
write_plan_rows = read_tsv(CUT_EVIDENCE_WRITE_PLAN_PATH)

applied_rows = []

write_plan_rows.each do |plan|
  next unless plan.fetch("target_action") == "create_new_evidence_after_review"
  next unless plan.fetch("write_gate") == "review_required_before_evidence_table_update"

  work_id = plan.fetch("work_id")
  source_item_id = plan.fetch("source_item_id")
  source_item = source_items_by_id.fetch(source_item_id)
  work = works_by_id.fetch(work_id)

  existing_match = source_item.fetch("matched_work_id").to_s
  unless existing_match.empty? || existing_match == work_id
    raise "Refusing to reassign #{source_item_id} from #{existing_match} to #{work_id}"
  end

  source_item["matched_work_id"] = work_id
  source_item["match_method"] = "x058_cut_evidence_write_plan_representative_selection"
  source_item["match_confidence"] = "0.90"
  source_item["match_status"] = "represented_by_selection"
  source_item["notes"] = append_note(source_item["notes"], "X058 linked for reviewed representative-selection evidence; not complete-work support.")

  existing_evidence = evidence_by_work_item[[work_id, source_item_id]]
  evidence_id = existing_evidence ? existing_evidence.fetch("evidence_id") : plan.fetch("proposed_evidence_id")
  raise "Evidence ID collision: #{evidence_id}" if !existing_evidence && evidence_ids[evidence_id]

  unless existing_evidence
    evidence_rows << {
      "evidence_id" => evidence_id,
      "work_id" => work_id,
      "source_id" => plan.fetch("source_id"),
      "source_item_id" => source_item_id,
      "evidence_type" => plan.fetch("evidence_type"),
      "evidence_strength" => plan.fetch("evidence_strength"),
      "page_or_section" => plan.fetch("page_or_section"),
      "quote_or_note" => "",
      "packet_id" => "X058",
      "supports_tier" => "",
      "supports_boundary_policy_id" => work.fetch("boundary_policy_id"),
      "reviewer_status" => "accepted",
      "notes" => "Applied from X057 write plan after X056 item-level scope review. Representative-selection evidence only; does not establish complete-work support or approve cuts."
    }
    evidence_ids[evidence_id] = true
    evidence_by_work_item[[work_id, source_item_id]] = evidence_rows.last
  end

  applied_rows << {
    "write_plan_id" => plan.fetch("write_plan_id"),
    "evidence_id" => evidence_id,
    "work_id" => work_id,
    "source_id" => plan.fetch("source_id"),
    "source_item_id" => source_item_id,
    "evidence_action" => "evidence_present_after_apply",
    "source_item_action" => "represented_by_selection_after_apply",
    "evidence_type" => plan.fetch("evidence_type"),
    "evidence_strength" => plan.fetch("evidence_strength"),
    "reviewer_status" => "accepted",
    "next_action" => "regenerate_source_debt_scoring_and_cut_review_tables"
  }
end

applied_rows = applied_rows.map.with_index(1) do |row, index|
  row.merge("applied_id" => "x058_cut_evidence_apply_#{index.to_s.rjust(4, "0")}")
end

write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_items)
write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_rows)
write_tsv(CUT_EVIDENCE_APPLIED_ROWS_PATH, APPLIED_HEADERS, applied_rows)
write_report(REPORT_PATH, applied_rows)

puts "applied or confirmed #{applied_rows.size} evidence rows"
