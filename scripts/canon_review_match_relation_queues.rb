#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

MATCH_REVIEW_PATH = File.join(TABLE_DIR, "canon_match_review_queue.tsv")
RELATION_REVIEW_PATH = File.join(TABLE_DIR, "canon_relation_review_queue.tsv")
MATCH_DECISIONS_PATH = File.join(TABLE_DIR, "canon_match_review_decisions.tsv")
RELATION_DECISIONS_PATH = File.join(TABLE_DIR, "canon_relation_review_decisions.tsv")

MATCH_DECISION_HEADERS = %w[
  source_item_id source_id raw_title raw_creator decision matched_work_id proposed_work_id
  proposed_title proposed_creator item_scope evidence_role next_action reviewer_status rationale
].freeze

RELATION_DECISION_HEADERS = %w[
  source_item_id source_id raw_title raw_creator matched_work_id proposed_relation_type
  issue_type decision target_work_id item_scope next_action reviewer_status rationale
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

match_overrides = {
  "broadview_medieval_r3_exeter_wanderer" => {
    decision: "represented_by_existing_selection",
    matched_work_id: "work_candidate_mandatory_old_english_elegies",
    item_scope: "poem_component",
    evidence_role: "representative_selection",
    next_action: "add_alias_or_selection_relation_after_relation_review",
    rationale: "The current path has Old English Elegies: Selected Poems; treat The Wanderer as a component/selection, not a true omission."
  },
  "broadview_medieval_drama_hrosvitha_abraham" => {
    decision: "create_source_backed_candidate",
    proposed_work_id: "work_candidate_source_broadview_hrotsvitha_abraham",
    proposed_title: "Abraham",
    proposed_creator: "Hrotsvitha of Gandersheim",
    item_scope: "complete_play_or_anthology_selection_pending",
    evidence_role: "field_anthology_support",
    next_action: "create_candidate_row_then_review_boundary_and_score",
    rationale: "No current Hrotsvitha/Abraham work candidate exists; Broadview medieval drama TOC is enough for a source-backed candidate, not public inclusion."
  },
  "e012_aap_harper_bury_me_free_land" => {
    decision: "create_source_backed_candidate",
    proposed_work_id: "work_candidate_source_aap_harper_bury_me_free_land",
    proposed_title: "Bury Me in a Free Land",
    proposed_creator: "Frances Ellen Watkins Harper",
    item_scope: "poem",
    evidence_role: "field_anthology_support",
    next_action: "create_candidate_or_collection_selection_basis_after_poetry_policy_review",
    rationale: "Do not collapse into Iola Leroy; this is a poem-level African American poetry source item."
  },
  "e012_loa_sn_brown_narrative" => {
    decision: "create_source_backed_candidate",
    proposed_work_id: "work_candidate_source_loa_brown_narrative",
    proposed_title: "Narrative of William W. Brown, A Fugitive Slave. Written by Himself",
    proposed_creator: "William Wells Brown",
    item_scope: "complete_slave_narrative",
    evidence_role: "authoritative_collection_support",
    next_action: "create_candidate_row_and_alias_short_title",
    rationale: "Separate slave narrative from Clotel; source note explicitly says not to collapse."
  },
  "e012_loa_sn_gronniosaw" => {
    decision: "create_source_backed_candidate",
    proposed_work_id: "work_candidate_source_loa_gronniosaw_narrative",
    proposed_title: "Narrative of James Albert Ukawsaw Gronniosaw",
    proposed_creator: "James Albert Ukawsaw Gronniosaw",
    item_scope: "complete_slave_narrative",
    evidence_role: "authoritative_collection_support",
    next_action: "create_candidate_row_and_full_title_alias",
    rationale: "LOA Slave Narratives gives a complete-work source item and no current work candidate was found."
  },
  "e012_loa_sn_nat_turner" => {
    decision: "create_source_backed_candidate",
    proposed_work_id: "work_candidate_source_loa_nat_turner_confessions",
    proposed_title: "The Confessions of Nat Turner",
    proposed_creator: "Nat Turner",
    item_scope: "complete_confession_narrative",
    evidence_role: "authoritative_collection_support",
    next_action: "create_candidate_row_and_alias_source_spelling_southhampton",
    rationale: "LOA row supports a separate candidate; source spelling has an alias/date-risk note."
  },
  "e012_naal4_v2_brooks_maud_martha" => {
    decision: "create_source_backed_candidate",
    proposed_work_id: "work_candidate_source_naal_brooks_maud_martha",
    proposed_title: "Maud Martha",
    proposed_creator: "Gwendolyn Brooks",
    item_scope: "work_or_excerpt_pending",
    evidence_role: "field_anthology_support",
    next_action: "create_candidate_after_verifying_complete_vs_excerpt_scope",
    rationale: "No current Maud Martha candidate exists; Norton African American Literature source row supports candidate discovery."
  },
  "e012_naal4_v2_whitehead_nickel_boys" => {
    decision: "create_source_backed_candidate_with_selection_scope",
    proposed_work_id: "work_candidate_source_naal_whitehead_nickel_boys",
    proposed_title: "The Nickel Boys",
    proposed_creator: "Colson Whitehead",
    item_scope: "excerpt_or_selection_pending",
    evidence_role: "field_anthology_support_limited",
    next_action: "create_candidate_and_mark_selection_scope_before_scoring",
    rationale: "The TOC sub-selection is The Match; source supports candidate discovery, not complete-work evidence yet."
  },
  "philobiblon_biteca_texid_1112_curial" => {
    decision: "create_source_backed_candidate_needs_corroboration",
    proposed_work_id: "work_candidate_source_philobiblon_curial_e_guelfa",
    proposed_title: "Curial e Guelfa",
    proposed_creator: "Anonymous Catalan tradition",
    item_scope: "work_identity",
    evidence_role: "bibliographic_identity_only",
    next_action: "seek_anthology_or_literary_history_support_before_scoring",
    rationale: "PhiloBiblon identifies a possible Catalan chivalric-novel gap, but bibliographic evidence alone is not canon support."
  },
  "princeton_humseq_2024_east_asian_005" => {
    decision: "out_of_scope_media_boundary",
    item_scope: "film_media_item",
    evidence_role: "boundary_context_only",
    next_action: "do_not_create_literature_candidate",
    rationale: "Princess Mononoke is a film/media item in this source layer; do not import into the literature path."
  }
}.freeze

match_decisions = read_tsv(MATCH_REVIEW_PATH).map do |row|
  override = match_overrides[row.fetch("source_item_id")]
  unless override
    candidate_work_ids = row.fetch("candidate_work_ids", "").split(";").reject(&:empty?)
    issue_type = row.fetch("issue_type", "")
    matched_work_id = candidate_work_ids.size == 1 ? candidate_work_ids.first : ""
    decision =
      if issue_type == "no_candidate_match"
        "unresolved_no_candidate_match"
      elsif matched_work_id.empty?
        "unresolved_ambiguous_candidate_match"
      else
        "candidate_match_requires_manual_confirmation"
      end

    override = {
      decision: decision,
      matched_work_id: matched_work_id,
      item_scope: "scope_pending",
      evidence_role: "pending_match_review",
      next_action: "manual_match_review_before_materialization",
      reviewer_status: "pending_manual_review",
      rationale: "Generated default decision for expanded X013 queue; no hardcoded review override exists yet."
    }
  end

  {
    "source_item_id" => row.fetch("source_item_id"),
    "source_id" => row.fetch("source_id"),
    "raw_title" => row.fetch("raw_title"),
    "raw_creator" => row.fetch("raw_creator"),
    "decision" => override.fetch(:decision),
    "matched_work_id" => override.fetch(:matched_work_id, ""),
    "proposed_work_id" => override.fetch(:proposed_work_id, ""),
    "proposed_title" => override.fetch(:proposed_title, ""),
    "proposed_creator" => override.fetch(:proposed_creator, ""),
    "item_scope" => override.fetch(:item_scope),
    "evidence_role" => override.fetch(:evidence_role),
    "next_action" => override.fetch(:next_action),
    "reviewer_status" => override.fetch(:reviewer_status, "reviewed_not_integrated"),
    "rationale" => override.fetch(:rationale)
  }
end

match_decisions_by_item = match_decisions.each_with_object({}) do |row, by_id|
  by_id[row.fetch("source_item_id")] = row
end

relation_decisions = read_tsv(RELATION_REVIEW_PATH).map do |row|
  source_item_id = row.fetch("source_item_id")
  proposed_relation_type = row.fetch("proposed_relation_type")
  matched_work_id = row.fetch("matched_work_id")
  match_decision = match_decisions_by_item[source_item_id]

  decision =
    if match_decision && match_decision["decision"] == "out_of_scope_media_boundary"
      {
        decision: "reject_relation_out_of_scope",
        target_work_id: "",
        item_scope: match_decision["item_scope"],
        next_action: "no_relation",
        rationale: match_decision["rationale"]
      }
    elsif match_decision && match_decision["proposed_work_id"].to_s != ""
      {
        decision: "blocked_until_candidate_created",
        target_work_id: match_decision["proposed_work_id"],
        item_scope: match_decision["item_scope"],
        next_action: "create_candidate_before_final_relation",
        rationale: "Relation decision depends on proposed candidate #{match_decision["proposed_work_id"]}."
      }
    elsif source_item_id == "broadview_medieval_r3_exeter_wanderer"
      {
        decision: "link_to_existing_selection_candidate",
        target_work_id: "work_candidate_mandatory_old_english_elegies",
        item_scope: "poem_component",
        next_action: "add_selection_or_alias_relation_after_candidate_policy_review",
        rationale: "The Wanderer is represented by Old English Elegies: Selected Poems, but needs explicit selection/contained-work relation."
      }
    elsif proposed_relation_type == "selection_from"
      {
        decision: "keep_selection_scope_pending",
        target_work_id: matched_work_id,
        item_scope: "selection_or_excerpt",
        next_action: "confirm_complete_vs_excerpt_before_scoring",
        rationale: "Selection/excerpt rows cannot score as complete-work inclusion until source scope is reviewed."
      }
    elsif proposed_relation_type == "contained_in"
      {
        decision: "source_container_evidence_only",
        target_work_id: matched_work_id,
        item_scope: "contained_work_or_source_volume_item",
        next_action: "do_not_write_final_relation_until_source_container_model_exists",
        rationale: "This identifies how the source presents the item; it is not automatically a relation between two canon work candidates."
      }
    elsif proposed_relation_type == "cycle_member"
      {
        decision: "accept_cycle_member_review_needed",
        target_work_id: matched_work_id,
        item_scope: "cycle_member",
        next_action: "create_cycle_relation_when_cycle_container_candidate_exists",
        rationale: "Arthurian/Vulgate cycle context is relevant but needs a cycle-container relation target."
      }
    elsif proposed_relation_type == "variant_of"
      {
        decision: "alias_or_variant_review_needed",
        target_work_id: matched_work_id,
        item_scope: "title_variant_or_distinct_work",
        next_action: "add_alias_or_create_candidate_after_manual_review",
        rationale: "Variant/alias risk identified; do not merge automatically."
      }
    else
      {
        decision: "needs_manual_review",
        target_work_id: matched_work_id,
        item_scope: "unknown",
        next_action: "manual_review",
        rationale: "No automatic decision rule covered this relation queue row."
      }
    end

  {
    "source_item_id" => source_item_id,
    "source_id" => row.fetch("source_id"),
    "raw_title" => row.fetch("raw_title"),
    "raw_creator" => row.fetch("raw_creator"),
    "matched_work_id" => matched_work_id,
    "proposed_relation_type" => proposed_relation_type,
    "issue_type" => row.fetch("issue_type"),
    "decision" => decision.fetch(:decision),
    "target_work_id" => decision.fetch(:target_work_id),
    "item_scope" => decision.fetch(:item_scope),
    "next_action" => decision.fetch(:next_action),
    "reviewer_status" => "reviewed_not_integrated",
    "rationale" => decision.fetch(:rationale)
  }
end

write_tsv(MATCH_DECISIONS_PATH, MATCH_DECISION_HEADERS, match_decisions)
write_tsv(RELATION_DECISIONS_PATH, RELATION_DECISION_HEADERS, relation_decisions)

puts "wrote #{MATCH_DECISIONS_PATH.sub(ROOT + "/", "")} (#{match_decisions.size} rows)"
puts "wrote #{RELATION_DECISIONS_PATH.sub(ROOT + "/", "")} (#{relation_decisions.size} rows)"
