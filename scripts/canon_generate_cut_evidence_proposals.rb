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
REPORT_PATH = File.join(REPORT_DIR, "x_batch_039_x055_cut_evidence_proposals.md")

HEADERS = %w[
  proposal_id cut_work_id cut_title cut_creator source_id scope_review_class
  scope_review_ids source_item_ids source_item_count raw_title_examples proposed_evidence_type
  proposed_evidence_strength proposal_gate reviewer_status recommended_action next_action
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

def proposed_evidence_type(scope_class)
  case scope_class
  when "existing_linked_selection_evidence_review", "representative_poetry_selection_review", "title_family_match_ode_source_item"
    "representative_selection"
  else
    "scope_review_required"
  end
end

def proposed_evidence_strength(rows)
  source_ids = rows.map { |row| row.fetch("source_id") }.uniq
  return "moderate" if rows.size >= 2 || source_ids.size >= 2

  "weak"
end

def proposal_gate(scope_class)
  case scope_class
  when "existing_linked_selection_evidence_review"
    "review_existing_evidence_before_acceptance"
  else
    "manual_scope_acceptance_required"
  end
end

def recommended_action(scope_class)
  case scope_class
  when "existing_linked_selection_evidence_review"
    "update_existing_evidence_status_if_scope_is_accepted"
  else
    "generate_cut_side_representative_selection_evidence_if_scope_is_accepted"
  end
end

def write_report(path, rows, skipped_high_risk_count)
  FileUtils.mkdir_p(File.dirname(path))
  class_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("scope_review_class")] += 1 }

  File.open(path, "w") do |file|
    file.puts "# X055 Cut Evidence Proposals"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X055 groups only medium-risk X054 rescue rows into evidence proposals. It does not accept evidence; it identifies the rows that can move next after manual scope acceptance."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_cut_evidence_proposals.rb`."
    file.puts "- Added `canon_cut_evidence_proposals.tsv`."
    file.puts "- Generated #{rows.size} grouped evidence proposal rows."
    file.puts "- High-risk X054 rows skipped: #{skipped_high_risk_count}."
    file.puts
    file.puts "Proposal class summary:"
    file.puts
    file.puts "| Scope class | Proposals |"
    file.puts "|---|---:|"
    class_counts.sort.each { |klass, count| file.puts "| `#{klass}` | #{count} |" }
    file.puts
    file.puts "Top proposals:"
    file.puts
    file.puts "| Proposal ID | Cut title | Creator | Source | Items | Gate |"
    file.puts "|---|---|---|---|---:|---|"
    rows.first(12).each do |row|
      file.puts "| `#{row.fetch("proposal_id")}` | #{row.fetch("cut_title")} | #{row.fetch("cut_creator")} | `#{row.fetch("source_id")}` | #{row.fetch("source_item_count")} | `#{row.fetch("proposal_gate")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "These proposals are not accepted evidence. They are the next safe review set: medium-risk source rows that may become cut-side representative-selection evidence without touching high-risk collection-membership or form-mismatch cases."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

scope_rows = read_tsv(CUT_RESCUE_SCOPE_REVIEW_PATH)
eligible_rows = scope_rows.select { |row| row.fetch("scope_risk") == "medium" }
skipped_high_risk_count = scope_rows.size - eligible_rows.size

proposal_rows = eligible_rows
                .group_by { |row| [row.fetch("cut_work_id"), row.fetch("source_id"), row.fetch("scope_review_class")] }
                .map do |(_work_id, _source_id, scope_class), rows|
                  first = rows.first
                  {
                    "cut_work_id" => first.fetch("cut_work_id"),
                    "cut_title" => first.fetch("cut_title"),
                    "cut_creator" => first.fetch("cut_creator"),
                    "source_id" => first.fetch("source_id"),
                    "scope_review_class" => scope_class,
                    "scope_review_ids" => rows.map { |row| row.fetch("scope_review_id") }.join(";"),
                    "source_item_ids" => rows.map { |row| row.fetch("source_item_id") }.join(";"),
                    "source_item_count" => rows.size.to_s,
                    "raw_title_examples" => rows.first(3).map { |row| row.fetch("raw_title") }.join(";"),
                    "proposed_evidence_type" => proposed_evidence_type(scope_class),
                    "proposed_evidence_strength" => proposed_evidence_strength(rows),
                    "proposal_gate" => proposal_gate(scope_class),
                    "reviewer_status" => "needs_manual_scope_review",
                    "recommended_action" => recommended_action(scope_class),
                    "next_action" => "manual_scope_review_before_evidence_table_update"
                  }
                end
                .sort_by { |row| [-row.fetch("source_item_count").to_i, row.fetch("cut_creator"), row.fetch("source_id")] }
                .map.with_index(1) do |row, index|
                  row.merge("proposal_id" => "x055_cut_evidence_#{index.to_s.rjust(4, "0")}")
                end

write_tsv(CUT_EVIDENCE_PROPOSALS_PATH, HEADERS, proposal_rows)
write_report(REPORT_PATH, proposal_rows, skipped_high_risk_count)

puts "wrote #{CUT_EVIDENCE_PROPOSALS_PATH.sub(ROOT + "/", "")} (#{proposal_rows.size} rows)"
proposal_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("scope_review_class")] += 1 }.sort.each do |klass, count|
  puts "#{klass}: #{count}"
end
