#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_STATUS_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
OMISSION_QUEUE_PATH = File.join(TABLE_DIR, "canon_omission_queue.tsv")

HEADERS = %w[
  omission_id work_id canonical_title creator_display source_debt_status evidence_refs
  evidence_count duplicate_risk boundary_risk chronology_risk scope_risk readiness_status
  blocking_reason next_action
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

def risk_flag(condition, label)
  condition ? label : "none"
end

works = read_tsv(WORK_CANDIDATES_PATH)
evidence_rows = read_tsv(EVIDENCE_PATH)
source_debt_rows = read_tsv(SOURCE_DEBT_STATUS_PATH)

evidence_by_work = evidence_rows.group_by { |row| row.fetch("work_id") }
source_debt_by_work = source_debt_rows.to_h { |row| [row.fetch("work_id"), row] }
sort_title_counts = works.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("sort_title")] += 1 }

omission_rows = works.select { |row| row.fetch("candidate_status") == "source_backed_candidate" }.map.with_index(1) do |work, index|
  debt = source_debt_by_work.fetch(work.fetch("work_id"))
  evidence = evidence_by_work.fetch(work.fetch("work_id"), [])
  evidence_refs = evidence.map { |row| row.fetch("evidence_id") }.sort.join(";")
  duplicate_risk = risk_flag(sort_title_counts.fetch(work.fetch("sort_title")) > 1, "duplicate_title_cluster")
  boundary_risk = risk_flag(work.fetch("boundary_flags").to_s != "" && work.fetch("boundary_flags") != "scope_pending", work.fetch("boundary_flags"))
  chronology_risk = risk_flag(work.fetch("date_precision") == "unknown" || work.fetch("sort_year").to_s == "0", "date_or_sort_year_pending")
  scope_risk = risk_flag(work.fetch("completion_unit").match?(/pending|selection|identity/), "completion_or_selection_scope_pending")
  readiness =
    if debt.fetch("source_debt_status").start_with?("closed") && [duplicate_risk, boundary_risk, chronology_risk, scope_risk].all? { |risk| risk == "none" }
      "ready_for_scoring_review"
    else
      "not_ready_for_scoring"
    end

  {
    "omission_id" => "x018_omission_#{index.to_s.rjust(4, "0")}",
    "work_id" => work.fetch("work_id"),
    "canonical_title" => work.fetch("canonical_title"),
    "creator_display" => work.fetch("creator_display"),
    "source_debt_status" => debt.fetch("source_debt_status"),
    "evidence_refs" => evidence_refs,
    "evidence_count" => evidence.size.to_s,
    "duplicate_risk" => duplicate_risk,
    "boundary_risk" => boundary_risk,
    "chronology_risk" => chronology_risk,
    "scope_risk" => scope_risk,
    "readiness_status" => readiness,
    "blocking_reason" => debt.fetch("blocking_reason"),
    "next_action" => debt.fetch("next_action")
  }
end

write_tsv(OMISSION_QUEUE_PATH, HEADERS, omission_rows)

puts "wrote #{OMISSION_QUEUE_PATH.sub(ROOT + "/", "")} (#{omission_rows.size} rows)"
omission_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("readiness_status")] += 1 }.sort.each do |status, count|
  puts "#{status}: #{count}"
end
