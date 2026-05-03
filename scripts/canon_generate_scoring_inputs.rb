#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
SOURCE_DEBT_STATUS_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
RELATION_SCOPE_STATUS_PATH = File.join(TABLE_DIR, "canon_relation_scope_status.tsv")
OMISSION_QUEUE_PATH = File.join(TABLE_DIR, "canon_omission_queue.tsv")
SCORING_INPUTS_PATH = File.join(TABLE_DIR, "canon_scoring_inputs.tsv")

HEADERS = %w[
  work_id candidate_status canonical_title source_debt_status evidence_count
  accepted_independent_support_families provisional_independent_support_families
  omission_readiness relation_scope_blocker_count date_uncertainty_flag boundary_scope_flag
  source_debt_penalty_input relation_scope_penalty_input date_uncertainty_penalty_input
  boundary_scope_penalty_input scoring_readiness blocking_reasons next_action
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

def bool_flag(condition)
  condition ? "1" : "0"
end

def open_boundary_flag?(value)
  !value.to_s.strip.empty?
end

def open_completion_scope?(value)
  normalized = value.to_s.strip.downcase
  return false if normalized.empty?

  normalized.include?("pending") || normalized == "work_identity"
end

works = read_tsv(WORK_CANDIDATES_PATH)
source_debt_rows = read_tsv(SOURCE_DEBT_STATUS_PATH)
relation_scope_rows = read_tsv(RELATION_SCOPE_STATUS_PATH)
omission_rows = read_tsv(OMISSION_QUEUE_PATH)

source_debt_by_work = source_debt_rows.to_h { |row| [row.fetch("work_id"), row] }
omission_by_work = omission_rows.to_h { |row| [row.fetch("work_id"), row] }
relation_blockers_by_work = Hash.new(0)
relation_scope_rows.each do |row|
  next if row.fetch("readiness_status") == "ready_to_write_relation"

  [row.fetch("target_work_id"), row.fetch("matched_work_id")].reject(&:empty?).uniq.each do |work_id|
    relation_blockers_by_work[work_id] += 1
  end
end

rows = works.map do |work|
  work_id = work.fetch("work_id")
  debt = source_debt_by_work.fetch(work_id)
  omission = omission_by_work[work_id]
  source_debt_open = !debt.fetch("source_debt_status").start_with?("closed")
  relation_blockers = relation_blockers_by_work.fetch(work_id, 0)
  date_uncertain = work.fetch("date_precision") == "unknown" || work.fetch("sort_year").to_s == "0"
  boundary_scope_open = open_boundary_flag?(work.fetch("boundary_flags")) || open_completion_scope?(work.fetch("completion_unit"))
  omission_readiness = omission ? omission.fetch("readiness_status") : "not_omission_candidate"

  blocking_reasons = []
  blocking_reasons << "source_debt_open" if source_debt_open
  blocking_reasons << "relation_scope_blockers" if relation_blockers.positive?
  blocking_reasons << "omission_not_ready" if omission && omission_readiness != "ready_for_scoring_review"
  blocking_reasons << "date_uncertain" if date_uncertain
  blocking_reasons << "boundary_or_completion_scope_open" if boundary_scope_open

  readiness = blocking_reasons.empty? ? "ready_for_score_computation" : "blocked_from_score_computation"
  next_action =
    if source_debt_open
      debt.fetch("next_action")
    elsif omission && omission_readiness != "ready_for_scoring_review"
      omission.fetch("next_action")
    elsif relation_blockers.positive?
      "resolve_relation_scope_blockers"
    elsif date_uncertain
      "resolve_date_basis"
    elsif boundary_scope_open
      "resolve_boundary_or_completion_scope"
    else
      "compute_score"
    end

  {
    "work_id" => work_id,
    "candidate_status" => work.fetch("candidate_status"),
    "canonical_title" => work.fetch("canonical_title"),
    "source_debt_status" => debt.fetch("source_debt_status"),
    "evidence_count" => debt.fetch("evidence_count"),
    "accepted_independent_support_families" => debt.fetch("accepted_independent_support_families"),
    "provisional_independent_support_families" => debt.fetch("provisional_independent_support_families"),
    "omission_readiness" => omission_readiness,
    "relation_scope_blocker_count" => relation_blockers.to_s,
    "date_uncertainty_flag" => bool_flag(date_uncertain),
    "boundary_scope_flag" => bool_flag(boundary_scope_open),
    "source_debt_penalty_input" => bool_flag(source_debt_open),
    "relation_scope_penalty_input" => bool_flag(relation_blockers.positive?),
    "date_uncertainty_penalty_input" => bool_flag(date_uncertain),
    "boundary_scope_penalty_input" => bool_flag(boundary_scope_open),
    "scoring_readiness" => readiness,
    "blocking_reasons" => blocking_reasons.join(";"),
    "next_action" => next_action
  }
end

write_tsv(SCORING_INPUTS_PATH, HEADERS, rows)

puts "wrote #{SCORING_INPUTS_PATH.sub(ROOT + "/", "")} (#{rows.size} rows)"
rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("scoring_readiness")] += 1 }.sort.each do |status, count|
  puts "#{status}: #{count}"
end
