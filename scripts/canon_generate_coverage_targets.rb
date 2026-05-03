#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

COVERAGE_MATRIX_PATH = File.join(TABLE_DIR, "canon_coverage_matrix.tsv")
COVERAGE_TARGETS_PATH = File.join(TABLE_DIR, "canon_coverage_targets.yml")

TARGET_AXES = %w[macro_region form_bucket period region_form].freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def target_id(axis, cell_key)
  "x044_target_#{axis}_#{cell_key.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_|_\z/, "")}"
end

def target_bonus(row)
  risk = row.fetch("risk_level")
  unmatched = row.fetch("source_item_unmatched_count").to_i
  no_evidence = row.fetch("no_evidence_selected_count").to_i
  selected = row.fetch("selected_count").to_i

  bonus = risk == "high" ? 0.30 : 0.10
  bonus += 0.10 if unmatched >= 100
  bonus += 0.10 if no_evidence >= 100
  bonus += 0.05 if selected < 50
  [bonus, 0.40].min.round(3)
end

def min_review_candidates(row)
  return 3 if row.fetch("risk_level") == "high"

  pressure = row.fetch("source_item_unmatched_count").to_i + row.fetch("no_evidence_selected_count").to_i
  pressure >= 500 ? 3 : pressure >= 100 ? 2 : 1
end

coverage_rows = read_tsv(COVERAGE_MATRIX_PATH)

targets = coverage_rows
          .select { |row| TARGET_AXES.include?(row.fetch("axis")) }
          .select { |row| %w[high medium].include?(row.fetch("risk_level")) }
          .map do |row|
            {
              "target_id" => target_id(row.fetch("axis"), row.fetch("cell_key")),
              "axis" => row.fetch("axis"),
              "cell_key" => row.fetch("cell_key"),
              "risk_level" => row.fetch("risk_level"),
              "selected_count" => row.fetch("selected_count").to_i,
              "candidate_count" => row.fetch("candidate_count").to_i,
              "source_item_unmatched_count" => row.fetch("source_item_unmatched_count").to_i,
              "evidence_count" => row.fetch("evidence_count").to_i,
              "no_evidence_selected_count" => row.fetch("no_evidence_selected_count").to_i,
              "target_type" => "review_priority",
              "target_direction" => "increase_or_verify_source_backed_coverage",
              "min_additional_review_candidates" => min_review_candidates(row),
              "bonus_if_add_matches" => target_bonus(row),
              "gate_status" => "coverage_bonus_only_no_replacement_authority",
              "rationale" => row.fetch("diagnostic_reason")
            }
          end
          .sort_by do |target|
            [
              target.fetch("risk_level") == "high" ? 0 : 1,
              -target.fetch("bonus_if_add_matches"),
              target.fetch("axis"),
              target.fetch("cell_key")
            ]
          end

payload = {
  "generated_on" => "2026-05-03",
  "status" => "generated_x044_from_x028_coverage_matrix",
  "target_count" => 3000,
  "coverage_axes" => %w[period_bucket macro_region subregion original_language literary_tradition form_bucket boundary_policy_id],
  "generation_method" => "Derived from X028 coverage matrix risk cells. Targets are review/scoring priors, not hard quotas.",
  "bonus_policy" => {
    "max_single_target_bonus" => 0.40,
    "max_score_coverage_scarcity_bonus" => 0.40,
    "replacement_authority" => "none",
    "notes" => "Coverage bonuses can rank ready candidates for review, but add/cut transactions still require separate replacement gates."
  },
  "targets" => targets,
  "known_current_limitations" => [
    "coverage_matrix_uses_inferred_taxonomy_for_many_incumbent_rows",
    "targets_are_review_priorities_not_locked_quota_claims",
    "source_debt_and_boundary_gates_still_control_candidate_eligibility"
  ]
}

FileUtils.mkdir_p(File.dirname(COVERAGE_TARGETS_PATH))
File.write(COVERAGE_TARGETS_PATH, payload.to_yaml)

puts "wrote #{COVERAGE_TARGETS_PATH.sub(ROOT + "/", "")} (#{targets.size} targets)"
