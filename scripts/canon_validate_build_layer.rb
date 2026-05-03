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
  "replacement_candidates" => File.join(BUILD_DIR, "tables", "canon_replacement_candidates.tsv"),
  "packet_status" => File.join(BUILD_DIR, "tables", "canon_packet_status.tsv")
}.freeze

HEADER_REQUIREMENTS = {
  "source_registry" => ["source_id", "source_title", "source_type", "source_scope", "source_date", "source_citation", "extraction_status"],
  "source_items" => ["source_id", "source_item_id", "raw_title", "evidence_type", "supports", "match_status"],
  "work_candidates" => ["work_id", "candidate_status", "canonical_title", "creator_display", "date_label", "sort_year", "date_precision", "macro_region", "literary_tradition", "form_bucket", "source_status", "review_status"],
  "evidence" => ["evidence_id", "work_id", "source_id", "evidence_type", "evidence_strength", "reviewer_status"],
  "scores" => ["work_id", "source_weighted_score", "source_diversity_score", "coverage_scarcity_bonus", "boundary_penalty", "duplicate_overlap_penalty", "source_debt_penalty", "final_score", "must_include", "must_exclude"],
  "replacement_candidates" => ["transaction_id", "add_work_id", "cut_work_id", "evidence_refs", "rationale", "gate_status"],
  "packet_status" => ["packet_id", "packet_family", "scope", "status", "gate", "output_artifact", "next_action"]
}.freeze

CONTROLLED_FIELD_CHECKS = {
  "source_registry" => {
    "schema" => "source",
    "fields" => ["source_type", "extraction_status"]
  },
  "source_items" => {
    "schema" => "source",
    "fields" => ["evidence_type", "match_status"]
  },
  "work_candidates" => {
    "schema" => "work",
    "fields" => ["candidate_status", "date_precision", "review_status"]
  },
  "evidence" => {
    "schema" => "evidence",
    "fields" => ["evidence_strength", "reviewer_status"]
  },
  "replacement_candidates" => {
    "schema" => "evidence",
    "fields" => ["gate_status"]
  }
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
  schemas = SCHEMA_FILES.transform_values { |path| YAML.load_file(path) }
  registry_rows = read_tsv(TABLE_FILES["source_registry"])
  source_item_rows = read_tsv(TABLE_FILES["source_items"])
  work_rows = read_tsv(TABLE_FILES["work_candidates"])
  evidence_rows = read_tsv(TABLE_FILES["evidence"])
  relation_rows = read_tsv(TABLE_FILES["relations"])
  path_selection_rows = read_tsv(TABLE_FILES["path_selection"])
  replacement_rows = read_tsv(TABLE_FILES["replacement_candidates"])

  table_rows = {
    "source_registry" => registry_rows,
    "source_items" => source_item_rows,
    "work_candidates" => work_rows,
    "relations" => relation_rows,
    "evidence" => evidence_rows,
    "replacement_candidates" => replacement_rows
  }

  source_ids = registry_rows.map { |row| row["source_id"] }.to_set
  source_item_ids = source_item_rows.map { |row| row["source_item_id"] }.to_set
  work_ids = work_rows.map { |row| row["work_id"] }.to_set

  CONTROLLED_FIELD_CHECKS.each do |table, config|
    schema = schemas.fetch(config.fetch("schema"))
    controlled_values = schema.fetch("controlled_values", {})
    rows = table_rows.fetch(table)

    config.fetch("fields").each do |field|
      allowed = Array(controlled_values[field]).to_set
      if allowed.empty?
        checks << ["controlled:#{table}.#{field}", "WARN", "no controlled values declared"]
        next
      end

      invalid = rows.reject do |row|
        value = row[field].to_s
        value.empty? || allowed.include?(value)
      end

      if invalid.empty?
        checks << ["controlled:#{table}.#{field}", "PASS", "#{allowed.size} allowed values"]
      else
        examples = invalid.first(10).map { |row| row[field].to_s }.uniq
        failures << "#{table}.#{field} has invalid controlled values: #{examples.join(", ")}"
        checks << ["controlled:#{table}.#{field}", "FAIL", "#{invalid.size} invalid rows"]
      end
    end
  end

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

  source_items_by_id = source_item_rows.each_with_object({}) { |row, by_id| by_id[row["source_item_id"]] = row }
  evidence_with_unsupported_source_items = evidence_rows.select do |row|
    source_item_id = row["source_item_id"].to_s
    next false if source_item_id.empty?

    source_item = source_items_by_id[source_item_id]
    source_item && !%w[matched_current_path matched_candidate represented_by_selection duplicate_or_variant].include?(source_item["match_status"])
  end
  if evidence_with_unsupported_source_items.empty?
    checks << ["integrity:evidence.supported_source_item_status", "PASS", "no evidence from unmatched/out-of-scope source items"]
  else
    examples = evidence_with_unsupported_source_items.first(10).map { |row| "#{row["evidence_id"]}:#{row["source_item_id"]}" }
    failures << "evidence rows reference source items with unsupported match_status: #{examples.join(", ")}"
    checks << ["integrity:evidence.supported_source_item_status", "FAIL", "#{evidence_with_unsupported_source_items.size} invalid evidence rows"]
  end

  unknown_relation_works = relation_rows.reject do |row|
    work_ids.include?(row["work_id"]) && work_ids.include?(row["related_work_id"])
  end
  if unknown_relation_works.empty?
    checks << ["integrity:relations.work_refs", "PASS", "all relation work refs exist"]
  else
    examples = unknown_relation_works.first(10).map { |row| "#{row["relation_id"]}:#{row["work_id"]}->#{row["related_work_id"]}" }
    failures << "relations reference unknown work IDs: #{examples.join(", ")}"
    checks << ["integrity:relations.work_refs", "FAIL", "#{unknown_relation_works.size} unknown references"]
  end

  path_selection_work_refs = path_selection_rows.reject { |row| work_ids.include?(row["work_id"]) }
  if path_selection_work_refs.empty?
    checks << ["integrity:path_selection.work_id", "PASS", "all selected work IDs exist"]
  else
    examples = path_selection_work_refs.first(10).map { |row| "#{row["path_id"]}:#{row["work_id"]}" }
    failures << "path_selection rows reference unknown work IDs: #{examples.join(", ")}"
    checks << ["integrity:path_selection.work_id", "FAIL", "#{path_selection_work_refs.size} unknown references"]
  end

  selected_path_rows = path_selection_rows.select { |row| row["selected"].to_s == "true" }
  rank_counts = selected_path_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row["rank"].to_i] += 1 }
  duplicate_ranks = rank_counts.select { |_rank, count| count > 1 }
  expected_ranks = (1..selected_path_rows.size).to_set
  actual_ranks = rank_counts.keys.to_set
  missing_ranks = expected_ranks - actual_ranks
  if duplicate_ranks.empty? && missing_ranks.empty?
    checks << ["integrity:path_selection.selected_rank_continuity", "PASS", "#{selected_path_rows.size} selected rows"]
  else
    failures << "path_selection selected ranks are not unique/continuous: #{duplicate_ranks.size} duplicate ranks, #{missing_ranks.size} missing ranks"
    checks << ["integrity:path_selection.selected_rank_continuity", "FAIL", "#{duplicate_ranks.size} duplicate ranks; #{missing_ranks.size} missing ranks"]
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
