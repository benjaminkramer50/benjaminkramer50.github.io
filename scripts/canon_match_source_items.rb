#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "set"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")

SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
WORKS_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
CREATORS_PATH = File.join(TABLE_DIR, "canon_creators.tsv")
ALIASES_PATH = File.join(TABLE_DIR, "canon_aliases.tsv")
MATCH_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_match_candidates.tsv")
MATCH_REVIEW_PATH = File.join(TABLE_DIR, "canon_match_review_queue.tsv")

MATCH_CANDIDATE_HEADERS = %w[
  source_item_id source_id raw_title raw_creator candidate_work_id candidate_title
  candidate_creator match_rule title_match creator_match confidence recommendation notes
].freeze

MATCH_REVIEW_HEADERS = %w[
  source_item_id source_id raw_title raw_creator issue_type candidate_work_ids
  recommendation notes
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

def normalize_text(value)
  value.to_s
       .downcase
       .gsub(/&/, " and ")
       .gsub(/[[:punct:]]+/, " ")
       .gsub(/\b(the|a|an|le|la|les|el|los|las|il|lo|gli|i|der|die|das)\b/, " ")
       .gsub(/\s+/, " ")
       .strip
end

def normalize_creator(value)
  normalize_text(value)
    .gsub(/\b(anonymous|unknown|desconegut|traditional|tradition|various|selected)\b/, " ")
    .gsub(/\s+/, " ")
    .strip
end

def source_title_norms(value)
  raw = value.to_s
  stripped_from = raw.sub(/\A\s*from\s+/i, "")
  [
    [normalize_text(raw), nil],
    [normalize_text(stripped_from), "from_prefix_stripped"]
  ].reject { |normalized, _suffix| normalized.empty? }
   .uniq { |normalized, _suffix| normalized }
end

def creator_parts(value, variant_index)
  normalize_creator(value)
    .split(/\s+\|\s+|;| and /)
    .map(&:strip)
    .reject(&:empty?)
    .flat_map { |part| [part, *variant_index.fetch(part, Set.new).to_a] }
    .uniq
end

def creator_variant_index(creators)
  creators.each_with_object(Hash.new { |hash, key| hash[key] = Set.new }) do |creator, index|
    names = [
      creator["creator_display"],
      creator["normalized_name"],
      *creator.fetch("name_variants", "").to_s.split(";")
    ].map { |name| normalize_creator(name) }.reject(&:empty?).uniq

    names.each do |name|
      (names - [name]).each { |variant| index[name] << variant }
    end
  end
end

def creator_matches?(source_creator, candidate_creator, variant_index)
  source = normalize_creator(source_creator)
  candidate = normalize_creator(candidate_creator)
  return "unknown" if source.empty? || candidate.empty?

  source_parts = creator_parts(source_creator, variant_index)
  candidate_parts = creator_parts(candidate_creator, variant_index)
  return "no" if source_parts.empty? || candidate_parts.empty?

  source_parts.any? do |source_part|
    candidate_parts.any? do |candidate_part|
      source_part == candidate_part ||
        source_part.include?(candidate_part) ||
        candidate_part.include?(source_part)
    end
  end ? "yes" : "no"
end

works = read_tsv(WORKS_PATH)
creators = read_tsv(CREATORS_PATH)
aliases = read_tsv(ALIASES_PATH)
source_items = read_tsv(SOURCE_ITEMS_PATH)
creator_variants = creator_variant_index(creators)

works_by_id = works.each_with_object({}) { |row, by_id| by_id[row.fetch("work_id")] = row }
title_index = Hash.new { |hash, key| hash[key] = [] }
alias_index = Hash.new { |hash, key| hash[key] = [] }

works.each do |work|
  [work["canonical_title"], work["sort_title"], work["original_title"]].each do |title|
    normalized = normalize_text(title)
    title_index[normalized] << work unless normalized.empty?
  end
end

aliases.each do |alias_row|
  normalized = normalize_text(alias_row["alias"])
  work = works_by_id[alias_row["work_id"]]
  alias_index[normalized] << work if work && !normalized.empty?
end

match_rows = []
review_rows = []

source_items.each do |item|
  source_item_id = item.fetch("source_item_id")
  source_id = item.fetch("source_id")
  raw_title = item.fetch("raw_title")
  raw_creator = item.fetch("raw_creator", "")
  title_norms = source_title_norms(raw_title)
  match_status = item.fetch("match_status", "")
  existing_work_id = item.fetch("matched_work_id", "")

  if !existing_work_id.empty? && works_by_id[existing_work_id]
    work = works_by_id[existing_work_id]
    match_rows << {
      "source_item_id" => source_item_id,
      "source_id" => source_id,
      "raw_title" => raw_title,
      "raw_creator" => raw_creator,
      "candidate_work_id" => existing_work_id,
      "candidate_title" => work.fetch("canonical_title"),
      "candidate_creator" => work.fetch("creator_display"),
      "match_rule" => "preexisting_#{match_status}",
      "title_match" => "preexisting",
      "creator_match" => creator_matches?(raw_creator, work.fetch("creator_display"), creator_variants),
      "confidence" => item.fetch("match_confidence", "").empty? ? "1.00" : item.fetch("match_confidence"),
      "recommendation" => "accepted_existing_match",
      "notes" => "Existing source_items.matched_work_id retained."
    }
    next
  end

  candidates = []
  title_norms.each do |title_norm, suffix|
    title_index[title_norm].each do |work|
      rule = suffix ? "exact_normalized_title_#{suffix}" : "exact_normalized_title"
      candidates << [work, rule]
    end
    alias_index[title_norm].each do |work|
      rule = suffix ? "exact_alias_#{suffix}" : "exact_alias"
      candidates << [work, rule]
    end
  end
  candidates.uniq! { |work, rule| [work["work_id"], rule] }

  if candidates.empty?
    review_rows << {
      "source_item_id" => source_item_id,
      "source_id" => source_id,
      "raw_title" => raw_title,
      "raw_creator" => raw_creator,
      "issue_type" => "no_candidate_match",
      "candidate_work_ids" => "",
      "recommendation" => "create_candidate_or_mark_out_of_scope_after_source_review",
      "notes" => "No exact normalized title or alias match found."
    }
    next
  end

  candidates.each do |work, rule|
    creator_match = creator_matches?(raw_creator, work.fetch("creator_display"), creator_variants)
    confidence =
      if creator_match == "yes" && rule == "exact_normalized_title"
        "0.97"
      elsif creator_match == "yes"
        "0.94"
      elsif creator_match == "unknown"
        "0.82"
      else
        "0.70"
      end
    recommendation =
      if creator_match == "yes" && candidates.size == 1
        "candidate_auto_match_after_review"
      else
        "needs_match_review"
      end

    match_rows << {
      "source_item_id" => source_item_id,
      "source_id" => source_id,
      "raw_title" => raw_title,
      "raw_creator" => raw_creator,
      "candidate_work_id" => work.fetch("work_id"),
      "candidate_title" => work.fetch("canonical_title"),
      "candidate_creator" => work.fetch("creator_display"),
      "match_rule" => rule,
      "title_match" => "exact",
      "creator_match" => creator_match,
      "confidence" => confidence,
      "recommendation" => recommendation,
      "notes" => "Generated by exact normalized title/alias matching."
    }
  end

  review_rows << {
    "source_item_id" => source_item_id,
    "source_id" => source_id,
    "raw_title" => raw_title,
    "raw_creator" => raw_creator,
    "issue_type" => candidates.size == 1 ? "candidate_match_needs_review" : "ambiguous_candidate_match",
    "candidate_work_ids" => candidates.map { |work, _rule| work.fetch("work_id") }.uniq.join(";"),
    "recommendation" => "review_creator_date_scope_before_updating_source_item",
    "notes" => "Generated candidate match; do not treat as true omission or accepted match yet."
  }
end

match_rows.sort_by! { |row| [row["source_id"], row["source_item_id"], row["candidate_work_id"]] }
review_rows.sort_by! { |row| [row["issue_type"], row["source_id"], row["source_item_id"]] }

write_tsv(MATCH_CANDIDATES_PATH, MATCH_CANDIDATE_HEADERS, match_rows)
write_tsv(MATCH_REVIEW_PATH, MATCH_REVIEW_HEADERS, review_rows)

puts "wrote #{MATCH_CANDIDATES_PATH.sub(ROOT + "/", "")} (#{match_rows.size} rows)"
puts "wrote #{MATCH_REVIEW_PATH.sub(ROOT + "/", "")} (#{review_rows.size} rows)"
