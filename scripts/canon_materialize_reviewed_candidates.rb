#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

MATCH_DECISIONS_PATH = File.join(TABLE_DIR, "canon_match_review_decisions.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
ALIASES_PATH = File.join(TABLE_DIR, "canon_aliases.tsv")
CREATORS_PATH = File.join(TABLE_DIR, "canon_creators.tsv")
WORK_CREATORS_PATH = File.join(TABLE_DIR, "canon_work_creators.tsv")

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def tsv_headers(path)
  CSV.open(path, col_sep: "\t", &:readline)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def normalized_text(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
end

def sort_title(title)
  normalized_text(title).sub(/\A(the|an|a) /, "")
end

def append_note(existing, addition)
  existing = existing.to_s
  return addition if existing.empty?
  return existing if existing.include?(addition)

  [existing, addition].join(" ")
end

def next_numeric_id(rows, field, prefix, width)
  max = rows.map { |row| row[field].to_s[/\A#{Regexp.escape(prefix)}(\d+)\z/, 1].to_i }.max || 0
  lambda do
    max += 1
    "#{prefix}#{max.to_s.rjust(width, "0")}"
  end
end

def source_date_metadata(source_item)
  raw_date = source_item.fetch("raw_date", "").to_s
  return ["date_pending_source_review", "0", "unknown"] if raw_date.empty?

  first_year = raw_date[/\d{3,4}/]
  precision =
    if raw_date.match?(/\A\d{4}\z/)
      "exact_year"
    elsif raw_date.include?("-")
      "range"
    else
      "unknown"
    end
  [raw_date, first_year || "0", precision]
end

def unit_type_for(source_item_id, item_scope)
  explicit = {
    "broadview_medieval_drama_hrosvitha_abraham" => "play_scope_pending",
    "e012_aap_harper_bury_me_free_land" => "poem",
    "e012_loa_sn_brown_narrative" => "slave_narrative",
    "e012_loa_sn_gronniosaw" => "slave_narrative",
    "e012_loa_sn_nat_turner" => "confession_narrative",
    "e012_naal4_v2_brooks_maud_martha" => "novel_scope_pending",
    "e012_naal4_v2_whitehead_nickel_boys" => "novel_selection_scope_pending",
    "philobiblon_biteca_texid_1112_curial" => "medieval_romance_identity_pending"
  }
  explicit.fetch(source_item_id, item_scope)
end

def selection_basis_for(item_scope)
  case item_scope
  when "poem"
    "Read the poem or a documented assigned anthology selection."
  when "complete_slave_narrative", "complete_confession_narrative"
    "Read the complete narrative unless a source-specific selection policy is later recorded."
  when "excerpt_or_selection_pending"
    "Do not treat as complete-work support until excerpt/selection scope is reviewed."
  when "work_identity"
    "Do not treat as canon-selection support until corroborating literary-history or anthology evidence exists."
  else
    "Candidate identity created from source-item review; completion scope pending."
  end
end

match_decisions = read_tsv(MATCH_DECISIONS_PATH)
source_items = read_tsv(SOURCE_ITEMS_PATH)
work_candidates = read_tsv(WORK_CANDIDATES_PATH)
aliases = read_tsv(ALIASES_PATH)
creators = read_tsv(CREATORS_PATH)
work_creators = read_tsv(WORK_CREATORS_PATH)

source_items_by_id = source_items.each_with_object({}) { |row, by_id| by_id[row.fetch("source_item_id")] = row }
work_candidates_by_id = work_candidates.each_with_object({}) { |row, by_id| by_id[row.fetch("work_id")] = row }
aliases_by_work_and_norm = aliases.to_h { |row| [[row.fetch("work_id"), row.fetch("normalized_alias")], true] }
creators_by_norm = creators.to_h { |row| [row.fetch("normalized_name"), row] }
work_creator_pairs = work_creators.to_h { |row| [[row.fetch("work_id"), row.fetch("creator_id")], true] }

next_creator_id = next_numeric_id(creators, "creator_id", "creator_", 5)
next_alias_id = next_numeric_id(aliases, "alias_id", "alias_", 5)

candidate_decisions = match_decisions.select { |row| row.fetch("proposed_work_id", "") != "" }
created_candidates = 0
updated_source_items = 0
created_aliases = 0
created_creators = 0
created_work_creators = 0

candidate_decisions.each do |decision|
  source_item = source_items_by_id.fetch(decision.fetch("source_item_id"))
  work_id = decision.fetch("proposed_work_id")
  date_label, sort_year, date_precision = source_date_metadata(source_item)
  item_scope = decision.fetch("item_scope")

  candidate_row = {
    "work_id" => work_id,
    "candidate_status" => "source_backed_candidate",
    "incumbent_path_id" => "",
    "incumbent_rank" => "",
    "canonical_title" => decision.fetch("proposed_title"),
    "sort_title" => sort_title(decision.fetch("proposed_title")),
    "original_title" => "",
    "creator_display" => decision.fetch("proposed_creator"),
    "date_label" => date_label,
    "sort_year" => sort_year,
    "date_precision" => date_precision,
    "macro_region" => "taxonomy_pending",
    "subregion" => "",
    "original_language" => "",
    "language_family" => "",
    "literary_tradition" => "taxonomy_pending",
    "period_bucket" => "taxonomy_pending",
    "form_bucket" => "taxonomy_pending",
    "unit_type" => unit_type_for(decision.fetch("source_item_id"), item_scope),
    "boundary_flags" => decision["decision"] == "create_source_backed_candidate_needs_corroboration" ? "corroboration_required" : "scope_pending",
    "included_as_literature" => "",
    "boundary_policy_id" => "",
    "boundary_note" => "Public inclusion blocked until evidence, duplicate, boundary, taxonomy, and scoring review.",
    "selection_basis" => selection_basis_for(item_scope),
    "edition_basis" => decision.fetch("source_id"),
    "completion_unit" => item_scope,
    "source_status" => "source_item_reviewed_candidate_pending_evidence",
    "review_status" => "provisional",
    "confidence" => "source_item_reviewed_unscored",
    "provisional_until" => "x017_evidence_x018_omission_review",
    "notes" => "Created from X013 match review decision #{decision.fetch("source_item_id")}; #{decision.fetch("rationale")}"
  }

  if work_candidates_by_id[work_id]
    candidate_row.each { |field, value| work_candidates_by_id[work_id][field] = value }
  else
    work_candidates << candidate_row
    work_candidates_by_id[work_id] = candidate_row
    created_candidates += 1
  end

  source_item["matched_work_id"] = work_id
  source_item["match_method"] = "x013_review_decision_candidate_creation"
  source_item["match_confidence"] = decision["decision"].include?("needs_corroboration") ? "0.70" : "0.95"
  source_item["match_status"] = "matched_candidate"
  source_item["notes"] = append_note(source_item["notes"], "X013 review decision materialized as candidate #{work_id}; not public-path integrated.")
  updated_source_items += 1

  creator_norm = normalized_text(decision.fetch("proposed_creator"))
  creator = creators_by_norm[creator_norm]
  unless creator
    creator = {
      "creator_id" => next_creator_id.call,
      "creator_display" => decision.fetch("proposed_creator"),
      "normalized_name" => creator_norm,
      "name_variants" => "",
      "life_dates" => "",
      "culture_or_tradition" => "",
      "notes" => "Created from X013 match review candidate materialization."
    }
    creators << creator
    creators_by_norm[creator_norm] = creator
    created_creators += 1
  end

  pair = [work_id, creator.fetch("creator_id")]
  unless work_creator_pairs[pair]
    work_creators << {
      "work_id" => work_id,
      "creator_id" => creator.fetch("creator_id"),
      "creator_role" => "author_or_tradition",
      "attribution_status" => "source_item_label",
      "notes" => "Created from X013 match review candidate materialization."
    }
    work_creator_pairs[pair] = true
    created_work_creators += 1
  end

  raw_title = source_item.fetch("raw_title")
  proposed_title = decision.fetch("proposed_title")
  raw_norm = normalized_text(raw_title)
  next if raw_norm.empty? || raw_norm == normalized_text(proposed_title) || aliases_by_work_and_norm[[work_id, raw_norm]]

  aliases << {
    "alias_id" => next_alias_id.call,
    "work_id" => work_id,
    "alias" => raw_title,
    "normalized_alias" => raw_norm,
    "alias_type" => "source_title",
    "language" => "",
    "script" => "",
    "source_id" => decision.fetch("source_id"),
    "confidence" => "source_reviewed",
    "notes" => "Created from X013 match review candidate materialization."
  }
  aliases_by_work_and_norm[[work_id, raw_norm]] = true
  created_aliases += 1
end

match_decisions.select { |row| row.fetch("decision") == "represented_by_existing_selection" }.each do |decision|
  source_item = source_items_by_id.fetch(decision.fetch("source_item_id"))
  source_item["matched_work_id"] = decision.fetch("matched_work_id")
  source_item["match_method"] = "x013_review_decision_represented_by_existing_selection"
  source_item["match_confidence"] = "0.90"
  source_item["match_status"] = "represented_by_selection"
  source_item["notes"] = append_note(source_item["notes"], "X013 review decision linked this source item to existing selection candidate #{decision.fetch("matched_work_id")}; final relation still pending.")
  updated_source_items += 1
end

write_tsv(WORK_CANDIDATES_PATH, tsv_headers(WORK_CANDIDATES_PATH), work_candidates)
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_items)
write_tsv(CREATORS_PATH, tsv_headers(CREATORS_PATH), creators)
write_tsv(WORK_CREATORS_PATH, tsv_headers(WORK_CREATORS_PATH), work_creators)
write_tsv(ALIASES_PATH, tsv_headers(ALIASES_PATH), aliases)

puts "created #{created_candidates} work candidates"
puts "updated #{updated_source_items} source items"
puts "created #{created_creators} creators"
puts "created #{created_work_creators} work-creator links"
puts "created #{created_aliases} aliases"
