#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")

SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
RELATION_REVIEW_PATH = File.join(TABLE_DIR, "canon_relation_review_queue.tsv")

HEADERS = %w[
  source_item_id source_id raw_title raw_creator matched_work_id proposed_relation_type
  issue_type recommendation notes
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

rows = []

read_tsv(SOURCE_ITEMS_PATH).each do |item|
  source_item_id = item.fetch("source_item_id")
  source_id = item.fetch("source_id")
  raw_title = item.fetch("raw_title")
  raw_creator = item.fetch("raw_creator", "")
  matched_work_id = item.fetch("matched_work_id", "")
  evidence_type = item.fetch("evidence_type", "")
  match_status = item.fetch("match_status", "")
  notes = item.fetch("notes", "")
  supports = item.fetch("supports", "")
  notes_lc = "#{notes} #{supports}".downcase

  if match_status == "represented_by_selection" || evidence_type == "representative_selection"
    rows << {
      "source_item_id" => source_item_id,
      "source_id" => source_id,
      "raw_title" => raw_title,
      "raw_creator" => raw_creator,
      "matched_work_id" => matched_work_id,
      "proposed_relation_type" => "selection_from",
      "issue_type" => "selection_or_excerpt",
      "recommendation" => "confirm whether source item is excerpt, poem/story component, or representative selection",
      "notes" => "Do not score as complete-work inclusion until relation is reviewed. #{notes}"
    }
  end

  if notes_lc.match?(/contain|contained|collection|anthology|volume|part of|cycle/)
    rows << {
      "source_item_id" => source_item_id,
      "source_id" => source_id,
      "raw_title" => raw_title,
      "raw_creator" => raw_creator,
      "matched_work_id" => matched_work_id,
      "proposed_relation_type" => notes_lc.include?("cycle") ? "cycle_member" : "contained_in",
      "issue_type" => "contained_or_collection_case",
      "recommendation" => "review whether a work-level relation or separate candidate is needed",
      "notes" => "Generated from source item notes/supports. #{notes}"
    }
  end

  if match_status == "duplicate_or_variant" || notes_lc.match?(/variant|adaptation|duplicate|do not collapse|alias risk/)
    rows << {
      "source_item_id" => source_item_id,
      "source_id" => source_id,
      "raw_title" => raw_title,
      "raw_creator" => raw_creator,
      "matched_work_id" => matched_work_id,
      "proposed_relation_type" => notes_lc.include?("adaptation") ? "adaptation_of" : "variant_of",
      "issue_type" => "variant_duplicate_or_alias_risk",
      "recommendation" => "review before merging, rejecting, or creating a separate candidate",
      "notes" => "Generated from match status or notes. #{notes}"
    }
  end
end

rows.uniq! { |row| [row["source_item_id"], row["proposed_relation_type"], row["issue_type"]] }
rows.sort_by! { |row| [row["issue_type"], row["source_id"], row["source_item_id"], row["proposed_relation_type"]] }

write_tsv(RELATION_REVIEW_PATH, HEADERS, rows)

puts "wrote #{RELATION_REVIEW_PATH.sub(ROOT + "/", "")} (#{rows.size} rows)"
