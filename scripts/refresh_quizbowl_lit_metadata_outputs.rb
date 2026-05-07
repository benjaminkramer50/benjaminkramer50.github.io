#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "json"
require "optparse"
require "yaml"

require_relative "build_quizbowl_literature_canon"

DEFAULT_CANON = File.join(ROOT, "_data", "quizbowl_literature_canon.yml")
DEFAULT_OUT_DIR = File.join(ROOT, "_planning", "quizbowl_lit_canon")

METADATA_COLUMNS = %w[
  creators creator_source creator_confidence chronology_sort_year chronology_label
  chronology_source chronology_confidence chronology_needs_review
].freeze

def parse_refresh_options
  options = {
    canon: DEFAULT_CANON,
    out_dir: DEFAULT_OUT_DIR
  }

  OptionParser.new do |parser|
    parser.on("--canon PATH") { |value| options[:canon] = value }
    parser.on("--out-dir PATH") { |value| options[:out_dir] = value }
  end.parse!

  options
end

def write_if_changed(path, content)
  return false if File.exist?(path) && File.binread(path) == content

  File.write(path, content)
  true
end

def current_tsv_creators(value)
  value.to_s.split(/\s*;\s*/).map { |creator| normalize_space(creator) }.reject(&:empty?)
end

def chronology_override_for(title)
  title_key = normalize_title(title)
  return nil unless CHRONOLOGY_TITLE_OVERRIDES.key?(title_key)

  year, label, source = CHRONOLOGY_TITLE_OVERRIDES.fetch(title_key)
  {
    "chronology_sort_year" => year,
    "chronology_label" => label,
    "chronology_source" => source,
    "chronology_confidence" => "high",
    "chronology_needs_review" => false
  }
end

def refreshed_metadata(title, current, reference_metadata)
  reference = reference_metadata_for(title, reference_metadata)
  output = {
    "creators" => Array(current["creators"]),
    "creator_source" => current["creator_source"].to_s,
    "creator_confidence" => current["creator_confidence"].to_s,
    "chronology_sort_year" => current["chronology_sort_year"],
    "chronology_label" => current["chronology_label"],
    "chronology_source" => current["chronology_source"].to_s,
    "chronology_confidence" => current["chronology_confidence"].to_s,
    "chronology_needs_review" => current["chronology_needs_review"]
  }

  if reference && !reference[:creators].to_a.empty?
    output["creators"] = reference[:creators]
    output["creator_source"] = reference[:source]
    output["creator_confidence"] = reference[:confidence] || "high"
  end

  chronology = chronology_override_for(title)
  if chronology
    output.merge!(chronology)
  elsif reference && reference[:sort_year]
    output["chronology_sort_year"] = reference[:sort_year].to_i
    output["chronology_label"] = reference[:date_label].to_s.empty? ? reference[:sort_year].to_s : reference[:date_label]
    output["chronology_source"] = reference[:source]
    output["chronology_confidence"] = reference[:confidence] || "high"
    output["chronology_needs_review"] = false
  end

  output
end

def apply_metadata_to_public_rows(rows, reference_metadata)
  changed = 0

  rows.each do |row|
    metadata = refreshed_metadata(row["title"], row, reference_metadata)
    before = row.values_at(*METADATA_COLUMNS)
    row["creators"] = metadata["creators"]
    row["creator_source"] = metadata["creator_source"]
    row["creator_confidence"] = metadata["creator_confidence"]
    row["chronology_sort_year"] = metadata["chronology_sort_year"]
    row["chronology_label"] = metadata["chronology_label"]
    row["chronology_source"] = metadata["chronology_source"]
    row["chronology_confidence"] = metadata["chronology_confidence"]
    row["chronology_needs_review"] = metadata["chronology_needs_review"]
    changed += 1 if before != row.values_at(*METADATA_COLUMNS)
  end

  changed
end

def apply_metadata_to_tsv(path, id_column, title_column, reference_metadata)
  return 0 unless File.exist?(path)

  rows = CSV.read(path, headers: true, col_sep: "\t")
  headers = rows.headers
  metadata_headers = headers & METADATA_COLUMNS
  changed = 0

  rows.each do |row|
    title = row[title_column]
    current = {
      "creators" => current_tsv_creators(row["creators"]),
      "creator_source" => row["creator_source"],
      "creator_confidence" => row["creator_confidence"],
      "chronology_sort_year" => row["chronology_sort_year"],
      "chronology_label" => row["chronology_label"],
      "chronology_source" => row["chronology_source"],
      "chronology_confidence" => row["chronology_confidence"],
      "chronology_needs_review" => row["chronology_needs_review"].to_s == "true"
    }
    metadata = refreshed_metadata(title, current, reference_metadata)
    before = metadata_headers.map { |header| row[header].to_s }

    row["creators"] = safe_tsv(metadata["creators"].join("; ")) if headers.include?("creators")
    row["creator_source"] = metadata["creator_source"] if headers.include?("creator_source")
    row["creator_confidence"] = metadata["creator_confidence"] if headers.include?("creator_confidence")
    row["chronology_sort_year"] = metadata["chronology_sort_year"] if headers.include?("chronology_sort_year")
    row["chronology_label"] = metadata["chronology_label"] if headers.include?("chronology_label")
    row["chronology_source"] = metadata["chronology_source"] if headers.include?("chronology_source")
    row["chronology_confidence"] = metadata["chronology_confidence"] if headers.include?("chronology_confidence")
    row["chronology_needs_review"] = metadata["chronology_needs_review"].to_s if headers.include?("chronology_needs_review")

    changed += 1 if before != metadata_headers.map { |header| row[header].to_s }
  end

  content = CSV.generate(col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row[header] } }
  end
  write_if_changed(path, content)
  changed
end

def update_summary(path, public_rows)
  return false unless File.exist?(path)

  summary = JSON.parse(File.read(path))
  summary["public_creator_source_counts"] = public_rows.group_by { |row| row["creator_source"] }.transform_values(&:length)
  summary["public_creator_confidence_counts"] = public_rows.group_by { |row| row["creator_confidence"] }.transform_values(&:length)
  summary["public_chronology_source_counts"] = public_rows.group_by { |row| row["chronology_source"] }.transform_values(&:length)
  summary["public_chronology_confidence_counts"] = public_rows.group_by { |row| row["chronology_confidence"] }.transform_values(&:length)
  summary["public_chronology_needs_review_count"] = public_rows.count { |row| row["chronology_needs_review"] }

  write_if_changed(path, JSON.pretty_generate(summary) + "\n")
end

def main
  options = parse_refresh_options
  reference_metadata = load_reference_metadata(ROOT)
  public_rows = YAML.load_file(options[:canon]) || []

  public_changed = apply_metadata_to_public_rows(public_rows, reference_metadata)
  canon_changed = public_changed.positive? && write_if_changed(options[:canon], public_rows.to_yaml)

  score_changed = apply_metadata_to_tsv(
    File.join(options[:out_dir], "quizbowl_lit_canon_scores.tsv"),
    "work_id",
    "canonical_title",
    reference_metadata
  )
  candidate_changed = apply_metadata_to_tsv(
    File.join(options[:out_dir], "quizbowl_lit_title_candidates.tsv"),
    "candidate_id",
    "canonical_title",
    reference_metadata
  )
  summary_changed = update_summary(File.join(options[:out_dir], "quizbowl_lit_summary.json"), public_rows)

  warn "Metadata refresh complete: public_rows_changed=#{public_changed}, canon_written=#{canon_changed}, score_rows_changed=#{score_changed}, candidate_rows_changed=#{candidate_changed}, summary_written=#{summary_changed}"
end

main if $PROGRAM_NAME == __FILE__
