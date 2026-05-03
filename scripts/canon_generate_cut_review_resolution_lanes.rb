#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

GENERIC_SELECTION_REVIEW_PATH = File.join(TABLE_DIR, "canon_generic_selection_basis_review.tsv")
CUT_SOURCE_ITEM_RESCUE_PATH = File.join(TABLE_DIR, "canon_cut_source_item_rescue_candidates.tsv")
CUT_REVIEW_RESOLUTION_LANES_PATH = File.join(TABLE_DIR, "canon_cut_review_resolution_lanes.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_037_x053_cut_review_resolution_lanes.md")

HEADERS = %w[
  resolution_id review_id work_order_id cut_work_id cut_title cut_creator cut_rank
  selection_basis_status rescue_candidate_count rescue_source_ids rescue_source_item_ids
  rescue_match_rules resolution_lane lane_priority recommended_action external_search_query
  next_action
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

def resolution_lane(review, rescue_rows)
  return "existing_source_item_rescue_review" if rescue_rows.any?
  return "external_source_acquisition" if review.fetch("selection_basis_status").include?("unresolved")

  "manual_selection_scope_review"
end

def recommended_action(lane, review)
  case lane
  when "existing_source_item_rescue_review"
    "review_rescue_source_items_for_match_scope_and_cut_side_evidence"
  when "external_source_acquisition"
    if review.fetch("selection_basis_status").start_with?("generic_title")
      "find_author_specific_external_support_for_selected_work_or_mark_cut_basis_unresolved"
    else
      "find_external_support_for_named_work_before_cut_decision"
    end
  else
    "manual_review_selection_basis_before_pair_promotion"
  end
end

def next_action(lane)
  case lane
  when "existing_source_item_rescue_review"
    "process_rescue_rows_before_external_search"
  when "external_source_acquisition"
    "create_source_acquisition_queries_and_register_verified_sources"
  else
    "manual_selection_scope_review"
  end
end

def lane_priority(lane, rescue_rows, rank)
  base = case lane
         when "existing_source_item_rescue_review" then 100.0
         when "manual_selection_scope_review" then 70.0
         else 50.0
         end
  format("%.3f", base + rescue_rows.size - (rank.to_i / 10_000.0))
end

def external_search_query(review)
  title = review.fetch("cut_title")
  creator = review.fetch("cut_creator")
  if review.fetch("selection_basis_status").start_with?("generic_title")
    %("#{creator}" "#{title}" anthology literature canon)
  else
    %("#{creator}" "#{title}" literature canon source)
  end
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  lane_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("resolution_lane")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X053 Cut Review Resolution Lanes"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X053 splits the 50 X051 cut-side rows into actionable lanes: process existing source-item rescue rows first, then run external source acquisition for rows with no local support."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_cut_review_resolution_lanes.rb`."
    file.puts "- Added `canon_cut_review_resolution_lanes.tsv`."
    file.puts "- Generated #{rows.size} resolution-lane rows."
    file.puts
    file.puts "Resolution lane summary:"
    file.puts
    file.puts "| Lane | Rows |"
    file.puts "|---|---:|"
    lane_counts.sort.each { |lane, count| file.puts "| `#{lane}` | #{count} |" }
    file.puts
    file.puts "Top existing-source rescue rows:"
    file.puts
    file.puts "| Resolution ID | Cut title | Creator | Rescue rows | Next action |"
    file.puts "|---|---|---|---:|---|"
    rows.select { |row| row.fetch("resolution_lane") == "existing_source_item_rescue_review" }.first(12).each do |row|
      file.puts "| `#{row.fetch("resolution_id")}` | #{row.fetch("cut_title")} | #{row.fetch("cut_creator")} | #{row.fetch("rescue_candidate_count")} | `#{row.fetch("next_action")}` |"
    end
    file.puts
    file.puts "Top external-source acquisition rows:"
    file.puts
    file.puts "| Resolution ID | Cut title | Creator | Query |"
    file.puts "|---|---|---|---|"
    rows.select { |row| row.fetch("resolution_lane") == "external_source_acquisition" }.first(8).each do |row|
      file.puts "| `#{row.fetch("resolution_id")}` | #{row.fetch("cut_title")} | #{row.fetch("cut_creator")} | `#{row.fetch("external_search_query")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "This packet does not approve cuts. It prevents the next work from branching randomly: first review source items already in the build layer, then source the genuinely unsupported rows."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

review_rows = read_tsv(GENERIC_SELECTION_REVIEW_PATH)
rescue_by_review = read_tsv(CUT_SOURCE_ITEM_RESCUE_PATH).group_by { |row| row.fetch("review_id") }

lane_rows = review_rows.map do |review|
  rescue_rows = rescue_by_review.fetch(review.fetch("review_id"), [])
  lane = resolution_lane(review, rescue_rows)

  {
    "review_id" => review.fetch("review_id"),
    "work_order_id" => review.fetch("work_order_id"),
    "cut_work_id" => review.fetch("cut_work_id"),
    "cut_title" => review.fetch("cut_title"),
    "cut_creator" => review.fetch("cut_creator"),
    "cut_rank" => review.fetch("cut_rank"),
    "selection_basis_status" => review.fetch("selection_basis_status"),
    "rescue_candidate_count" => rescue_rows.size.to_s,
    "rescue_source_ids" => rescue_rows.map { |row| row.fetch("source_id") }.uniq.join(";"),
    "rescue_source_item_ids" => rescue_rows.map { |row| row.fetch("source_item_id") }.join(";"),
    "rescue_match_rules" => rescue_rows.map { |row| row.fetch("rescue_match_rule") }.uniq.sort.join(";"),
    "resolution_lane" => lane,
    "lane_priority" => lane_priority(lane, rescue_rows, review.fetch("cut_rank")),
    "recommended_action" => recommended_action(lane, review),
    "external_search_query" => lane == "external_source_acquisition" ? external_search_query(review) : "",
    "next_action" => next_action(lane)
  }
end

lane_rows = lane_rows
            .sort_by { |row| [-row.fetch("lane_priority").to_f, row.fetch("cut_rank").to_i] }
            .map.with_index(1) do |row, index|
              row.merge("resolution_id" => "x053_cut_resolution_#{index.to_s.rjust(4, "0")}")
            end

write_tsv(CUT_REVIEW_RESOLUTION_LANES_PATH, HEADERS, lane_rows)
write_report(REPORT_PATH, lane_rows)

puts "wrote #{CUT_REVIEW_RESOLUTION_LANES_PATH.sub(ROOT + "/", "")} (#{lane_rows.size} rows)"
lane_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("resolution_lane")] += 1 }.sort.each do |lane, count|
  puts "#{lane}: #{count}"
end
