#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
REVIEW_PATH = File.join(TABLE_DIR, "canon_selection_only_complete_work_support_review.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_048_x064_selection_only_complete_work_support.md")

DUNBAR_WORK_ID = "work_candidate_wave002_dunbar_lyrics_lowly_life"
HUGHES_WORK_ID = "work_candidate_bloom_reviewed_hughes_poems"

REVIEW_HEADERS = %w[
  review_id action_id work_id current_title creator review_decision support_status
  source_ids evidence_ids evidence_rows_written source_debt_effect next_action rationale
].freeze

REGISTRY_ROWS = [
  {
    "source_id" => "x064_encyclopedia_com_lyrics_lowly_life_reference",
    "source_title" => "Encyclopedia.com: Lyrics of Lowly Life",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Work-specific public reference entry for Paul Laurence Dunbar's Lyrics of Lowly Life",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopedia.com, Lyrics of Lowly Life, https://www.encyclopedia.com/history/culture-magazines/lyrics-lowly-life",
    "edition" => "online reference entry",
    "editors_or_authors" => "John Bird; American History Through Literature 1870-1920 / Gale",
    "publisher" => "Encyclopedia.com / Gale",
    "coverage_limits" => "Work-specific reference support, not anthology selection evidence",
    "extraction_method" => "Targeted X064 public reference review",
    "packet_ids" => "X064",
    "extraction_status" => "extracted",
    "notes" => "Used as complete-work support for Lyrics of Lowly Life; source explicitly identifies the 1896 book and its literary-historical importance."
  },
  {
    "source_id" => "x064_poetry_foundation_dunbar_reference",
    "source_title" => "Poetry Foundation: Paul Laurence Dunbar",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Poetry Foundation public biography with work-specific Lyrics of Lowly Life discussion",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Poetry Foundation, Paul Laurence Dunbar, https://www.poetryfoundation.org/poets/paul-laurence-dunbar",
    "edition" => "online poet biography",
    "editors_or_authors" => "Poetry Foundation",
    "publisher" => "Poetry Foundation",
    "coverage_limits" => "Author biography; supports work-specific collection identity and reception, not anthology selection",
    "extraction_method" => "Targeted X064 public reference review",
    "packet_ids" => "X064",
    "extraction_status" => "extracted",
    "notes" => "Used as independent public reference support for Lyrics of Lowly Life."
  }
].freeze

SOURCE_ITEM_ROWS = [
  {
    "source_id" => "x064_encyclopedia_com_lyrics_lowly_life_reference",
    "source_item_id" => "x064_encyclopedia_com_lyrics_lowly_life",
    "raw_title" => "Lyrics of Lowly Life",
    "raw_creator" => "Paul Laurence Dunbar",
    "raw_date" => "1896",
    "source_rank" => "",
    "source_section" => "Lyrics of Lowly Life entry",
    "source_url" => "https://www.encyclopedia.com/history/culture-magazines/lyrics-lowly-life",
    "source_citation" => "Encyclopedia.com, Lyrics of Lowly Life",
    "matched_work_id" => DUNBAR_WORK_ID,
    "match_method" => "x064_exact_complete_work_reference_match",
    "match_confidence" => "0.98",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_complete_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X064 accepted as exact complete-work support for the selected collection; not a public replacement decision."
  },
  {
    "source_id" => "x064_poetry_foundation_dunbar_reference",
    "source_item_id" => "x064_poetry_foundation_dunbar_lyrics_lowly_life",
    "raw_title" => "Lyrics of Lowly Life",
    "raw_creator" => "Paul Laurence Dunbar",
    "raw_date" => "1896",
    "source_rank" => "",
    "source_section" => "Paul Laurence Dunbar biography",
    "source_url" => "https://www.poetryfoundation.org/poets/paul-laurence-dunbar",
    "source_citation" => "Poetry Foundation, Paul Laurence Dunbar",
    "matched_work_id" => DUNBAR_WORK_ID,
    "match_method" => "x064_exact_complete_work_reference_match",
    "match_confidence" => "0.96",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_complete_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X064 accepted as independent complete-work support for the selected collection; not a public replacement decision."
  }
].freeze

EVIDENCE_ROWS = [
  {
    "evidence_id" => "x064_ev_encyclopedia_com_lyrics_lowly_life",
    "work_id" => DUNBAR_WORK_ID,
    "source_id" => "x064_encyclopedia_com_lyrics_lowly_life_reference",
    "source_item_id" => "x064_encyclopedia_com_lyrics_lowly_life",
    "evidence_type" => "inclusion",
    "evidence_strength" => "moderate",
    "page_or_section" => "Lyrics of Lowly Life entry",
    "quote_or_note" => "",
    "packet_id" => "X064",
    "supports_tier" => "",
    "supports_boundary_policy_id" => "",
    "reviewer_status" => "accepted",
    "notes" => "X064 accepted as work-specific reference support for Lyrics of Lowly Life; closes source debt only after independent-family rules pass."
  },
  {
    "evidence_id" => "x064_ev_poetry_foundation_dunbar_lyrics_lowly_life",
    "work_id" => DUNBAR_WORK_ID,
    "source_id" => "x064_poetry_foundation_dunbar_reference",
    "source_item_id" => "x064_poetry_foundation_dunbar_lyrics_lowly_life",
    "evidence_type" => "inclusion",
    "evidence_strength" => "moderate",
    "page_or_section" => "Paul Laurence Dunbar biography",
    "quote_or_note" => "",
    "packet_id" => "X064",
    "supports_tier" => "",
    "supports_boundary_policy_id" => "",
    "reviewer_status" => "accepted",
    "notes" => "X064 accepted as independent work-specific reference support for Lyrics of Lowly Life; not a cut approval."
  }
].freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def tsv_headers(path)
  CSV.open(path, col_sep: "\t", &:readline)
end

def write_tsv(path, headers, rows, sort_key: nil)
  FileUtils.mkdir_p(File.dirname(path))
  rows = rows.sort_by { |row| row.fetch(sort_key).to_s } if sort_key
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def upsert_rows(existing_rows, new_rows, key)
  by_key = existing_rows.each_with_object({}) { |row, memo| memo[row.fetch(key)] = row }
  new_rows.each { |row| by_key[row.fetch(key)] = row }
  by_key.values
end

def action_for(actions, work_id)
  actions.find { |row| row.fetch("cut_work_id") == work_id }
end

def previous_review_action_id(review_rows, work_id)
  review_rows.find { |row| row.fetch("work_id") == work_id }&.fetch("action_id").to_s
end

def write_report(path, review_rows)
  FileUtils.mkdir_p(File.dirname(path))
  File.open(path, "w") do |file|
    file.puts "# X064 Selection-Only Complete-Work Support"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X064 processes the two current `accepted_selection_only_complete_work_source_needed` cut-side rows. It accepts complete-work support only where the source matches the selected work's current title/scope."
    file.puts
    file.puts "## Decisions"
    file.puts
    file.puts "| Work | Decision | Evidence rows | Source-debt effect | Next action |"
    file.puts "|---|---|---:|---|---|"
    review_rows.each do |row|
      file.puts "| #{row.fetch("current_title")} | `#{row.fetch("review_decision")}` | #{row.fetch("evidence_rows_written")} | `#{row.fetch("source_debt_effect")}` | `#{row.fetch("next_action")}` |"
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "`Lyrics of Lowly Life` receives two accepted independent public-reference inclusion rows and can be refreshed through source-debt rules. `The Weary Blues and Selected Poems` remains blocked because the strongest public sources support `The Weary Blues` as a complete book, not the current composite selected-work label."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

registry_rows = read_tsv(SOURCE_REGISTRY_PATH)
source_item_rows = read_tsv(SOURCE_ITEMS_PATH)
evidence_rows = read_tsv(EVIDENCE_PATH)
actions = read_tsv(ACTION_QUEUE_PATH)
existing_review_rows = File.exist?(REVIEW_PATH) ? read_tsv(REVIEW_PATH) : []

dunbar_action = action_for(actions, DUNBAR_WORK_ID)
hughes_action = action_for(actions, HUGHES_WORK_ID)
dunbar_action_id = dunbar_action&.fetch("action_id").to_s
if dunbar_action_id.empty?
  previous_action_id = previous_review_action_id(existing_review_rows, DUNBAR_WORK_ID).sub(/\Apre_x064_/, "")
  dunbar_action_id = previous_action_id.empty? ? "" : "pre_x064_#{previous_action_id}"
end
hughes_action_id = hughes_action&.fetch("action_id").to_s
hughes_action_id = previous_review_action_id(existing_review_rows, HUGHES_WORK_ID) if hughes_action_id.empty?
raise "Missing current or previously reviewed Dunbar action" if dunbar_action_id.empty?
raise "Missing current Hughes action" unless hughes_action

registry_rows = upsert_rows(registry_rows, REGISTRY_ROWS, "source_id")
source_item_rows = upsert_rows(source_item_rows, SOURCE_ITEM_ROWS, "source_item_id")
evidence_rows = upsert_rows(evidence_rows, EVIDENCE_ROWS, "evidence_id")

review_rows = [
  {
    "review_id" => "x064_selection_only_support_0001",
    "action_id" => dunbar_action_id,
    "work_id" => DUNBAR_WORK_ID,
    "current_title" => "Lyrics of Lowly Life",
    "creator" => "Paul Laurence Dunbar",
    "review_decision" => "accept_complete_work_support",
    "support_status" => "exact_current_title_supported",
    "source_ids" => REGISTRY_ROWS.map { |row| row.fetch("source_id") }.join(";"),
    "evidence_ids" => EVIDENCE_ROWS.map { |row| row.fetch("evidence_id") }.join(";"),
    "evidence_rows_written" => "2",
    "source_debt_effect" => dunbar_action.nil? ? "closed_after_source_debt_refresh" : "expected_to_close_after_source_debt_refresh",
    "next_action" => dunbar_action.nil? ? "removed_from_current_cut_side_action_queue_after_refresh" : "refresh_source_debt_scoring_and_cut_queues",
    "rationale" => "Two independent public reference sources support Lyrics of Lowly Life as a work-specific Dunbar collection."
  },
  {
    "review_id" => "x064_selection_only_support_0002",
    "action_id" => hughes_action_id,
    "work_id" => HUGHES_WORK_ID,
    "current_title" => "The Weary Blues and Selected Poems",
    "creator" => "Langston Hughes",
    "review_decision" => "hold_for_title_scope_correction",
    "support_status" => "sources_support_alias_not_current_composite_title",
    "source_ids" => "poets_org_weary_blues_book_page;poets_org_weary_blues_essay;britannica_weary_blues_entry",
    "evidence_ids" => "",
    "evidence_rows_written" => "0",
    "source_debt_effect" => "remains_open_selection_only",
    "next_action" => "decide_title_scope_before_complete_work_evidence",
    "rationale" => "Public sources support The Weary Blues as Hughes's 1926 first book/debut collection, but the current selected-work label combines that book with a generic selected-poems scope."
  }
]

write_tsv(SOURCE_REGISTRY_PATH, tsv_headers(SOURCE_REGISTRY_PATH), registry_rows, sort_key: "source_id")
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_item_rows)
write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_rows)
write_tsv(REVIEW_PATH, REVIEW_HEADERS, review_rows)
write_report(REPORT_PATH, review_rows)

puts "accepted #{EVIDENCE_ROWS.size} complete-work support evidence rows; held Hughes title/scope row"
