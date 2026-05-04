# Canon Build Layer Validation

- status: PASS
- checked_files: 45
- failures: 0

## Checks

| Check | Status | Detail |
|---|---|---|
| schema:source | PASS | `_planning/canon_build/schemas/canon_source.schema.yml` |
| schema:work | PASS | `_planning/canon_build/schemas/canon_work.schema.yml` |
| schema:evidence | PASS | `_planning/canon_build/schemas/canon_evidence.schema.yml` |
| table:source_registry | PASS | `_planning/canon_build/tables/canon_source_registry.tsv (14 columns)` |
| table:source_items | PASS | `_planning/canon_build/tables/canon_source_items.tsv (17 columns)` |
| table:work_candidates | PASS | `_planning/canon_build/tables/canon_work_candidates.tsv (31 columns)` |
| table:creators | PASS | `_planning/canon_build/tables/canon_creators.tsv (7 columns)` |
| table:work_creators | PASS | `_planning/canon_build/tables/canon_work_creators.tsv (5 columns)` |
| table:aliases | PASS | `_planning/canon_build/tables/canon_aliases.tsv (10 columns)` |
| table:relations | PASS | `_planning/canon_build/tables/canon_relations.tsv (7 columns)` |
| table:match_candidates | PASS | `_planning/canon_build/tables/canon_match_candidates.tsv (13 columns)` |
| table:match_review_queue | PASS | `_planning/canon_build/tables/canon_match_review_queue.tsv (8 columns)` |
| table:match_review_decisions | PASS | `_planning/canon_build/tables/canon_match_review_decisions.tsv (14 columns)` |
| table:relation_review_queue | PASS | `_planning/canon_build/tables/canon_relation_review_queue.tsv (9 columns)` |
| table:relation_review_decisions | PASS | `_planning/canon_build/tables/canon_relation_review_decisions.tsv (13 columns)` |
| table:relation_scope_rules | PASS | `_planning/canon_build/tables/canon_relation_scope_rules.yml` |
| table:relation_scope_status | PASS | `_planning/canon_build/tables/canon_relation_scope_status.tsv (15 columns)` |
| table:evidence | PASS | `_planning/canon_build/tables/canon_evidence.tsv (13 columns)` |
| table:review_decisions | PASS | `_planning/canon_build/tables/canon_review_decisions.yml` |
| table:scores | PASS | `_planning/canon_build/tables/canon_scores.tsv (27 columns)` |
| table:source_weights | PASS | `_planning/canon_build/tables/canon_source_weights.yml` |
| table:source_debt_rules | PASS | `_planning/canon_build/tables/canon_source_debt_rules.yml` |
| table:source_debt_status | PASS | `_planning/canon_build/tables/canon_source_debt_status.tsv (15 columns)` |
| table:scoring_inputs | PASS | `_planning/canon_build/tables/canon_scoring_inputs.tsv (18 columns)` |
| table:coverage_targets | PASS | `_planning/canon_build/tables/canon_coverage_targets.yml` |
| table:path_selection | PASS | `_planning/canon_build/tables/canon_path_selection.tsv (8 columns)` |
| table:omission_queue | PASS | `_planning/canon_build/tables/canon_omission_queue.tsv (14 columns)` |
| table:replacement_candidates | PASS | `_planning/canon_build/tables/canon_replacement_candidates.tsv (18 columns)` |
| table:replacement_pair_review_queue | PASS | `_planning/canon_build/tables/canon_replacement_pair_review_queue.tsv (17 columns)` |
| table:cut_review_work_orders | PASS | `_planning/canon_build/tables/canon_cut_review_work_orders.tsv (19 columns)` |
| table:generic_selection_basis_review | PASS | `_planning/canon_build/tables/canon_generic_selection_basis_review.tsv (22 columns)` |
| table:cut_source_item_rescue_candidates | PASS | `_planning/canon_build/tables/canon_cut_source_item_rescue_candidates.tsv (19 columns)` |
| table:cut_review_resolution_lanes | PASS | `_planning/canon_build/tables/canon_cut_review_resolution_lanes.tsv (17 columns)` |
| table:cut_rescue_scope_review | PASS | `_planning/canon_build/tables/canon_cut_rescue_scope_review.tsv (19 columns)` |
| table:cut_evidence_proposals | PASS | `_planning/canon_build/tables/canon_cut_evidence_proposals.tsv (16 columns)` |
| table:cut_evidence_item_decisions | PASS | `_planning/canon_build/tables/canon_cut_evidence_item_decisions.tsv (17 columns)` |
| table:cut_evidence_write_plan | PASS | `_planning/canon_build/tables/canon_cut_evidence_write_plan.tsv (16 columns)` |
| table:cut_evidence_applied_rows | PASS | `_planning/canon_build/tables/canon_cut_evidence_applied_rows.tsv (12 columns)` |
| table:cut_side_post_x058_action_queue | PASS | `_planning/canon_build/tables/canon_cut_side_post_x058_action_queue.tsv (20 columns)` |
| table:existing_selection_evidence_reviews | PASS | `_planning/canon_build/tables/canon_existing_selection_evidence_reviews.tsv (13 columns)` |
| table:current_rescue_scope_review | PASS | `_planning/canon_build/tables/canon_current_rescue_scope_review.tsv (15 columns)` |
| table:medium_risk_rescue_evidence_applied | PASS | `_planning/canon_build/tables/canon_medium_risk_rescue_evidence_applied.tsv (15 columns)` |
| table:high_risk_rescue_residue | PASS | `_planning/canon_build/tables/canon_high_risk_rescue_residue.tsv (18 columns)` |
| table:selection_only_complete_work_support_review | PASS | `_planning/canon_build/tables/canon_selection_only_complete_work_support_review.tsv (13 columns)` |
| table:packet_status | PASS | `_planning/canon_build/tables/canon_packet_status.tsv (8 columns)` |
| policy:source_weights.source_type_mapping | PASS | `42 source types mapped` |
| policy:source_debt_rules.source_class_rules | PASS | `10 source classes covered` |
| policy:relation_scope_rules.decision_rules | PASS | `12 decision rules declared` |
| controlled:source_registry.source_type | PASS | `42 allowed values` |
| controlled:source_registry.extraction_status | PASS | `16 allowed values` |
| controlled:source_items.evidence_type | PASS | `6 allowed values` |
| controlled:source_items.match_status | PASS | `7 allowed values` |
| controlled:work_candidates.candidate_status | PASS | `5 allowed values` |
| controlled:work_candidates.date_precision | PASS | `6 allowed values` |
| controlled:work_candidates.review_status | PASS | `7 allowed values` |
| controlled:evidence.evidence_strength | PASS | `4 allowed values` |
| controlled:evidence.reviewer_status | PASS | `4 allowed values` |
| controlled:replacement_candidates.gate_status | PASS | `4 allowed values` |
| integrity:unique:source_registry.source_id | PASS | `0 duplicates` |
| integrity:unique:source_items.source_item_id | PASS | `0 duplicates` |
| integrity:unique:work_candidates.work_id | PASS | `0 duplicates` |
| integrity:unique:creators.creator_id | PASS | `0 duplicates` |
| integrity:unique:relation_scope_status.relation_scope_id | PASS | `0 duplicates` |
| integrity:unique:omission_queue.omission_id | PASS | `0 duplicates` |
| integrity:unique:evidence.evidence_id | PASS | `0 duplicates` |
| integrity:source_items.source_id | PASS | `all source IDs registered` |
| integrity:source_items.matched_work_id | PASS | `all nonblank matched work IDs exist` |
| integrity:work_creators.refs | PASS | `all work-creator refs exist and pairs are unique` |
| integrity:evidence.source_id | PASS | `all source IDs registered` |
| integrity:evidence.source_item_id | PASS | `all nonblank source item IDs exist` |
| integrity:evidence.work_id | PASS | `all work IDs exist` |
| integrity:evidence.supported_source_item_status | PASS | `no evidence from unmatched/out-of-scope source items` |
| integrity:relations.work_refs | PASS | `all relation work refs exist` |
| integrity:match_candidates.refs | PASS | `all match candidate refs exist` |
| integrity:match_review_queue.source_item_id | PASS | `all review queue source items exist` |
| integrity:match_review_decisions.refs | PASS | `all match decisions cover queued source items and existing work refs` |
| integrity:relation_review_queue.refs | PASS | `all relation review refs exist` |
| integrity:relation_review_decisions.refs | PASS | `all relation decisions cover queued rows and valid existing/proposed targets` |
| integrity:relation_scope_status.refs | PASS | `all relation scope statuses cover decisions and valid refs` |
| integrity:path_selection.work_id | PASS | `all selected work IDs exist` |
| integrity:source_debt_status.work_id | PASS | `one source-debt status row per work candidate` |
| integrity:scoring_inputs.work_id | PASS | `one scoring input row per work candidate` |
| integrity:omission_queue.refs | PASS | `all omission queue work/evidence refs exist` |
| integrity:path_selection.selected_rank_continuity | PASS | `3000 selected rows` |
