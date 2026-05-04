#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
OUTPUT_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_047_x063_high_risk_rescue_residue.md")

HEADERS = %w[
  residue_id scope_review_id cut_work_id cut_title cut_creator source_id source_item_id
  raw_title raw_creator source_item_form scope_review_class current_action_status
  current_action_id current_lane residue_status required_resolution
  source_debt_effect next_action
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

def count_by(rows, key)
  rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch(key)] += 1 }
end

def required_resolution(scope_class)
  case scope_class
  when "named_collection_membership_unverified"
    "find_exact_named_collection_membership_or_reject_source_item_for_cut_side_support"
  when "creator_exact_component_form_unverified"
    "verify_component_form_then_decide_representative_selection_or_named_membership_requirement"
  when "creator_exact_form_mismatch"
    "reject_as_wrong_form_for_cut_side_work_unless_separate_source_support_exists"
  else
    "manual_scope_resolution_required"
  end
end

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  status_counts = count_by(rows, "residue_status")
  class_counts = count_by(rows, "scope_review_class")
  current_rows = rows.select { |row| row.fetch("residue_status") == "current_high_risk_scope_blocker" }

  File.open(path, "w") do |file|
    file.puts "# X063 High-Risk Rescue Residue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X063 reconciles the high-risk X061 source-scope rows against the current post-X062 cut-side action queue. This prevents stale high-risk rows from being processed after X062 removed their work rows from the current queue."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_high_risk_rescue_residue_x063.rb`."
    file.puts "- Added `canon_high_risk_rescue_residue.tsv`."
    file.puts "- Reconciled #{rows.size} high-risk X061 rows."
    file.puts "- #{current_rows.size} high-risk rows still map to current existing-source rescue actions."
    file.puts
    file.puts "Residue status summary:"
    file.puts
    file.puts "| Status | Rows |"
    file.puts "|---|---:|"
    status_counts.sort.each { |status, count| file.puts "| `#{status}` | #{count} |" }
    file.puts
    file.puts "Scope class summary:"
    file.puts
    file.puts "| Scope class | Rows |"
    file.puts "|---|---:|"
    class_counts.sort.each { |scope_class, count| file.puts "| `#{scope_class}` | #{count} |" }
    file.puts
    file.puts "Current work-level blockers:"
    file.puts
    file.puts "| Work | High-risk source rows | Required resolution |"
    file.puts "|---|---:|---|"
    current_rows.group_by { |row| row.fetch("cut_work_id") }.sort.each do |work_id, grouped|
      resolutions = grouped.map { |row| row.fetch("required_resolution") }.uniq.join("; ")
      file.puts "| `#{work_id}` | #{grouped.size} | #{resolutions} |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "X063 does not generate evidence. The active high-risk residue still requires exact collection-membership, form, or component-scope verification before any source item can support a cut-side selected work."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

scope_rows = read_tsv(SCOPE_REVIEW_PATH).select { |row| row.fetch("scope_risk") == "high" }
current_actions_by_work_id = read_tsv(ACTION_QUEUE_PATH).to_h { |row| [row.fetch("cut_work_id"), row] }

rows = scope_rows.map.with_index(1) do |scope, index|
  current_action = current_actions_by_work_id[scope.fetch("cut_work_id")]
  current_lane = current_action&.fetch("current_lane").to_s
  current_action_id = current_action&.fetch("action_id").to_s

  residue_status =
    if current_action.nil?
      "stale_after_x062_current_queue_refresh"
    elsif current_lane == "existing_source_item_rescue_review"
      "current_high_risk_scope_blocker"
    else
      "current_queue_non_rescue_lane"
    end

  next_action =
    case residue_status
    when "current_high_risk_scope_blocker"
      "resolve_high_risk_scope_before_evidence_generation"
    when "stale_after_x062_current_queue_refresh"
      "do_not_process_until_work_reappears_in_current_queue"
    else
      "respect_current_action_queue_lane_before_scope_processing"
    end

  {
    "residue_id" => "x063_high_risk_residue_#{index.to_s.rjust(4, "0")}",
    "scope_review_id" => scope.fetch("scope_review_id"),
    "cut_work_id" => scope.fetch("cut_work_id"),
    "cut_title" => scope.fetch("cut_title"),
    "cut_creator" => scope.fetch("cut_creator"),
    "source_id" => scope.fetch("source_id"),
    "source_item_id" => scope.fetch("source_item_id"),
    "raw_title" => scope.fetch("raw_title"),
    "raw_creator" => scope.fetch("raw_creator"),
    "source_item_form" => scope.fetch("source_item_form"),
    "scope_review_class" => scope.fetch("scope_review_class"),
    "current_action_status" => current_action.nil? ? "not_in_current_action_queue" : "present_in_current_action_queue",
    "current_action_id" => current_action_id,
    "current_lane" => current_lane,
    "residue_status" => residue_status,
    "required_resolution" => required_resolution(scope.fetch("scope_review_class")),
    "source_debt_effect" => "does_not_close_source_debt",
    "next_action" => next_action
  }
end

write_tsv(OUTPUT_PATH, HEADERS, rows)
write_report(REPORT_PATH, rows)

puts "generated #{rows.size} high-risk rescue residue rows"
