#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

GENERIC_SELECTION_REVIEW_PATH = File.join(TABLE_DIR, "canon_generic_selection_basis_review.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_043_x059_cut_side_post_x058_action_queue.md")

HEADERS = %w[
  action_id review_id work_order_id cut_work_id cut_title cut_creator cut_rank
  source_debt_status selection_basis_status accepted_inclusion_evidence_count
  accepted_representative_selection_evidence_count needs_followup_representative_selection_evidence_count
  matched_source_item_count represented_source_item_count creator_exact_unmatched_source_item_count
  current_lane lane_priority recommended_action next_action rationale
].freeze

GENERIC_CREATORS = ["", "anonymous", "various", "unknown"].freeze

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
  value.to_s
       .unicode_normalize(:nfkd)
       .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
       .downcase
       .gsub(/[^a-z0-9]+/, " ")
       .strip
       .squeeze(" ")
end

def creator_keys(value)
  normalize(value).split(/\s*;\s*/).map(&:strip).reject { |key| GENERIC_CREATORS.include?(key) }
end

def classify_lane(review, counts)
  return "cut_side_source_debt_closed_review" if !review.fetch("source_debt_status").start_with?("open_")
  return "accepted_selection_only_complete_work_source_needed" if counts.fetch(:accepted_representative_selection).positive?
  return "needs_followup_selection_evidence_review" if counts.fetch(:needs_followup_representative_selection).positive?
  return "matched_source_item_scope_review" if counts.fetch(:represented_source_items).positive? || counts.fetch(:matched_source_items).positive?
  return "existing_source_item_rescue_review" if counts.fetch(:creator_exact_unmatched_source_items).positive?

  "external_source_acquisition"
end

def lane_priority(lane, review, counts)
  base = case lane
         when "cut_side_source_debt_closed_review" then 120.0
         when "accepted_selection_only_complete_work_source_needed" then 105.0
         when "needs_followup_selection_evidence_review" then 100.0
         when "matched_source_item_scope_review" then 90.0
         when "existing_source_item_rescue_review" then 80.0
         else 50.0
         end

  format("%.3f", base + counts.values.sum - (review.fetch("cut_rank").to_i / 10_000.0))
end

def recommended_action(lane)
  case lane
  when "cut_side_source_debt_closed_review"
    "review_cut_score_eligibility_before_pair_promotion"
  when "accepted_selection_only_complete_work_source_needed"
    "find_complete_work_or_independent_inclusion_support_before_cut_scoring"
  when "needs_followup_selection_evidence_review"
    "accept_reject_or_scope_existing_representative_selection_evidence"
  when "matched_source_item_scope_review"
    "review_matched_source_items_for_scope_and_evidence_status"
  when "existing_source_item_rescue_review"
    "review_creator_exact_source_items_for_safe_match_or_scope_rejection"
  else
    "find_author_specific_external_support_or_mark_cut_basis_unresolved"
  end
end

def next_action(lane)
  case lane
  when "cut_side_source_debt_closed_review"
    "compute_or_review_cut_side_score_inputs"
  when "accepted_selection_only_complete_work_source_needed"
    "search_for_complete_work_source_support"
  when "needs_followup_selection_evidence_review"
    "manual_review_existing_selection_evidence_status"
  when "matched_source_item_scope_review"
    "manual_source_item_scope_review"
  when "existing_source_item_rescue_review"
    "route_source_items_to_scope_review_before_evidence_generation"
  else
    "create_source_acquisition_query"
  end
end

def rationale(lane, counts)
  case lane
  when "accepted_selection_only_complete_work_source_needed"
    "Accepted representative-selection evidence exists, but source debt remains open because selection evidence is not complete-work support."
  when "needs_followup_selection_evidence_review"
    "A representative-selection evidence row exists but is still marked needs_followup, so it cannot support cut-side scoring."
  when "matched_source_item_scope_review"
    "Local source items are linked to the cut work, but scope and evidence status still need review."
  when "existing_source_item_rescue_review"
    "Creator-exact unmatched source items exist and may be rescuable after scope review."
  when "cut_side_source_debt_closed_review"
    "Source debt is no longer open; cut-side scoring eligibility still needs explicit review."
  else
    "No local source support was found in the current extracted source-item table."
  end
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  lane_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("current_lane")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X059 Post-X058 Cut-Side Action Queue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X059 creates a current cut-side action queue after X058 applied representative-selection evidence. It does not overwrite the X052-X057 pre-apply staging audit."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_cut_side_post_x058_action_queue.rb`."
    file.puts "- Added `canon_cut_side_post_x058_action_queue.tsv`."
    file.puts "- Generated #{rows.size} current action rows from the post-X058 X051 queue."
    file.puts
    file.puts "Lane summary:"
    file.puts
    file.puts "| Lane | Rows |"
    file.puts "|---|---:|"
    lane_counts.sort.each { |lane, count| file.puts "| `#{lane}` | #{count} |" }
    file.puts
    file.puts "Highest-priority rows:"
    file.puts
    file.puts "| Action ID | Cut title | Creator | Lane | Next action |"
    file.puts "|---|---|---|---|---|"
    rows.first(12).each do |row|
      file.puts "| `#{row.fetch("action_id")}` | #{row.fetch("cut_title")} | #{row.fetch("cut_creator")} | `#{row.fetch("current_lane")}` | `#{row.fetch("next_action")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "The post-X058 current queue is still blocked. Selection evidence can reduce ambiguity, but it does not justify a cut unless complete-work support, cut-side scoring, and replacement gates are resolved."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

review_rows = read_tsv(GENERIC_SELECTION_REVIEW_PATH)
source_items = read_tsv(SOURCE_ITEMS_PATH)
evidence_rows = read_tsv(EVIDENCE_PATH)

source_items_by_work = source_items.group_by { |row| row.fetch("matched_work_id") }
evidence_by_work = evidence_rows.group_by { |row| row.fetch("work_id") }

action_rows = review_rows.map do |review|
  work_id = review.fetch("cut_work_id")
  work_source_items = source_items_by_work.fetch(work_id, [])
  work_evidence = evidence_by_work.fetch(work_id, [])
  cut_creator_keys = creator_keys(review.fetch("cut_creator"))

  creator_exact_unmatched_source_items = source_items.count do |source_item|
    source_item.fetch("match_status") == "unmatched" &&
      cut_creator_keys.include?(normalize(source_item.fetch("raw_creator")))
  end

  counts = {
    accepted_inclusion: work_evidence.count { |row| row.fetch("reviewer_status") == "accepted" && row.fetch("evidence_type") == "inclusion" },
    accepted_representative_selection: work_evidence.count { |row| row.fetch("reviewer_status") == "accepted" && row.fetch("evidence_type") == "representative_selection" },
    needs_followup_representative_selection: work_evidence.count { |row| row.fetch("reviewer_status") == "needs_followup" && row.fetch("evidence_type") == "representative_selection" },
    matched_source_items: work_source_items.size,
    represented_source_items: work_source_items.count { |row| row.fetch("match_status") == "represented_by_selection" },
    creator_exact_unmatched_source_items: creator_exact_unmatched_source_items
  }

  lane = classify_lane(review, counts)

  {
    "review_id" => review.fetch("review_id"),
    "work_order_id" => review.fetch("work_order_id"),
    "cut_work_id" => work_id,
    "cut_title" => review.fetch("cut_title"),
    "cut_creator" => review.fetch("cut_creator"),
    "cut_rank" => review.fetch("cut_rank"),
    "source_debt_status" => review.fetch("source_debt_status"),
    "selection_basis_status" => review.fetch("selection_basis_status"),
    "accepted_inclusion_evidence_count" => counts.fetch(:accepted_inclusion).to_s,
    "accepted_representative_selection_evidence_count" => counts.fetch(:accepted_representative_selection).to_s,
    "needs_followup_representative_selection_evidence_count" => counts.fetch(:needs_followup_representative_selection).to_s,
    "matched_source_item_count" => counts.fetch(:matched_source_items).to_s,
    "represented_source_item_count" => counts.fetch(:represented_source_items).to_s,
    "creator_exact_unmatched_source_item_count" => counts.fetch(:creator_exact_unmatched_source_items).to_s,
    "current_lane" => lane,
    "lane_priority" => lane_priority(lane, review, counts),
    "recommended_action" => recommended_action(lane),
    "next_action" => next_action(lane),
    "rationale" => rationale(lane, counts)
  }
end

action_rows = action_rows
              .sort_by { |row| [-row.fetch("lane_priority").to_f, row.fetch("cut_rank").to_i] }
              .map.with_index(1) do |row, index|
                row.merge("action_id" => "x059_cut_action_#{index.to_s.rjust(4, "0")}")
              end

write_tsv(ACTION_QUEUE_PATH, HEADERS, action_rows)
write_report(REPORT_PATH, action_rows)

puts "wrote #{ACTION_QUEUE_PATH.sub(ROOT + "/", "")} (#{action_rows.size} rows)"
action_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("current_lane")] += 1 }.sort.each do |lane, count|
  puts "#{lane}: #{count}"
end
