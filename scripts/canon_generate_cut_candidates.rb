#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "set"

ROOT = File.expand_path("..", __dir__)
BUILD_TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")
AUDIT_DIR = File.join(ROOT, "_planning", "canon_audit_outputs")

WORK_CANDIDATES_PATH = File.join(BUILD_TABLE_DIR, "canon_work_candidates.tsv")
PATH_SELECTION_PATH = File.join(BUILD_TABLE_DIR, "canon_path_selection.tsv")
SOURCE_DEBT_STATUS_PATH = File.join(BUILD_TABLE_DIR, "canon_source_debt_status.tsv")
CUT_CANDIDATES_PATH = File.join(BUILD_TABLE_DIR, "canon_cut_candidates.tsv")

INVENTORY_PATH = File.join(AUDIT_DIR, "canon_inventory.tsv")
GENERIC_TITLES_PATH = File.join(AUDIT_DIR, "canon_generic_titles.tsv")
DUPLICATE_CANDIDATES_PATH = File.join(AUDIT_DIR, "canon_duplicate_candidates.tsv")
CHRONOLOGY_INVERSIONS_PATH = File.join(AUDIT_DIR, "canon_chronology_inversions.tsv")
BOUNDARY_CASES_PATH = File.join(AUDIT_DIR, "canon_boundary_cases.tsv")

HEADERS = %w[
  cut_candidate_id work_id incumbent_path_id rank title creator tier source_status review_status
  source_debt_status evidence_count generic_title_flag duplicate_cluster_key duplicate_cluster_size
  chronology_issue_count boundary_flag risk_score gate_status rationale next_action
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

def selected_path_rows
  read_tsv(PATH_SELECTION_PATH).select { |row| row.fetch("selected") == "true" }
end

inventory_by_id = read_tsv(INVENTORY_PATH).to_h { |row| [row.fetch("id"), row] }
generic_ids = read_tsv(GENERIC_TITLES_PATH).map { |row| row.fetch("id") }.to_set
boundary_ids = read_tsv(BOUNDARY_CASES_PATH).map { |row| row.fetch("id") }.to_set

duplicate_by_id = {}
read_tsv(DUPLICATE_CANDIDATES_PATH).each do |row|
  key = row.fetch("match_key")
  size = row.fetch("count").to_i
  row.fetch("ids").split(/\s+\|\s+/).each do |id|
    duplicate_by_id[id] = [key, size]
  end
end

chronology_count_by_rank = Hash.new(0)
read_tsv(CHRONOLOGY_INVERSIONS_PATH).each do |row|
  chronology_count_by_rank[row.fetch("previous_rank").to_i] += 1
  chronology_count_by_rank[row.fetch("current_rank").to_i] += 1
end

works_by_id = read_tsv(WORK_CANDIDATES_PATH).to_h { |row| [row.fetch("work_id"), row] }
source_debt_by_work = read_tsv(SOURCE_DEBT_STATUS_PATH).to_h { |row| [row.fetch("work_id"), row] }

rows = selected_path_rows.map do |selection|
  work = works_by_id.fetch(selection.fetch("work_id"))
  incumbent_path_id = work.fetch("incumbent_path_id")
  inventory = inventory_by_id.fetch(incumbent_path_id)
  debt = source_debt_by_work.fetch(work.fetch("work_id"))
  rank = selection.fetch("rank").to_i
  duplicate_key, duplicate_size = duplicate_by_id.fetch(incumbent_path_id, ["", 0])
  generic = generic_ids.include?(incumbent_path_id)
  boundary = boundary_ids.include?(incumbent_path_id)
  chronology_count = chronology_count_by_rank.fetch(rank, 0)

  risk = 0.0
  risk += 2.0 if debt.fetch("source_debt_status") == "open_no_evidence"
  risk += 1.0 if debt.fetch("source_debt_status").start_with?("open_") && debt.fetch("source_debt_status") != "open_no_evidence"
  risk += 1.5 if generic
  risk += [duplicate_size / 10.0, 2.0].min if duplicate_size.positive?
  risk += [chronology_count * 0.5, 1.5].min
  risk += 0.5 if boundary
  risk += 0.5 if inventory.fetch("review_status") == "needs_sources"
  risk -= 2.0 if inventory.fetch("tier") == "core"
  risk = [risk, 0.0].max

  gate_status =
    if inventory.fetch("tier") == "core"
      "protected_core_review_required"
    elsif risk >= 4.0
      "high_cut_review_priority"
    elsif risk >= 2.0
      "medium_cut_review_priority"
    else
      "low_cut_review_priority"
    end

  rationale_bits = []
  rationale_bits << debt.fetch("source_debt_status")
  rationale_bits << "generic_title" if generic
  rationale_bits << "duplicate_cluster=#{duplicate_key}(#{duplicate_size})" if duplicate_size.positive?
  rationale_bits << "chronology_issues=#{chronology_count}" if chronology_count.positive?
  rationale_bits << "boundary_case" if boundary
  rationale_bits << "core_protected" if inventory.fetch("tier") == "core"

  {
    "cut_candidate_id" => "x046_cut_#{rank.to_s.rjust(4, "0")}",
    "work_id" => work.fetch("work_id"),
    "incumbent_path_id" => incumbent_path_id,
    "rank" => rank.to_s,
    "title" => work.fetch("canonical_title"),
    "creator" => work.fetch("creator_display"),
    "tier" => inventory.fetch("tier"),
    "source_status" => inventory.fetch("source_status"),
    "review_status" => inventory.fetch("review_status"),
    "source_debt_status" => debt.fetch("source_debt_status"),
    "evidence_count" => debt.fetch("evidence_count"),
    "generic_title_flag" => generic ? "true" : "false",
    "duplicate_cluster_key" => duplicate_key,
    "duplicate_cluster_size" => duplicate_size.to_s,
    "chronology_issue_count" => chronology_count.to_s,
    "boundary_flag" => boundary ? "true" : "false",
    "risk_score" => format("%.2f", risk),
    "gate_status" => gate_status,
    "rationale" => rationale_bits.join(";"),
    "next_action" => "manual_cut_review_before_pairing_with_add_candidate"
  }
end

rows.sort_by! { |row| [-row.fetch("risk_score").to_f, row.fetch("rank").to_i] }

write_tsv(CUT_CANDIDATES_PATH, HEADERS, rows)

puts "wrote #{CUT_CANDIDATES_PATH.sub(ROOT + "/", "")} (#{rows.size} rows)"
rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("gate_status")] += 1 }.sort.each do |status, count|
  puts "#{status}: #{count}"
end
