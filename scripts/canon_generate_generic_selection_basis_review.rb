#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

CUT_REVIEW_WORK_ORDERS_PATH = File.join(TABLE_DIR, "canon_cut_review_work_orders.tsv")
WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
ALIASES_PATH = File.join(TABLE_DIR, "canon_aliases.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_STATUS_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
GENERIC_SELECTION_REVIEW_PATH = File.join(TABLE_DIR, "canon_generic_selection_basis_review.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_035_x051_generic_selection_basis_review.md")

HEADERS = %w[
  review_id work_order_id cut_work_id cut_title cut_creator cut_rank selection_basis
  completion_unit source_debt_status evidence_count accepted_evidence_refs provisional_evidence_refs
  alias_count alias_examples source_item_match_count source_item_match_statuses duplicate_cluster_key
  duplicate_cluster_size generic_title_flag selection_basis_status recommended_resolution next_action
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

def write_report(path, rows)
  FileUtils.mkdir_p(File.dirname(path))

  status_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("selection_basis_status")] += 1 }
  resolution_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("recommended_resolution")] += 1 }
  unsupported_generic_rows = rows.count do |row|
    row.fetch("generic_title_flag") == "true" && row.fetch("accepted_evidence_refs").empty?
  end
  rows_with_source_items = rows.count { |row| row.fetch("source_item_match_count").to_i.positive? }
  rows_with_aliases = rows.count { |row| row.fetch("alias_count").to_i.positive? }

  File.open(path, "w") do |file|
    file.puts "# X051 Generic Selection-Basis Review"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X051 reviews the 50 X050 cut-side work orders as selection-basis and source-support problems. The point is to avoid treating generic selected-work rows as easy cuts before their identity, edition/selection basis, and evidence state are checked."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_generate_generic_selection_basis_review.rb`."
    file.puts "- Added `canon_generic_selection_basis_review.tsv`."
    file.puts "- Generated #{rows.size} review rows from X050 work orders."
    file.puts "- Rows with alias support: #{rows_with_aliases}."
    file.puts "- Rows with matched source items: #{rows_with_source_items}."
    file.puts "- Generic-title rows without accepted evidence: #{unsupported_generic_rows}."
    file.puts
    file.puts "Selection-basis status summary:"
    file.puts
    file.puts "| Status | Rows |"
    file.puts "|---|---:|"
    status_counts.sort.each { |status, count| file.puts "| `#{status}` | #{count} |" }
    file.puts
    file.puts "Recommended resolution summary:"
    file.puts
    file.puts "| Resolution | Rows |"
    file.puts "|---|---:|"
    resolution_counts.sort.each { |resolution, count| file.puts "| `#{resolution}` | #{count} |" }
    file.puts
    file.puts "Highest-priority unresolved rows:"
    file.puts
    file.puts "| Review ID | Cut title | Creator | Status | Next action |"
    file.puts "|---|---|---|---|---|"
    rows.first(10).each do |row|
      file.puts "| `#{row.fetch("review_id")}` | #{row.fetch("cut_title")} | #{row.fetch("cut_creator")} | `#{row.fetch("selection_basis_status")}` | `#{row.fetch("next_action")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "These rows are not approved cuts. X051 turns the highest-risk work orders into a concrete review queue: verify whether the incumbent is a canonical collection, a representative selection, an anthology convenience label, or an under-sourced duplicate-cluster row before any replacement pair can advance."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

def evidence_refs(rows)
  rows.map { |row| row.fetch("evidence_id") }.join(";")
end

def selection_basis_status(order, accepted_evidence_rows, source_item_rows)
  generic = order.fetch("cut_generic_title_flag") == "true"
  accepted_evidence_count = accepted_evidence_rows.size
  source_item_count = source_item_rows.size

  return "generic_title_unresolved_no_source_support" if generic && accepted_evidence_count.zero? && source_item_count.zero?
  return "generic_title_source_items_need_evidence_review" if generic && accepted_evidence_count.zero?
  return "generic_title_has_evidence_selection_basis_review_required" if generic
  return "non_generic_source_support_unresolved" if accepted_evidence_count.zero?

  "supported_but_cut_review_required"
end

def recommended_resolution(status)
  case status
  when "generic_title_unresolved_no_source_support"
    "hold_cut_pairing_until_selection_basis_and_external_support_are_verified"
  when "generic_title_source_items_need_evidence_review"
    "review_matched_source_items_then_accept_or_reject_cut_side_evidence"
  when "generic_title_has_evidence_selection_basis_review_required"
    "review_whether_row_is_collection_or_representative_selection"
  when "non_generic_source_support_unresolved"
    "extract_or_accept_cut_side_source_support_before_cut_decision"
  else
    "manual_cut_score_and_quality_review"
  end
end

def next_action(status)
  case status
  when "generic_title_unresolved_no_source_support"
    "find_author_work_specific_source_or_mark_cut_basis_unresolved"
  when "generic_title_source_items_need_evidence_review"
    "review_source_item_scope_and_generate_cut_side_evidence"
  when "generic_title_has_evidence_selection_basis_review_required"
    "resolve_collection_vs_selected_representation_basis"
  when "non_generic_source_support_unresolved"
    "extract_cut_side_source_support"
  else
    "compute_cut_side_score_after_manual_review"
  end
end

orders = read_tsv(CUT_REVIEW_WORK_ORDERS_PATH)
work_by_id = read_tsv(WORK_CANDIDATES_PATH).to_h { |row| [row.fetch("work_id"), row] }
source_debt_by_work = read_tsv(SOURCE_DEBT_STATUS_PATH).to_h { |row| [row.fetch("work_id"), row] }
aliases_by_work = read_tsv(ALIASES_PATH).group_by { |row| row.fetch("work_id") }
source_items_by_work = read_tsv(SOURCE_ITEMS_PATH).group_by { |row| row.fetch("matched_work_id") }
evidence_by_work = read_tsv(EVIDENCE_PATH).group_by { |row| row.fetch("work_id") }

review_rows = orders.map.with_index(1) do |order, index|
  work = work_by_id.fetch(order.fetch("cut_work_id"))
  source_debt = source_debt_by_work.fetch(order.fetch("cut_work_id"))
  aliases = aliases_by_work.fetch(order.fetch("cut_work_id"), [])
  source_items = source_items_by_work.fetch(order.fetch("cut_work_id"), [])
  evidence = evidence_by_work.fetch(order.fetch("cut_work_id"), [])
  accepted_evidence = evidence.select { |row| row.fetch("reviewer_status") == "accepted" }
  provisional_evidence = evidence.reject { |row| row.fetch("reviewer_status") == "accepted" }
  status = selection_basis_status(order, accepted_evidence, source_items)

  {
    "review_id" => "x051_selection_basis_#{index.to_s.rjust(4, "0")}",
    "work_order_id" => order.fetch("work_order_id"),
    "cut_work_id" => order.fetch("cut_work_id"),
    "cut_title" => order.fetch("cut_title"),
    "cut_creator" => order.fetch("cut_creator"),
    "cut_rank" => order.fetch("cut_rank"),
    "selection_basis" => work.fetch("selection_basis"),
    "completion_unit" => work.fetch("completion_unit"),
    "source_debt_status" => source_debt.fetch("source_debt_status"),
    "evidence_count" => source_debt.fetch("evidence_count"),
    "accepted_evidence_refs" => evidence_refs(accepted_evidence),
    "provisional_evidence_refs" => evidence_refs(provisional_evidence),
    "alias_count" => aliases.size.to_s,
    "alias_examples" => aliases.first(3).map { |row| row.fetch("alias") }.join(";"),
    "source_item_match_count" => source_items.size.to_s,
    "source_item_match_statuses" => source_items.map { |row| row.fetch("match_status") }.uniq.sort.join(";"),
    "duplicate_cluster_key" => order.fetch("cut_duplicate_cluster_key"),
    "duplicate_cluster_size" => order.fetch("cut_duplicate_cluster_size"),
    "generic_title_flag" => order.fetch("cut_generic_title_flag"),
    "selection_basis_status" => status,
    "recommended_resolution" => recommended_resolution(status),
    "next_action" => next_action(status)
  }
end

write_tsv(GENERIC_SELECTION_REVIEW_PATH, HEADERS, review_rows)
write_report(REPORT_PATH, review_rows)

puts "wrote #{GENERIC_SELECTION_REVIEW_PATH.sub(ROOT + "/", "")} (#{review_rows.size} rows)"
review_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("selection_basis_status")] += 1 }.sort.each do |status, count|
  puts "#{status}: #{count}"
end
