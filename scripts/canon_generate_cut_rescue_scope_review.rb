#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

CUT_SOURCE_ITEM_RESCUE_PATH = File.join(TABLE_DIR, "canon_cut_source_item_rescue_candidates.tsv")
CUT_RESCUE_SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_cut_rescue_scope_review.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_038_x054_cut_rescue_scope_review.md")

HEADERS = %w[
  scope_review_id rescue_id review_id work_order_id cut_work_id cut_title cut_creator
  source_id source_item_id raw_title raw_creator evidence_type supports rescue_match_rule
  scope_review_class scope_risk evidence_generation_gate recommended_action next_action
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

def poetry_collection_title?(title)
  normalize(title).match?(/\A(selected poems|collected poems|poems|the weary blues and selected poems|lyrics of lowly life)\z/) ||
    normalize(title).include?("collected poems")
end

def story_collection_title?(title)
  normalize(title).match?(/\A(selected stories|all fires the fire|blow up and other stories)\z/)
end

def scope_review_class(row)
  title = normalize(row.fetch("cut_title"))
  raw_title = normalize(row.fetch("raw_title"))

  return "existing_linked_selection_evidence_review" if row.fetch("rescue_match_rule") == "source_item_already_linked_to_cut"

  if title == "odes"
    return "title_family_match_ode_source_item" if raw_title.match?(/\bode|odes\b/)

    return "creator_only_form_mismatch"
  end

  return "representative_poetry_selection_review" if poetry_collection_title?(row.fetch("cut_title"))
  return "story_collection_membership_review" if story_collection_title?(row.fetch("cut_title"))
  return "named_collection_membership_review" if title == "the tenth muse"

  "creator_only_scope_review"
end

def scope_risk(scope_class)
  case scope_class
  when "existing_linked_selection_evidence_review", "title_family_match_ode_source_item"
    "medium"
  when "representative_poetry_selection_review"
    "medium"
  else
    "high"
  end
end

def evidence_generation_gate(scope_class)
  case scope_class
  when "existing_linked_selection_evidence_review"
    "review_existing_provisional_evidence_before_acceptance"
  when "title_family_match_ode_source_item", "representative_poetry_selection_review"
    "manual_scope_acceptance_required_before_evidence_generation"
  when "creator_only_form_mismatch"
    "do_not_generate_evidence_without_work_level_match"
  else
    "verify_collection_membership_before_evidence_generation"
  end
end

def recommended_action(scope_class)
  case scope_class
  when "existing_linked_selection_evidence_review"
    "review_existing_representative_selection_evidence_status"
  when "title_family_match_ode_source_item"
    "route_ode_family_source_item_to_scope_review"
  when "representative_poetry_selection_review"
    "review_as_representative_selection_not_whole_collection_support"
  when "creator_only_form_mismatch"
    "reject_as_cut_side_evidence_unless_source_item_matches_work_scope"
  when "story_collection_membership_review", "named_collection_membership_review"
    "verify_source_item_is_in_named_collection_before_evidence"
  else
    "manual_scope_review"
  end
end

def next_action(scope_class)
  case scope_class
  when "creator_only_form_mismatch"
    "mark_rescue_row_scope_blocked_or_find_better_source_item"
  when "story_collection_membership_review", "named_collection_membership_review"
    "check_collection_membership_source_before_match_update"
  else
    "review_scope_then_update_match_or_evidence_tables"
  end
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  class_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("scope_review_class")] += 1 }
  risk_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("scope_risk")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X054 Cut Rescue Scope Review"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X054 reviews the X052 rescue rows for scope risk. A creator-exact source item is not automatically evidence for a selected collection, named collection, or generic title."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_cut_rescue_scope_review.rb`."
    file.puts "- Added `canon_cut_rescue_scope_review.tsv`."
    file.puts "- Generated #{rows.size} scope-review rows."
    file.puts
    file.puts "Scope class summary:"
    file.puts
    file.puts "| Scope class | Rows |"
    file.puts "|---|---:|"
    class_counts.sort.each { |klass, count| file.puts "| `#{klass}` | #{count} |" }
    file.puts
    file.puts "Scope risk summary:"
    file.puts
    file.puts "| Risk | Rows |"
    file.puts "|---|---:|"
    risk_counts.sort.each { |risk, count| file.puts "| `#{risk}` | #{count} |" }
    file.puts
    file.puts "High-risk rows needing membership or form review:"
    file.puts
    file.puts "| Scope review ID | Cut title | Creator | Raw title | Class |"
    file.puts "|---|---|---|---|---|"
    rows.select { |row| row.fetch("scope_risk") == "high" }.first(12).each do |row|
      file.puts "| `#{row.fetch("scope_review_id")}` | #{row.fetch("cut_title")} | #{row.fetch("cut_creator")} | #{row.fetch("raw_title")} | `#{row.fetch("scope_review_class")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "This packet keeps the rescue lane conservative: source items may support representative selection evidence, but collection membership and form mismatches must be resolved before any cut-side score changes."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

scope_rows = read_tsv(CUT_SOURCE_ITEM_RESCUE_PATH).map.with_index(1) do |row, index|
  klass = scope_review_class(row)
  {
    "scope_review_id" => "x054_cut_scope_#{index.to_s.rjust(4, "0")}",
    "rescue_id" => row.fetch("rescue_id"),
    "review_id" => row.fetch("review_id"),
    "work_order_id" => row.fetch("work_order_id"),
    "cut_work_id" => row.fetch("cut_work_id"),
    "cut_title" => row.fetch("cut_title"),
    "cut_creator" => row.fetch("cut_creator"),
    "source_id" => row.fetch("source_id"),
    "source_item_id" => row.fetch("source_item_id"),
    "raw_title" => row.fetch("raw_title"),
    "raw_creator" => row.fetch("raw_creator"),
    "evidence_type" => row.fetch("evidence_type"),
    "supports" => row.fetch("supports"),
    "rescue_match_rule" => row.fetch("rescue_match_rule"),
    "scope_review_class" => klass,
    "scope_risk" => scope_risk(klass),
    "evidence_generation_gate" => evidence_generation_gate(klass),
    "recommended_action" => recommended_action(klass),
    "next_action" => next_action(klass)
  }
end

write_tsv(CUT_RESCUE_SCOPE_REVIEW_PATH, HEADERS, scope_rows)
write_report(REPORT_PATH, scope_rows)

puts "wrote #{CUT_RESCUE_SCOPE_REVIEW_PATH.sub(ROOT + "/", "")} (#{scope_rows.size} rows)"
scope_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("scope_review_class")] += 1 }.sort.each do |klass, count|
  puts "#{klass}: #{count}"
end
