#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")
REPORT_FILE = File.join(MANIFEST_DIR, "canon_source_item_progress.md")

REGISTRY_FILE = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_FILE = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_FILE = File.join(TABLE_DIR, "canon_evidence.tsv")

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

registry_rows = read_tsv(REGISTRY_FILE)
source_items = read_tsv(SOURCE_ITEMS_FILE)
evidence_rows = read_tsv(EVIDENCE_FILE)

items_by_source = source_items.group_by { |row| row["source_id"] }
evidence_by_source = evidence_rows.group_by { |row| row["source_id"] }

all_statuses = source_items.map { |row| row["match_status"].to_s }.reject(&:empty?).uniq.sort
all_evidence_types = source_items.map { |row| row["evidence_type"].to_s }.reject(&:empty?).uniq.sort

report = []
report << "# Canon Source-Item Progress"
report << ""
report << "- generated_on: #{Time.now.utc.strftime("%Y-%m-%d")}"
report << "- registered_sources: #{registry_rows.size}"
report << "- source_item_rows: #{source_items.size}"
report << "- evidence_rows: #{evidence_rows.size}"
report << "- match_statuses: #{all_statuses.join(", ")}"
report << "- evidence_types: #{all_evidence_types.join(", ")}"
report << ""
report << "## By Source"
report << ""
report << "| Source ID | Packet | Extraction Status | Items | Evidence | Matched Current | Matched Candidate | Represented | Unmatched | Out Of Scope | Unresolved |"
report << "|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|"

registry_rows.sort_by { |row| row["source_id"].to_s }.each do |source|
  rows = items_by_source.fetch(source["source_id"], [])
  status_counts = rows.each_with_object(Hash.new(0)) do |row, counts|
    counts[row["match_status"].to_s] += 1
  end
  report << [
    "| `#{source["source_id"]}`",
    source["packet_ids"],
    source["extraction_status"],
    rows.size,
    evidence_by_source.fetch(source["source_id"], []).size,
    status_counts.fetch("matched_current_path", 0),
    status_counts.fetch("matched_candidate", 0),
    status_counts.fetch("represented_by_selection", 0),
    status_counts.fetch("unmatched", 0),
    status_counts.fetch("out_of_scope", 0),
    status_counts.fetch("unresolved", 0)
  ].join(" | ") + " |"
end

report << ""
report << "## Empty Registered Sources"
report << ""
empty_sources = registry_rows.select { |source| items_by_source.fetch(source["source_id"], []).empty? }
empty_sources.each do |source|
  report << "- `#{source["source_id"]}` (#{source["packet_ids"]}; #{source["extraction_status"]})"
end
report << "" if empty_sources.empty?

FileUtils.mkdir_p(MANIFEST_DIR)
File.write(REPORT_FILE, report.join("\n"))

puts "wrote #{REPORT_FILE.sub(ROOT + "/", "")}"
