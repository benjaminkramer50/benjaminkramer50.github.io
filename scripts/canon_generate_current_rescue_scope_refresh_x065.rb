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
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_049_x065_current_rescue_scope_refresh.md")

HEADERS = %w[
  scope_review_id action_id cut_work_id cut_title cut_creator source_id source_item_id
  raw_title raw_creator source_item_form scope_review_class scope_risk evidence_generation_gate
  recommended_action next_action
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

def creator_key(value)
  key = normalize(value)
  GENERIC_CREATORS.include?(key) ? "" : key
end

def source_item_form(row)
  support = row.fetch("supports")
  source_id = row.fetch("source_id")
  return "poem" if support.include?("poem") || source_id.include?("poetry")
  return "story" if source_id.include?("short_stories")

  "unspecified_component"
end

def named_collection_title?(title)
  %w[
    the\ tenth\ muse
    all\ fires\ the\ fire
    blow\ up\ and\ other\ stories
  ].include?(normalize(title))
end

def poetry_selection_title?(title)
  key = normalize(title)
  key.match?(/\A(selected poems|collected poems|poems|collected poems 1948 1984)\z/) ||
    key.include?("selected poems") ||
    key.include?("collected poems")
end

def story_selection_title?(title)
  normalize(title).match?(/\Aselected stories\z/)
end

def scope_class(action, source_item_form)
  title = action.fetch("cut_title")
  raw_title_match = normalize(title) == normalize(action.fetch("raw_title").to_s)

  return "exact_named_collection_support_review" if named_collection_title?(title) && raw_title_match
  return "named_collection_membership_unverified" if named_collection_title?(title)
  return "representative_poetry_selection_review" if poetry_selection_title?(title) && source_item_form == "poem"
  return "representative_story_selection_review" if story_selection_title?(title) && source_item_form == "story"
  return "creator_exact_form_mismatch" if poetry_selection_title?(title) && source_item_form == "story"
  return "creator_exact_form_mismatch" if story_selection_title?(title) && source_item_form == "poem"
  return "creator_exact_component_form_unverified" if poetry_selection_title?(title) || story_selection_title?(title)

  "creator_exact_scope_review"
end

def scope_risk(scope_class)
  case scope_class
  when "representative_poetry_selection_review", "representative_story_selection_review"
    "medium"
  else
    "high"
  end
end

def evidence_generation_gate(scope_class)
  case scope_class
  when "representative_poetry_selection_review", "representative_story_selection_review"
    "manual_scope_acceptance_required_before_representative_selection_evidence"
  when "exact_named_collection_support_review"
    "manual_exact_collection_confirmation_required"
  else
    "do_not_generate_evidence_without_exact_collection_or_form_support"
  end
end

def recommended_action(scope_class)
  case scope_class
  when "representative_poetry_selection_review"
    "review_as_representative_poetry_selection_not_complete_collection_support"
  when "representative_story_selection_review"
    "review_as_representative_story_selection_not_complete_collection_support"
  when "named_collection_membership_unverified"
    "verify_source_item_membership_in_named_collection_before_evidence"
  when "creator_exact_form_mismatch"
    "reject_or_hold_as_form_mismatch_for_cut_side_work"
  when "creator_exact_component_form_unverified"
    "verify_component_form_before_evidence_generation"
  else
    "manual_scope_review_before_evidence_generation"
  end
end

def next_action(scope_class)
  case scope_class
  when "representative_poetry_selection_review", "representative_story_selection_review"
    "manual_scope_review_then_possible_representative_selection_evidence"
  when "named_collection_membership_unverified", "exact_named_collection_support_review"
    "find_named_collection_membership_source"
  else
    "manual_scope_review_or_external_source_acquisition"
  end
end

def count_by(rows, key)
  rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch(key)] += 1 }
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  class_counts = count_by(rows, "scope_review_class")
  risk_counts = count_by(rows, "scope_risk")
  work_counts = count_by(rows, "cut_work_id")

  File.open(path, "w") do |file|
    file.puts "# X065 Current Rescue Scope Refresh"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X065 refreshes the current existing-source rescue scope review after X064 removed Dunbar from the cut-side queue and surfaced Odi Gonzales as a local source-item rescue row."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_current_rescue_scope_refresh_x065.rb`."
    file.puts "- Refreshed `canon_current_rescue_scope_review.tsv`."
    file.puts "- Classified #{rows.size} current source-item rescue rows across #{work_counts.size} cut-side works."
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
    file.puts "Current work-level source-row counts:"
    file.puts
    file.puts "| Work | Source rows |"
    file.puts "|---|---:|"
    rows.group_by { |row| row.fetch("cut_work_id") }.sort.each do |work_id, grouped|
      file.puts "| `#{work_id}` | #{grouped.size} |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "The current rescue lane is smaller than the X061 snapshot. Only one medium-risk row, Odi Gonzales's poem `Umantuu`, can move toward representative-selection evidence; the remaining rows still need collection-membership or component-form resolution."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

action_rows = read_tsv(ACTION_QUEUE_PATH).select do |row|
  row.fetch("current_lane") == "existing_source_item_rescue_review"
end
source_items = read_tsv(SOURCE_ITEMS_PATH)

scope_rows = []

action_rows.each do |action|
  cut_creator_key = creator_key(action.fetch("cut_creator"))
  source_items.each do |source_item|
    next unless source_item.fetch("match_status") == "unmatched"
    next unless creator_key(source_item.fetch("raw_creator")) == cut_creator_key

    form = source_item_form(source_item)
    row_for_class = action.merge("raw_title" => source_item.fetch("raw_title"))
    klass = scope_class(row_for_class, form)

    scope_rows << {
      "action_id" => action.fetch("action_id"),
      "cut_work_id" => action.fetch("cut_work_id"),
      "cut_title" => action.fetch("cut_title"),
      "cut_creator" => action.fetch("cut_creator"),
      "source_id" => source_item.fetch("source_id"),
      "source_item_id" => source_item.fetch("source_item_id"),
      "raw_title" => source_item.fetch("raw_title"),
      "raw_creator" => source_item.fetch("raw_creator"),
      "source_item_form" => form,
      "scope_review_class" => klass,
      "scope_risk" => scope_risk(klass),
      "evidence_generation_gate" => evidence_generation_gate(klass),
      "recommended_action" => recommended_action(klass),
      "next_action" => next_action(klass)
    }
  end
end

scope_rows = scope_rows.map.with_index(1) do |row, index|
  row.merge("scope_review_id" => "x065_current_scope_#{index.to_s.rjust(4, "0")}")
end

write_tsv(SCOPE_REVIEW_PATH, HEADERS, scope_rows)
write_report(REPORT_PATH, scope_rows)

puts "wrote #{SCOPE_REVIEW_PATH.sub(ROOT + "/", "")} (#{scope_rows.size} rows)"
count_by(scope_rows, "scope_review_class").sort.each do |klass, count|
  puts "#{klass}: #{count}"
end
