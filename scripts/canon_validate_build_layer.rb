#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")
REPORT_PATH = File.join(MANIFEST_DIR, "canon_build_validation.md")

SCHEMA_FILES = {
  "source" => File.join(BUILD_DIR, "schemas", "canon_source.schema.yml"),
  "work" => File.join(BUILD_DIR, "schemas", "canon_work.schema.yml"),
  "evidence" => File.join(BUILD_DIR, "schemas", "canon_evidence.schema.yml")
}.freeze

TABLE_FILES = {
  "source_registry" => File.join(BUILD_DIR, "tables", "canon_source_registry.tsv"),
  "source_items" => File.join(BUILD_DIR, "tables", "canon_source_items.tsv"),
  "work_candidates" => File.join(BUILD_DIR, "tables", "canon_work_candidates.tsv"),
  "creators" => File.join(BUILD_DIR, "tables", "canon_creators.tsv"),
  "work_creators" => File.join(BUILD_DIR, "tables", "canon_work_creators.tsv"),
  "aliases" => File.join(BUILD_DIR, "tables", "canon_aliases.tsv"),
  "relations" => File.join(BUILD_DIR, "tables", "canon_relations.tsv"),
  "evidence" => File.join(BUILD_DIR, "tables", "canon_evidence.tsv"),
  "review_decisions" => File.join(BUILD_DIR, "tables", "canon_review_decisions.yml"),
  "scores" => File.join(BUILD_DIR, "tables", "canon_scores.tsv"),
  "coverage_targets" => File.join(BUILD_DIR, "tables", "canon_coverage_targets.yml"),
  "path_selection" => File.join(BUILD_DIR, "tables", "canon_path_selection.tsv"),
  "replacement_candidates" => File.join(BUILD_DIR, "tables", "canon_replacement_candidates.tsv")
}.freeze

HEADER_REQUIREMENTS = {
  "source_registry" => ["source_id", "source_title", "source_type", "source_scope", "source_date", "source_citation", "extraction_status"],
  "source_items" => ["source_id", "source_item_id", "raw_title", "evidence_type", "supports", "match_status"],
  "work_candidates" => ["work_id", "candidate_status", "canonical_title", "creator_display", "date_label", "sort_year", "date_precision", "macro_region", "literary_tradition", "form_bucket", "source_status", "review_status"],
  "evidence" => ["evidence_id", "work_id", "source_id", "evidence_type", "evidence_strength", "reviewer_status"],
  "scores" => ["work_id", "source_weighted_score", "source_diversity_score", "coverage_scarcity_bonus", "boundary_penalty", "duplicate_overlap_penalty", "source_debt_penalty", "final_score", "must_include", "must_exclude"],
  "replacement_candidates" => ["transaction_id", "add_work_id", "cut_work_id", "evidence_refs", "rationale", "gate_status"]
}.freeze

def tsv_headers(path)
  line = File.open(path, &:readline)
  CSV.parse_line(line, col_sep: "\t")
end

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def duplicate_values(rows, key)
  rows.each_with_object(Hash.new(0)) do |row, counts|
    value = row[key].to_s
    counts[value] += 1 unless value.empty?
  end.select { |_value, count| count > 1 }
end

failures = []
checks = []

SCHEMA_FILES.each do |label, path|
  if File.file?(path)
    begin
      YAML.load_file(path)
      checks << ["schema:#{label}", "PASS", path]
    rescue Psych::Exception => e
      failures << "Schema #{label} is invalid YAML: #{e.message}"
      checks << ["schema:#{label}", "FAIL", path]
    end
  else
    failures << "Missing schema file: #{path}"
    checks << ["schema:#{label}", "FAIL", path]
  end
end

TABLE_FILES.each do |label, path|
  unless File.file?(path)
    failures << "Missing table file: #{path}"
    checks << ["table:#{label}", "FAIL", path]
    next
  end

  if File.extname(path) == ".yml"
    begin
      YAML.load_file(path)
      checks << ["table:#{label}", "PASS", path]
    rescue Psych::Exception => e
      failures << "Table #{label} is invalid YAML: #{e.message}"
      checks << ["table:#{label}", "FAIL", path]
    end
    next
  end

  headers = tsv_headers(path)
  missing = Array(HEADER_REQUIREMENTS[label]) - headers
  if missing.empty?
    checks << ["table:#{label}", "PASS", "#{path} (#{headers.size} columns)"]
  else
    failures << "Table #{label} missing required columns: #{missing.join(", ")}"
    checks << ["table:#{label}", "FAIL", path]
  end
rescue EOFError
  failures << "Table #{label} is empty: #{path}"
  checks << ["table:#{label}", "FAIL", path]
end

if failures.empty?
  registry_rows = read_tsv(TABLE_FILES["source_registry"])
  source_item_rows = read_tsv(TABLE_FILES["source_items"])
  work_rows = read_tsv(TABLE_FILES["work_candidates"])
  evidence_rows = read_tsv(TABLE_FILES["evidence"])

  source_ids = registry_rows.map { |row| row["source_id"] }.to_set
  source_item_ids = source_item_rows.map { |row| row["source_item_id"] }.to_set
  work_ids = work_rows.map { |row| row["work_id"] }.to_set

  {
    "source_registry.source_id" => duplicate_values(registry_rows, "source_id"),
    "source_items.source_item_id" => duplicate_values(source_item_rows, "source_item_id"),
    "work_candidates.work_id" => duplicate_values(work_rows, "work_id"),
    "evidence.evidence_id" => duplicate_values(evidence_rows, "evidence_id")
  }.each do |label, duplicates|
    if duplicates.empty?
      checks << ["integrity:unique:#{label}", "PASS", "0 duplicates"]
    else
      failures << "#{label} has duplicate values: #{duplicates.keys.first(10).join(", ")}"
      checks << ["integrity:unique:#{label}", "FAIL", "#{duplicates.size} duplicate keys"]
    end
  end

  unknown_source_items = source_item_rows.reject { |row| source_ids.include?(row["source_id"]) }
  if unknown_source_items.empty?
    checks << ["integrity:source_items.source_id", "PASS", "all source IDs registered"]
  else
    examples = unknown_source_items.first(10).map { |row| "#{row["source_item_id"]}:#{row["source_id"]}" }
    failures << "source_items rows reference unknown source IDs: #{examples.join(", ")}"
    checks << ["integrity:source_items.source_id", "FAIL", "#{unknown_source_items.size} unknown references"]
  end

  unknown_source_item_works = source_item_rows.reject { |row| row["matched_work_id"].to_s.empty? || work_ids.include?(row["matched_work_id"]) }
  if unknown_source_item_works.empty?
    checks << ["integrity:source_items.matched_work_id", "PASS", "all nonblank matched work IDs exist"]
  else
    examples = unknown_source_item_works.first(10).map { |row| "#{row["source_item_id"]}:#{row["matched_work_id"]}" }
    failures << "source_items rows reference unknown matched work IDs: #{examples.join(", ")}"
    checks << ["integrity:source_items.matched_work_id", "FAIL", "#{unknown_source_item_works.size} unknown references"]
  end

  unknown_evidence_sources = evidence_rows.reject { |row| source_ids.include?(row["source_id"]) }
  if unknown_evidence_sources.empty?
    checks << ["integrity:evidence.source_id", "PASS", "all source IDs registered"]
  else
    examples = unknown_evidence_sources.first(10).map { |row| "#{row["evidence_id"]}:#{row["source_id"]}" }
    failures << "evidence rows reference unknown source IDs: #{examples.join(", ")}"
    checks << ["integrity:evidence.source_id", "FAIL", "#{unknown_evidence_sources.size} unknown references"]
  end

  unknown_evidence_items = evidence_rows.reject { |row| row["source_item_id"].to_s.empty? || source_item_ids.include?(row["source_item_id"]) }
  if unknown_evidence_items.empty?
    checks << ["integrity:evidence.source_item_id", "PASS", "all nonblank source item IDs exist"]
  else
    examples = unknown_evidence_items.first(10).map { |row| "#{row["evidence_id"]}:#{row["source_item_id"]}" }
    failures << "evidence rows reference unknown source item IDs: #{examples.join(", ")}"
    checks << ["integrity:evidence.source_item_id", "FAIL", "#{unknown_evidence_items.size} unknown references"]
  end

  unknown_evidence_works = evidence_rows.reject { |row| work_ids.include?(row["work_id"]) }
  if unknown_evidence_works.empty?
    checks << ["integrity:evidence.work_id", "PASS", "all work IDs exist"]
  else
    examples = unknown_evidence_works.first(10).map { |row| "#{row["evidence_id"]}:#{row["work_id"]}" }
    failures << "evidence rows reference unknown work IDs: #{examples.join(", ")}"
    checks << ["integrity:evidence.work_id", "FAIL", "#{unknown_evidence_works.size} unknown references"]
  end
end

FileUtils.mkdir_p(MANIFEST_DIR)

report = []
report << "# Canon Build Layer Validation"
report << ""
report << "- status: #{failures.empty? ? "PASS" : "FAIL"}"
report << "- checked_files: #{SCHEMA_FILES.size + TABLE_FILES.size}"
report << "- failures: #{failures.size}"
report << ""
report << "## Checks"
report << ""
report << "| Check | Status | Detail |"
report << "|---|---|---|"
checks.each do |name, status, detail|
  report << "| #{name} | #{status} | `#{detail.sub(ROOT + "/", "")}` |"
end
unless failures.empty?
  report << ""
  report << "## Failures"
  report << ""
  failures.each { |failure| report << "- #{failure}" }
end
report << ""

File.write(REPORT_PATH, report.join("\n"))

puts failures.empty? ? "canon build validation passed" : "canon build validation failed"
exit(failures.empty? ? 0 : 1)
