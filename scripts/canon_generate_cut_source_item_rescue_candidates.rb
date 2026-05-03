#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

GENERIC_SELECTION_REVIEW_PATH = File.join(TABLE_DIR, "canon_generic_selection_basis_review.tsv")
ALIASES_PATH = File.join(TABLE_DIR, "canon_aliases.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
RESCUE_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_cut_source_item_rescue_candidates.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_036_x052_cut_source_item_rescue_candidates.md")

HEADERS = %w[
  rescue_id review_id work_order_id cut_work_id cut_title cut_creator source_id source_item_id
  raw_title raw_creator match_status matched_work_id evidence_type evidence_weight supports
  rescue_match_rule rescue_confidence recommended_action next_action
].freeze

GENERIC_CREATORS = [
  "",
  "anonymous",
  "various",
  "unknown"
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
  value.to_s
       .unicode_normalize(:nfkd)
       .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
       .downcase
       .gsub(/[^a-z0-9]+/, " ")
       .strip
       .squeeze(" ")
end

def creator_keys(creator)
  normalize(creator).split(/\s*;\s*/).map(&:strip).reject { |key| GENERIC_CREATORS.include?(key) }
end

def title_keys(row, aliases)
  ([row.fetch("cut_title")] + aliases.map { |alias_row| alias_row.fetch("alias") })
    .map { |title| normalize(title) }
    .reject(&:empty?)
    .uniq
end

def match_rule(review, source_item, cut_creator_keys, cut_title_keys)
  raw_title_key = normalize(source_item.fetch("raw_title"))
  raw_creator_key = normalize(source_item.fetch("raw_creator"))
  creator_match = !raw_creator_key.empty? && cut_creator_keys.include?(raw_creator_key)
  title_match = cut_title_keys.include?(raw_title_key)

  return "source_item_already_linked_to_cut" if source_item.fetch("matched_work_id") == review.fetch("cut_work_id")

  if title_match
    return nil if !raw_creator_key.empty? && !creator_match
    return "title_or_alias_exact_unmatched" if source_item.fetch("match_status") == "unmatched"
    return "title_or_alias_exact_different_work" unless source_item.fetch("matched_work_id").empty?
  end

  return nil unless creator_match

  if source_item.fetch("match_status") == "unmatched" && source_item.fetch("evidence_type") == "boundary_context"
    "creator_exact_unmatched_context"
  elsif source_item.fetch("match_status") == "unmatched"
    "creator_exact_unmatched_source_item"
  end
end

def confidence(rule)
  case rule
  when "source_item_already_linked_to_cut"
    "0.95"
  when "title_or_alias_exact_unmatched"
    "0.90"
  when "creator_exact_unmatched_source_item"
    "0.82"
  when "creator_exact_represented_by_selection"
    "0.78"
  when "title_or_alias_exact_different_work"
    "0.70"
  when "creator_exact_unmatched_context"
    "0.55"
  else
    "0.45"
  end
end

def recommended_action(rule)
  case rule
  when "source_item_already_linked_to_cut", "creator_exact_represented_by_selection"
    "review_existing_selection_scope_and_evidence_status"
  when "title_or_alias_exact_unmatched", "creator_exact_unmatched_source_item"
    "review_source_item_for_cut_side_evidence_generation"
  when "creator_exact_unmatched_context"
    "use_context_row_only_to_locate_contained_source_items"
  when "title_or_alias_exact_different_work", "creator_exact_already_matched_elsewhere"
    "review_possible_duplicate_or_misassigned_source_item"
  else
    "manual_rescue_review"
  end
end

def next_action(rule)
  case rule
  when "source_item_already_linked_to_cut", "creator_exact_represented_by_selection"
    "accept_reject_or_scope_existing_selection_evidence"
  when "title_or_alias_exact_unmatched", "creator_exact_unmatched_source_item"
    "route_to_match_review_then_generate_evidence_if_valid"
  when "creator_exact_unmatched_context"
    "inspect_adjacent_source_items_before_evidence_generation"
  else
    "manual_match_scope_review"
  end
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  rule_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("rescue_match_rule")] += 1 }
  work_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[[row.fetch("cut_title"), row.fetch("cut_creator")]] += 1 }
  high_confidence = rows.count { |row| row.fetch("rescue_confidence").to_f >= 0.78 }

  File.open(path, "w") do |file|
    file.puts "# X052 Cut Source-Item Rescue Candidates"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X052 mines the existing extracted source-item table for source rows that can rescue X051 cut-side work orders from an apparent no-source-support state. This is still a review queue; it does not accept evidence or approve cuts."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_cut_source_item_rescue_candidates.rb`."
    file.puts "- Added `canon_cut_source_item_rescue_candidates.tsv`."
    file.puts "- Generated #{rows.size} rescue candidate rows."
    file.puts "- High-confidence rescue rows: #{high_confidence}."
    file.puts
    file.puts "Rescue rule summary:"
    file.puts
    file.puts "| Rule | Rows |"
    file.puts "|---|---:|"
    rule_counts.sort.each { |rule, count| file.puts "| `#{rule}` | #{count} |" }
    file.puts
    file.puts "Work-order coverage:"
    file.puts
    file.puts "| Cut title | Creator | Rescue rows |"
    file.puts "|---|---|---:|"
    work_counts.sort_by { |(_work, count)| -count }.first(12).each do |(title, creator), count|
      file.puts "| #{title} | #{creator} | #{count} |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "The source table already contains some rows that can unblock cut-side evidence review. These rows should be routed through match/scope review first, especially poetry selections where source items are individual poems rather than whole collection titles."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

review_rows = read_tsv(GENERIC_SELECTION_REVIEW_PATH)
aliases_by_work = read_tsv(ALIASES_PATH).group_by { |row| row.fetch("work_id") }
source_items = read_tsv(SOURCE_ITEMS_PATH)

rescue_rows = []

review_rows.each do |review|
  aliases = aliases_by_work.fetch(review.fetch("cut_work_id"), [])
  cut_creator_keys = creator_keys(review.fetch("cut_creator"))
  cut_title_keys = title_keys(review, aliases)

  source_items.each do |source_item|
    rule = match_rule(review, source_item, cut_creator_keys, cut_title_keys)
    next unless rule

    rescue_rows << {
      "review_id" => review.fetch("review_id"),
      "work_order_id" => review.fetch("work_order_id"),
      "cut_work_id" => review.fetch("cut_work_id"),
      "cut_title" => review.fetch("cut_title"),
      "cut_creator" => review.fetch("cut_creator"),
      "source_id" => source_item.fetch("source_id"),
      "source_item_id" => source_item.fetch("source_item_id"),
      "raw_title" => source_item.fetch("raw_title"),
      "raw_creator" => source_item.fetch("raw_creator"),
      "match_status" => source_item.fetch("match_status"),
      "matched_work_id" => source_item.fetch("matched_work_id"),
      "evidence_type" => source_item.fetch("evidence_type"),
      "evidence_weight" => source_item.fetch("evidence_weight"),
      "supports" => source_item.fetch("supports"),
      "rescue_match_rule" => rule,
      "rescue_confidence" => confidence(rule),
      "recommended_action" => recommended_action(rule),
      "next_action" => next_action(rule)
    }
  end
end

rescue_rows = rescue_rows
              .uniq { |row| [row.fetch("cut_work_id"), row.fetch("source_item_id"), row.fetch("rescue_match_rule")] }
              .sort_by do |row|
                [
                  -row.fetch("rescue_confidence").to_f,
                  row.fetch("cut_creator"),
                  row.fetch("source_id"),
                  row.fetch("source_item_id")
                ]
              end
              .map.with_index(1) do |row, index|
                row.merge("rescue_id" => "x052_cut_source_rescue_#{index.to_s.rjust(4, "0")}")
              end

write_tsv(RESCUE_CANDIDATES_PATH, HEADERS, rescue_rows)
write_report(REPORT_PATH, rescue_rows)

puts "wrote #{RESCUE_CANDIDATES_PATH.sub(ROOT + "/", "")} (#{rescue_rows.size} rows)"
rescue_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("rescue_match_rule")] += 1 }.sort.each do |rule, count|
  puts "#{rule}: #{count}"
end
