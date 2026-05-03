#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_WEIGHTS_PATH = File.join(TABLE_DIR, "canon_source_weights.yml")
SOURCE_DEBT_RULES_PATH = File.join(TABLE_DIR, "canon_source_debt_rules.yml")
SOURCE_DEBT_STATUS_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")

HEADERS = %w[
  work_id candidate_status canonical_title evidence_count accepted_external_support_count
  provisional_external_support_count accepted_independent_support_families
  provisional_independent_support_families representative_selection_count
  non_scoring_evidence_count internal_evidence_count source_debt_status closure_scope
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

def support_family(evidence, source_class_key)
  [source_class_key, evidence.fetch("source_id")].join(":")
end

def closing_support?(evidence, source_class_rule)
  return false unless evidence.fetch("evidence_type") == "inclusion"

  %w[conditional limited].include?(source_class_rule.fetch("closes_external_source_debt").to_s)
end

work_rows = read_tsv(WORK_CANDIDATES_PATH)
source_rows = read_tsv(SOURCE_REGISTRY_PATH)
evidence_rows = read_tsv(EVIDENCE_PATH)
source_weights = YAML.load_file(SOURCE_WEIGHTS_PATH)
source_debt_rules = YAML.load_file(SOURCE_DEBT_RULES_PATH)

sources_by_id = source_rows.to_h { |row| [row.fetch("source_id"), row] }
source_type_mapping = source_weights.fetch("source_type_mapping")
source_class_rules = source_debt_rules.fetch("source_class_rules")
evidence_by_work = evidence_rows.group_by { |row| row.fetch("work_id") }
min_support_families = source_debt_rules.fetch("global_rules").fetch("non_obvious_addition_min_independent_canon_support_families")

status_rows = work_rows.map do |work|
  work_evidence = evidence_by_work.fetch(work.fetch("work_id"), [])
  accepted_families = Set.new
  provisional_families = Set.new
  accepted_external = 0
  provisional_external = 0
  representative_count = 0
  non_scoring_count = 0
  internal_count = 0

  work_evidence.each do |evidence|
    source = sources_by_id.fetch(evidence.fetch("source_id"))
    source_class_key = source_type_mapping.fetch(source.fetch("source_type"))
    source_class_rule = source_class_rules.fetch(source_class_key)
    closes = source_class_rule.fetch("closes_external_source_debt").to_s

    representative_count += 1 if evidence.fetch("evidence_type") == "representative_selection"
    non_scoring_count += 1 if closes == "false"
    internal_count += 1 if source_class_key == "internal_record_or_packet_output"
    next unless closing_support?(evidence, source_class_rule)

    family = support_family(evidence, source_class_key)
    if evidence.fetch("reviewer_status") == "accepted"
      accepted_external += 1
      accepted_families << family
    else
      provisional_external += 1
      provisional_families << family
    end
  end

  status, closure_scope, blocking_reason, next_action =
    if work_evidence.empty?
      ["open_no_evidence", "none", "No evidence rows exist for this work.", "extract_or_match_source_items"]
    elsif accepted_families.size >= min_support_families
      ["closed_by_independent_external_support", "complete_work_candidate_scope_pending", "Meets minimum accepted independent support-family count.", "score_with_duplicate_boundary_and_taxonomy_gates"]
    elsif accepted_external.positive?
      ["open_insufficient_independent_support", "partial", "Accepted external evidence exists but independent support-family count is below #{min_support_families}.", "seek_additional_independent_support_or_waiver"]
    elsif provisional_external.positive?
      ["open_provisional_external_support", "none", "External evidence exists but reviewer_status is not accepted.", "review_evidence_scope_and_accept_or_reject"]
    elsif internal_count == work_evidence.size
      ["open_internal_only", "none", "Only internal accepted-site or packet evidence exists.", "add_external_source_support"]
    elsif non_scoring_count == work_evidence.size
      ["open_non_scoring_only", "identity_or_access_only", "Only non-scoring corpus, bibliographic, metadata, or access evidence exists.", "seek_canon_support_source"]
    elsif representative_count.positive?
      ["open_selection_only", "selection_identity", "Evidence is selection/representation support, not complete-work support.", "verify_complete_work_scope_or_record_selection_policy"]
    else
      ["open_needs_review", "none", "Evidence exists but does not satisfy debt-closure rules.", "manual_source_debt_review"]
    end

  {
    "work_id" => work.fetch("work_id"),
    "candidate_status" => work.fetch("candidate_status"),
    "canonical_title" => work.fetch("canonical_title"),
    "evidence_count" => work_evidence.size.to_s,
    "accepted_external_support_count" => accepted_external.to_s,
    "provisional_external_support_count" => provisional_external.to_s,
    "accepted_independent_support_families" => accepted_families.size.to_s,
    "provisional_independent_support_families" => provisional_families.size.to_s,
    "representative_selection_count" => representative_count.to_s,
    "non_scoring_evidence_count" => non_scoring_count.to_s,
    "internal_evidence_count" => internal_count.to_s,
    "source_debt_status" => status,
    "closure_scope" => closure_scope,
    "blocking_reason" => blocking_reason,
    "next_action" => next_action
  }
end

write_tsv(SOURCE_DEBT_STATUS_PATH, HEADERS, status_rows)

counts = status_rows.each_with_object(Hash.new(0)) { |row, tally| tally[row.fetch("source_debt_status")] += 1 }
puts "wrote #{SOURCE_DEBT_STATUS_PATH.sub(ROOT + "/", "")} (#{status_rows.size} rows)"
counts.sort.each { |status, count| puts "#{status}: #{count}" }
