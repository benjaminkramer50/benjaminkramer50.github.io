#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")

TRIAGE_FILE = File.join(TABLE_DIR, "canon_red_cell_triage.tsv")
PACKET_STATUS_FILE = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_FILE = File.join(MANIFEST_DIR, "canon_build_manifest.yml")

DECISIONS_FILE = File.join(TABLE_DIR, "canon_red_cell_review_decisions.tsv")
REPORT_FILE = File.join(REPORT_DIR, "x_batch_014_x030_title_route_review.md")

PACKET_ID = "X030"

DECISION_HEADERS = %w[
  decision_id triage_id queue_id diagnostic_id subject triage_class review_decision target_work_id
  confidence rationale next_action
].freeze

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

MANUAL_DECISIONS = {
  "x028_source_cluster_invitation_to_voyage" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_fleurs_du_mal",
    confidence: "medium",
    rationale: "Repeated anthology title is a Baudelaire poem/selection; route through Les Fleurs du mal rather than create a separate work by default.",
    next_action: "record_selection_or_alias_relation_to_current_collection"
  },
  "x028_source_cluster_kubla_khan" => {
    review_decision: "variant_alias_to_current_work",
    target_work_id: "work_candidate_bloom_late_032_literature_bloom_democratic_age_reviewed_0482_christabel_kubla_khan_a_vision_in_a_dream_the_pa",
    confidence: "medium",
    rationale: "Same-creator current candidate already represents the Coleridge Kubla Khan selection cluster.",
    next_action: "add_alias_or_match_review_decision"
  },
  "x028_source_cluster_agamemnon" => {
    review_decision: "contained_in_current_work",
    target_work_id: "work_canon_oresteia",
    confidence: "high",
    rationale: "Agamemnon is a play within Aeschylus' Oresteia, which is already in the current path.",
    next_action: "record_contained_work_scope_not_new_omission"
  },
  "x028_source_cluster_fuenteovejuna" => {
    review_decision: "orthographic_alias_to_current_work",
    target_work_id: "work_candidate_bloom_fuente_ovejuna",
    confidence: "high",
    rationale: "Fuenteovejuna is an orthographic variant of the current-path Fuente Ovejuna row.",
    next_action: "add_alias_or_match_review_decision"
  },
  "x028_source_cluster_holy_sonnets" => {
    review_decision: "new_or_collection_candidate_review",
    target_work_id: "",
    confidence: "medium",
    rationale: "John Donne's Holy Sonnets may warrant collection-level candidate review; do not treat as an individual poem-only row.",
    next_action: "review_collection_boundary_and_existing_donne_coverage"
  },
  "x028_source_cluster_ithaka" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_euro_under_lit_cavafy_poems",
    confidence: "medium",
    rationale: "Ithaka is a Cavafy poem; current path already includes Cavafy Collected Poems.",
    next_action: "record_selection_or_alias_relation_to_current_collection"
  },
  "x028_source_cluster_o_captain_my_captain" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_leaves_of_grass",
    confidence: "medium",
    rationale: "Whitman poem selection should route through the current Whitman poetry collection unless later review chooses individual-poem granularity.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_ode_on_grecian_urn" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_bloom_keats_poems",
    confidence: "medium",
    rationale: "Keats ode selection should route through the current Keats selected-poems row.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_ode_to_nightingale" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_bloom_keats_poems",
    confidence: "medium",
    rationale: "Keats ode selection should route through the current Keats selected-poems row.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_of_cannibals" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_essays_montaigne",
    confidence: "high",
    rationale: "Of Cannibals is an essay within Montaigne's Essays, which is already selected.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_of_power_of_imagination" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_essays_montaigne",
    confidence: "high",
    rationale: "Of the Power of the Imagination is an essay within Montaigne's Essays, which is already selected.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_prologue_in_heaven" => {
    review_decision: "contained_in_current_work",
    target_work_id: "work_candidate_faust_goethe",
    confidence: "medium",
    rationale: "Prologue in Heaven is a Faust component/excerpt and should route through Goethe's Faust.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_song_of_lasting_regret" => {
    review_decision: "variant_alias_to_current_work",
    target_work_id: "work_candidate_eastasia_lit_song_everlasting_sorrow",
    confidence: "medium",
    rationale: "Song of Lasting Regret is a common translated title for Bai Juyi's Song of Everlasting Sorrow.",
    next_action: "add_alias_or_match_review_decision"
  },
  "x028_source_cluster_tales_of_heike" => {
    review_decision: "variant_alias_to_current_work",
    target_work_id: "work_candidate_tale_of_heike",
    confidence: "high",
    rationale: "Pluralized/anthology title variant maps to The Tale of the Heike.",
    next_action: "add_alias_or_match_review_decision"
  },
  "x028_source_cluster_dead" => {
    review_decision: "existing_current_match_needs_creator_disambiguation",
    target_work_id: "work_candidate_bloom_reviewed_dubliners",
    confidence: "medium",
    rationale: "The Dead is represented through Dubliners for Joyce, but same-title current rows require source-creator disambiguation before automatic matching.",
    next_action: "split_by_creator_then_match_joyce_rows_to_dubliners"
  },
  "x028_source_cluster_ramayana_of_valmiki" => {
    review_decision: "variant_alias_to_current_work",
    target_work_id: "work_canon_ramayana",
    confidence: "high",
    rationale: "The Ramayana of Valmiki is a title/attribution variant of the current Ramayana row.",
    next_action: "add_alias_or_match_review_decision"
  },
  "x028_source_cluster_general_prologue" => {
    review_decision: "contained_in_current_work",
    target_work_id: "work_canon_canterbury_tales",
    confidence: "high",
    rationale: "The General Prologue is a Canterbury Tales component, not a separate canon omission under current granularity.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_prince" => {
    review_decision: "new_omission_candidate_boundary_review",
    target_work_id: "",
    confidence: "medium",
    rationale: "Machiavelli's The Prince is source-backed and not currently selected; boundary review must decide political-philosophical prose as literature.",
    next_action: "create_candidate_after_boundary_policy_review"
  },
  "x028_source_cluster_tyger" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_bloom_reviewed_songs_innocence_experience",
    confidence: "high",
    rationale: "The Tyger is contained in Songs of Innocence and of Experience, already selected.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_wife_of_bath_s_prologue" => {
    review_decision: "contained_in_current_work",
    target_work_id: "work_canon_canterbury_tales",
    confidence: "high",
    rationale: "The Wife of Bath's Prologue is a Canterbury Tales component.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_wife_of_bath_s_tale" => {
    review_decision: "contained_in_current_work",
    target_work_id: "work_canon_canterbury_tales",
    confidence: "high",
    rationale: "The Wife of Bath's Tale is a Canterbury Tales component.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_to_autumn" => {
    review_decision: "contained_in_current_collection",
    target_work_id: "work_candidate_bloom_keats_poems",
    confidence: "medium",
    rationale: "Keats poem selection should route through the current Keats selected-poems row.",
    next_action: "record_selection_scope_not_new_work"
  },
  "x028_source_cluster_yellow_woman" => {
    review_decision: "new_omission_candidate_short_story_review",
    target_work_id: "",
    confidence: "medium",
    rationale: "Leslie Marmon Silko is represented by novels, but this source-backed story title is not an obvious alias of a selected work.",
    next_action: "review_short_story_granularity_and_create_candidate_if_policy_allows"
  },
  "x028_source_cluster_zaabalawi" => {
    review_decision: "new_omission_candidate_short_story_review",
    target_work_id: "",
    confidence: "medium",
    rationale: "Mahfouz is represented by novels, but this source-backed story title is not an obvious alias of a selected work.",
    next_action: "review_short_story_granularity_and_create_candidate_if_policy_allows"
  },
  "x028_source_cluster_from_life_of_sensuous_woman" => {
    review_decision: "variant_alias_to_current_work",
    target_work_id: "work_candidate_global_lit_life_amorous_woman",
    confidence: "high",
    rationale: "Life of a Sensuous Woman is a translated-title variant/excerpt title for the current Life of an Amorous Woman row.",
    next_action: "add_alias_or_match_review_decision"
  }
}.freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

triage_rows = read_tsv(TRIAGE_FILE)
decision_rows = []

triage_rows.each do |row|
  manual = MANUAL_DECISIONS[row.fetch("diagnostic_id")]
  next unless manual

  decision_rows << {
    "decision_id" => "x030_decision_#{(decision_rows.size + 1).to_s.rjust(4, "0")}",
    "triage_id" => row.fetch("triage_id"),
    "queue_id" => row.fetch("queue_id"),
    "diagnostic_id" => row.fetch("diagnostic_id"),
    "subject" => row.fetch("subject"),
    "triage_class" => row.fetch("triage_class"),
    "review_decision" => manual.fetch(:review_decision),
    "target_work_id" => manual.fetch(:target_work_id),
    "confidence" => manual.fetch(:confidence),
    "rationale" => manual.fetch(:rationale),
    "next_action" => manual.fetch(:next_action)
  }
end

write_tsv(DECISIONS_FILE, DECISION_HEADERS, decision_rows)

decision_counts = decision_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("review_decision")] += 1 }
next_action_counts = decision_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("next_action")] += 1 }

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row.fetch("packet_id") == PACKET_ID }
packet_rows << {
  "packet_id" => PACKET_ID,
  "packet_family" => "X",
  "scope" => "manual route decisions for X029 title-level rows",
  "status" => "review_decisions_recorded",
  "gate" => "relation_or_candidate_writes_required",
  "output_artifact" => "_planning/canon_build/tables/canon_red_cell_review_decisions.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_014_x030_title_route_review.md",
  "next_action" => "write_alias_selection_or_omission_candidate_updates_from_x030_decisions",
  "notes" => "#{decision_rows.size} title-route decisions recorded; public canon unchanged"
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows.sort_by { |row| row.fetch("packet_id") })

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x030_title_route_review_recorded"
manifest["artifacts"]["red_cell_review_decisions"] = "generated_x030"
manifest["red_cell_review_x030"] = {
  "decision_rows" => decision_rows.size,
  "decision_counts" => decision_counts.sort.to_h,
  "next_action_counts" => next_action_counts.sort.to_h,
  "direct_replacements" => 0
}
File.write(MANIFEST_FILE, manifest.to_yaml)

report = <<~MARKDOWN
  # X Batch 14 Report: X030 Title-Route Review

  Date: 2026-05-03

  Status: title-route decisions recorded; public canon unchanged.

  ## Summary

  X030 manually routes the clearest X029 title-level rows. This prevents already-covered components and title variants from being mistaken for new omissions.

  | Review decision | Rows |
  |---|---:|
  #{decision_counts.sort.map { |decision, count| "| #{decision} | #{count} |" }.join("\n")}

  ## Decisions

  | Subject | Decision | Target | Next action |
  |---|---|---|---|
  #{decision_rows.map { |row| "| #{row.fetch("subject").gsub("|", "/")} | #{row.fetch("review_decision")} | #{row.fetch("target_work_id")} | #{row.fetch("next_action")} |" }.join("\n")}

  ## Interpretation

  These are route decisions, not public-list transactions. Alias, contained-work, and selection decisions should be written into match/relation review tables before any scoring or replacement packet. New omission candidates still need source-scope, boundary, duplicate, chronology, and source-debt gates.

  ## Next Actions

  1. Write alias/match decisions for clear variants such as Fuenteovejuna, Ramayana of Valmiki, Tales of Heike, and Life of a Sensuous Woman.
  2. Write contained/selection scope decisions for Canterbury, Montaigne, Keats, Blake, Whitman, Cavafy, Baudelaire, and Oresteia component rows.
  3. Open candidate-boundary review for The Prince, Yellow Woman, Zaabalawi, and unresolved collection-level rows such as Holy Sonnets.
MARKDOWN
File.write(REPORT_FILE, report)

puts "wrote #{DECISIONS_FILE.sub(ROOT + "/", "")} (#{decision_rows.size} rows)"
puts "wrote #{REPORT_FILE.sub(ROOT + "/", "")}"
