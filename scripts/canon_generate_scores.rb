#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SCORING_INPUTS_PATH = File.join(TABLE_DIR, "canon_scoring_inputs.tsv")
SOURCE_WEIGHTS_PATH = File.join(TABLE_DIR, "canon_source_weights.yml")
SCORES_PATH = File.join(TABLE_DIR, "canon_scores.tsv")

HEADERS = %w[
  work_id source_weighted_score source_diversity_score region_specific_score
  language_specific_score anthology_score syllabus_score translation_edition_score
  reception_prize_score accepted_record_bonus packet_priority_score
  coverage_scarcity_bonus period_balance_bonus language_region_balance_bonus
  form_balance_bonus boundary_penalty generic_title_penalty date_uncertainty_penalty
  source_debt_penalty duplicate_overlap_penalty author_cluster_penalty recent_work_penalty
  incumbent_bonus final_score must_include must_exclude notes
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

def number(value)
  format("%.3f", value.round(3))
end

def support_family(evidence, source_class_key)
  [source_class_key, evidence.fetch("source_id")].join(":")
end

work_rows = read_tsv(WORK_CANDIDATES_PATH)
source_rows = read_tsv(SOURCE_REGISTRY_PATH)
source_item_rows = read_tsv(SOURCE_ITEMS_PATH)
evidence_rows = read_tsv(EVIDENCE_PATH)
scoring_inputs = read_tsv(SCORING_INPUTS_PATH)
source_weights = YAML.load_file(SOURCE_WEIGHTS_PATH)

works_by_id = work_rows.to_h { |row| [row.fetch("work_id"), row] }
sources_by_id = source_rows.to_h { |row| [row.fetch("source_id"), row] }
source_items_by_id = source_item_rows.to_h { |row| [row.fetch("source_item_id"), row] }
source_type_mapping = source_weights.fetch("source_type_mapping")
source_classes = source_weights.fetch("source_classes")
evidence_by_work = evidence_rows.group_by { |row| row.fetch("work_id") }

ready_inputs = scoring_inputs.select { |row| row.fetch("scoring_readiness") == "ready_for_score_computation" }

score_rows = ready_inputs.map do |input|
  work = works_by_id.fetch(input.fetch("work_id"))
  accepted = evidence_by_work.fetch(work.fetch("work_id"), []).select { |row| row.fetch("reviewer_status") == "accepted" }
  accepted_families = Set.new
  source_weighted_score = 0.0
  anthology_score = 0.0
  syllabus_score = 0.0
  translation_edition_score = 0.0
  reception_prize_score = 0.0

  accepted.each do |evidence|
    source = sources_by_id.fetch(evidence.fetch("source_id"))
    source_class_key = source_type_mapping.fetch(source.fetch("source_type"))
    source_class = source_classes.fetch(source_class_key)
    source_item = source_items_by_id[evidence.fetch("source_item_id", "")]
    item_weight = source_item ? source_item.fetch("evidence_weight", "").to_s : ""
    base_weight = item_weight.empty? ? source_class.fetch("default_weight").to_f : item_weight.to_f
    weight = evidence.fetch("evidence_type") == "representative_selection" ? base_weight * 0.5 : base_weight

    source_weighted_score += weight
    accepted_families << support_family(evidence, source_class_key)

    case source_class_key
    when "curated_teaching_anthology_complete_work", "field_or_national_anthology"
      anthology_score += weight
    when "university_core_required_reading"
      syllabus_score += weight
    when "authoritative_edition_or_translation_series"
      translation_edition_score += weight
    when "prize_or_reception_layer"
      reception_prize_score += weight
    end
  end

  source_diversity_score = [accepted_families.size * 0.25, 1.0].min
  packet_priority_score = work.fetch("candidate_status") == "source_backed_candidate" ? 0.25 : 0.0
  incumbent_bonus = work.fetch("candidate_status") == "incumbent_current_path" ? 0.5 : 0.0
  boundary_penalty = input.fetch("boundary_scope_penalty_input") == "1" ? 0.75 : 0.0
  date_uncertainty_penalty = input.fetch("date_uncertainty_penalty_input") == "1" ? 0.25 : 0.0
  source_debt_penalty = input.fetch("source_debt_penalty_input") == "1" ? 1.0 : 0.0
  duplicate_overlap_penalty = 0.0
  author_cluster_penalty = 0.0
  recent_work_penalty = work.fetch("sort_year").to_i >= 2000 ? 0.2 : 0.0

  positive = source_weighted_score + source_diversity_score + anthology_score + syllabus_score +
             translation_edition_score + reception_prize_score + packet_priority_score + incumbent_bonus
  negative = boundary_penalty + date_uncertainty_penalty + source_debt_penalty + duplicate_overlap_penalty +
             author_cluster_penalty + recent_work_penalty
  final_score = positive - negative

  {
    "work_id" => work.fetch("work_id"),
    "source_weighted_score" => number(source_weighted_score),
    "source_diversity_score" => number(source_diversity_score),
    "region_specific_score" => number(0),
    "language_specific_score" => number(0),
    "anthology_score" => number(anthology_score),
    "syllabus_score" => number(syllabus_score),
    "translation_edition_score" => number(translation_edition_score),
    "reception_prize_score" => number(reception_prize_score),
    "accepted_record_bonus" => number(0),
    "packet_priority_score" => number(packet_priority_score),
    "coverage_scarcity_bonus" => number(0),
    "period_balance_bonus" => number(0),
    "language_region_balance_bonus" => number(0),
    "form_balance_bonus" => number(0),
    "boundary_penalty" => number(boundary_penalty),
    "generic_title_penalty" => number(0),
    "date_uncertainty_penalty" => number(date_uncertainty_penalty),
    "source_debt_penalty" => number(source_debt_penalty),
    "duplicate_overlap_penalty" => number(duplicate_overlap_penalty),
    "author_cluster_penalty" => number(author_cluster_penalty),
    "recent_work_penalty" => number(recent_work_penalty),
    "incumbent_bonus" => number(incumbent_bonus),
    "final_score" => number(final_score),
    "must_include" => "false",
    "must_exclude" => "false",
    "notes" => "X042 provisional score for rows already ready_for_score_computation; no replacement action is implied."
  }
end

write_tsv(SCORES_PATH, HEADERS, score_rows)

puts "wrote #{SCORES_PATH.sub(ROOT + "/", "")} (#{score_rows.size} rows)"
