#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

RELATION_DECISIONS_PATH = File.join(TABLE_DIR, "canon_relation_review_decisions.tsv")
RELATION_SCOPE_RULES_PATH = File.join(TABLE_DIR, "canon_relation_scope_rules.yml")
WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
RELATION_SCOPE_STATUS_PATH = File.join(TABLE_DIR, "canon_relation_scope_status.tsv")

HEADERS = %w[
  relation_scope_id source_item_id source_id raw_title proposed_relation_type decision
  target_work_id target_exists matched_work_id matched_work_exists scope_status writable_relation
  readiness_status blocker next_action
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

def boolean_text(value)
  value ? "true" : "false"
end

relation_decisions = read_tsv(RELATION_DECISIONS_PATH)
relation_scope_rules = YAML.load_file(RELATION_SCOPE_RULES_PATH)
work_ids = read_tsv(WORK_CANDIDATES_PATH).map { |row| row.fetch("work_id") }.to_h { |work_id| [work_id, true] }
decision_rules = relation_scope_rules.fetch("decision_rules")

status_rows = relation_decisions.map.with_index(1) do |decision, index|
  rule = decision_rules.fetch(decision.fetch("decision"))
  target_work_id = decision.fetch("target_work_id", "")
  matched_work_id = decision.fetch("matched_work_id", "")
  target_exists = target_work_id.empty? || work_ids.fetch(target_work_id, false)
  matched_work_exists = matched_work_id.empty? || work_ids.fetch(matched_work_id, false)
  writable = rule.fetch("writable_relation").to_s
  readiness =
    if writable == "true" && target_exists && matched_work_exists
      "ready_to_write_relation"
    elsif writable == "false"
      "not_writable_policy_blocked"
    elsif target_exists && matched_work_exists
      "scope_review_required"
    else
      "target_missing"
    end

  {
    "relation_scope_id" => "x014_scope_#{index.to_s.rjust(4, "0")}",
    "source_item_id" => decision.fetch("source_item_id"),
    "source_id" => decision.fetch("source_id"),
    "raw_title" => decision.fetch("raw_title"),
    "proposed_relation_type" => decision.fetch("proposed_relation_type"),
    "decision" => decision.fetch("decision"),
    "target_work_id" => target_work_id,
    "target_exists" => boolean_text(target_exists),
    "matched_work_id" => matched_work_id,
    "matched_work_exists" => boolean_text(matched_work_exists),
    "scope_status" => rule.fetch("scope_status"),
    "writable_relation" => writable,
    "readiness_status" => readiness,
    "blocker" => rule.fetch("blocker"),
    "next_action" => decision.fetch("next_action")
  }
end

write_tsv(RELATION_SCOPE_STATUS_PATH, HEADERS, status_rows)

puts "wrote #{RELATION_SCOPE_STATUS_PATH.sub(ROOT + "/", "")} (#{status_rows.size} rows)"
status_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("readiness_status")] += 1 }.sort.each do |status, count|
  puts "#{status}: #{count}"
end
