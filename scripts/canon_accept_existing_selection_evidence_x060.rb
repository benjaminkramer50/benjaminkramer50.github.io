#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
REVIEWS_PATH = File.join(TABLE_DIR, "canon_existing_selection_evidence_reviews.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_044_x060_existing_selection_evidence_review.md")

HEADERS = %w[
  review_id action_id evidence_id work_id source_id source_item_id raw_title raw_creator
  previous_reviewer_status new_reviewer_status evidence_scope_decision source_debt_effect
  next_action
].freeze

NOTE = "X060 accepted as representative-selection evidence only; not complete-work support or cut approval."

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
  status_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("new_reviewer_status")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X060 Existing Selection Evidence Review"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X060 reviews the X059 needs-followup representative-selection evidence rows. It may accept selection evidence, but it cannot close complete-work source debt or approve cuts."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_accept_existing_selection_evidence_x060.rb`."
    file.puts "- Added `canon_existing_selection_evidence_reviews.tsv`."
    file.puts "- Reviewed #{rows.size} existing selection-evidence rows."
    file.puts
    file.puts "Reviewer-status summary:"
    file.puts
    file.puts "| Status | Rows |"
    file.puts "|---|---:|"
    status_counts.sort.each { |status, count| file.puts "| `#{status}` | #{count} |" }
    file.puts
    file.puts "Reviewed rows:"
    file.puts
    file.puts "| Review ID | Work | Source item | Decision |"
    file.puts "|---|---|---|---|"
    rows.each do |row|
      file.puts "| `#{row.fetch("review_id")}` | `#{row.fetch("work_id")}` | #{row.fetch("raw_title")} | `#{row.fetch("evidence_scope_decision")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "These rows now count as accepted representative-selection evidence only. The selected-work cut side remains blocked until complete-work support, selection-basis review, and scoring gates are resolved."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

action_rows = read_tsv(ACTION_QUEUE_PATH).select do |row|
  row.fetch("current_lane") == "needs_followup_selection_evidence_review"
end
raise "Expected needs_followup selection-evidence rows" if action_rows.empty?

source_items_by_id = read_tsv(SOURCE_ITEMS_PATH).to_h { |row| [row.fetch("source_item_id"), row] }
evidence_rows = read_tsv(EVIDENCE_PATH)
evidence_by_work = evidence_rows.group_by { |row| row.fetch("work_id") }

review_rows = []

action_rows.each do |action|
  work_id = action.fetch("cut_work_id")
  source_item = source_items_by_id.values.find do |candidate|
    candidate.fetch("matched_work_id") == work_id &&
      candidate.fetch("match_status") == "represented_by_selection" &&
      candidate.fetch("evidence_type") == "representative_selection"
  end
  raise "No represented source item for #{work_id}" unless source_item

  evidence = evidence_by_work.fetch(work_id, []).find do |candidate|
    candidate.fetch("source_item_id") == source_item.fetch("source_item_id") &&
      candidate.fetch("evidence_type") == "representative_selection"
  end
  raise "No representative-selection evidence for #{work_id}" unless evidence
  raise "Unexpected evidence status for #{evidence.fetch("evidence_id")}" unless evidence.fetch("reviewer_status") == "needs_followup"

  previous_status = evidence.fetch("reviewer_status")
  evidence["reviewer_status"] = "accepted"
  evidence["notes"] = append_note(evidence["notes"], NOTE)
  source_item["notes"] = append_note(source_item["notes"], NOTE)

  review_rows << {
    "action_id" => action.fetch("action_id"),
    "evidence_id" => evidence.fetch("evidence_id"),
    "work_id" => work_id,
    "source_id" => evidence.fetch("source_id"),
    "source_item_id" => source_item.fetch("source_item_id"),
    "raw_title" => source_item.fetch("raw_title"),
    "raw_creator" => source_item.fetch("raw_creator"),
    "previous_reviewer_status" => previous_status,
    "new_reviewer_status" => evidence.fetch("reviewer_status"),
    "evidence_scope_decision" => "accepted_representative_selection_only",
    "source_debt_effect" => "does_not_close_complete_work_source_debt",
    "next_action" => "refresh_source_debt_scoring_and_current_cut_side_action_queue"
  }
end

review_rows = review_rows.map.with_index(1) do |row, index|
  row.merge("review_id" => "x060_selection_evidence_review_#{index.to_s.rjust(4, "0")}")
end

write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_rows)
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_items_by_id.values)
write_tsv(REVIEWS_PATH, HEADERS, review_rows)
write_report(REPORT_PATH, review_rows)

puts "accepted #{review_rows.size} existing representative-selection evidence rows"
