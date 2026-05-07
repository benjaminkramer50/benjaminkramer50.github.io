#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "optparse"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DEFAULT_CANON = File.join(ROOT, "_data", "quizbowl_literature_canon.yml")
DEFAULT_TSV = File.join(ROOT, "_planning", "quizbowl_lit_canon", "quizbowl_lit_metadata_backlog.tsv")
DEFAULT_MD = File.join(ROOT, "_planning", "quizbowl_lit_canon", "quizbowl_lit_metadata_backlog.md")

HEADERS = %w[
  rank
  title
  total_question_count
  answerline_question_count
  clue_mention_question_count
  tier
  bucket
  creators
  creator_source
  creator_confidence
  chronology_label
  chronology_source
  work_form
  reading_unit
  era
  region_or_tradition
  dominant_quizbowl_track
  literature_track_count
  non_literature_track_count
  first_year
  last_year
  notes
].freeze

LEADING_FRAGMENT_WORD_RE = /\A(?:of|and|or|to|in|into|from|for|with|by|is|are|was|were)\b/i
TRAILING_FRAGMENT_WORD_RE = /\b(?:of|and|or|to|in|from|for|with|by)\z/i
STRANGE_CREATOR_RE = /(?:\d|~|:|;|\?|!|\bpoints?\b|\benglish\b|\bamerica\b|\bargentina\b|\bchinese\b)/i

def parse_options
  options = {
    canon: DEFAULT_CANON,
    tsv: DEFAULT_TSV,
    md: DEFAULT_MD
  }

  OptionParser.new do |parser|
    parser.on("--canon PATH") { |value| options[:canon] = value }
    parser.on("--tsv PATH") { |value| options[:tsv] = value }
    parser.on("--md PATH") { |value| options[:md] = value }
  end.parse!

  options
end

def track_counts(row)
  row["quizbowl_track_counts"].is_a?(Hash) ? row["quizbowl_track_counts"] : {}
end

def known_creator?(row)
  row["creator_source"].to_s != "unknown" && Array(row["creators"]).any?
end

def strange_creator?(row)
  Array(row["creators"]).join(" ").match?(STRANGE_CREATOR_RE)
end

def mostly_non_literature_context?(row)
  counts = track_counts(row)
  literature = counts["literature"].to_i
  non_literature = counts.reject { |track, _| track == "literature" }.values.sum(&:to_i)
  return false if literature >= non_literature

  row["dominant_quizbowl_track"].to_s != "literature" &&
    row["answerline_question_count"].to_i < 3 &&
    non_literature >= 40
end

def fragment_like_title?(row)
  title = row["title"].to_s.strip
  return true if title.match?(LEADING_FRAGMENT_WORD_RE)
  return true if title.match?(TRAILING_FRAGMENT_WORD_RE)
  return true if title.match?(/\A[a-z]/)
  return true if title.length < 5 && row["total_question_count"].to_i < 50

  false
end

def oral_or_composite?(row)
  [
    row["work_form"],
    row["reading_unit"],
    row["title"]
  ].join(" ").match?(/\b(?:scripture|myth|hymn|oral|epic|romance|cycle|saga|folklore|fairy)\b/i)
end

def bucket_for(row)
  return "likely_parser_fragment" if fragment_like_title?(row)
  return "creator_needs_audit" if strange_creator?(row)
  return "likely_non_literature_context" if mostly_non_literature_context?(row)
  return "oral_or_composite_date_review" if oral_or_composite?(row)
  return "needs_date_only" if known_creator?(row)

  "needs_creator_and_date"
end

def note_for(row, bucket)
  case bucket
  when "likely_parser_fragment"
    "Title shape suggests extracted phrase or truncated title; reject, alias, or rescue manually."
  when "creator_needs_audit"
    "Creator field appears to come from noisy answerline text; verify before using."
  when "likely_non_literature_context"
    "Dominant evidence is outside literature and answerline support is weak; check for leakage."
  when "oral_or_composite_date_review"
    "Likely oral, composite, mythic, scriptural, or cycle work; use conservative date label."
  when "needs_date_only"
    "Creator is present, but no chronology metadata is available."
  else
    "No reliable creator or chronology metadata yet."
  end
end

def backlog_rows(data)
  data
    .select { |row| row["review_status"] == "accepted_likely_work" && row["chronology_source"].to_s == "unknown" }
    .sort_by { |row| [-row["total_question_count"].to_i, row["rank"].to_i] }
    .map do |row|
      bucket = bucket_for(row)
      counts = track_counts(row)
      literature = counts["literature"].to_i
      non_literature = counts.reject { |track, _| track == "literature" }.values.sum(&:to_i)

      {
        "rank" => row["rank"],
        "title" => row["title"],
        "total_question_count" => row["total_question_count"],
        "answerline_question_count" => row["answerline_question_count"],
        "clue_mention_question_count" => row["clue_mention_question_count"],
        "tier" => row["tier"],
        "bucket" => bucket,
        "creators" => Array(row["creators"]).join("; "),
        "creator_source" => row["creator_source"],
        "creator_confidence" => row["creator_confidence"],
        "chronology_label" => row["chronology_label"],
        "chronology_source" => row["chronology_source"],
        "work_form" => row["work_form"],
        "reading_unit" => row["reading_unit"],
        "era" => row["era"],
        "region_or_tradition" => row["region_or_tradition"],
        "dominant_quizbowl_track" => row["dominant_quizbowl_track"],
        "literature_track_count" => literature,
        "non_literature_track_count" => non_literature,
        "first_year" => row["first_year"],
        "last_year" => row["last_year"],
        "notes" => note_for(row, bucket)
      }
    end
end

def write_tsv(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: HEADERS) do |csv|
    rows.each { |row| csv << HEADERS.map { |header| row.fetch(header, "") } }
  end
end

def write_markdown(path, rows)
  FileUtils.mkdir_p(File.dirname(path))
  bucket_counts = rows.group_by { |row| row["bucket"] }.transform_values(&:length).sort_by { |_, count| -count }
  top_rows = rows.first(40)

  lines = []
  lines << "# Quizbowl Literature Metadata Backlog"
  lines << ""
  lines << "Generated from `_data/quizbowl_literature_canon.yml`."
  lines << ""
  lines << "Scope: accepted public rows with `chronology_source: unknown`."
  lines << ""
  lines << "Total unresolved chronology rows: #{rows.length}"
  lines << ""
  lines << "## Buckets"
  lines << ""
  bucket_counts.each do |bucket, count|
    lines << "- `#{bucket}`: #{count}"
  end
  lines << ""
  lines << "## Highest-Salience Rows"
  lines << ""
  lines << "| Count | Rank | Bucket | Title | Creator Source | Creators | Notes |"
  lines << "| ---: | ---: | --- | --- | --- | --- | --- |"
  top_rows.each do |row|
    lines << "| #{row["total_question_count"]} | #{row["rank"]} | `#{row["bucket"]}` | #{row["title"]} | #{row["creator_source"]} | #{row["creators"]} | #{row["notes"]} |"
  end
  lines << ""
  lines << "## Operating Rule"
  lines << ""
  lines << "Resolve this file from the top down. Use Wikidata or another explicit metadata source where the match is exact. For oral, composite, and anonymous works, use a conservative `date_label` rather than forcing a false single year. Parser fragments should become rejects or aliases, not dated works."

  File.write(path, lines.join("\n") + "\n")
end

def main
  options = parse_options
  data = YAML.load_file(options[:canon])
  rows = backlog_rows(data)
  write_tsv(options[:tsv], rows)
  write_markdown(options[:md], rows)
  warn "Wrote #{rows.length} unresolved metadata rows to #{options[:tsv]}"
end

main if $PROGRAM_NAME == __FILE__
