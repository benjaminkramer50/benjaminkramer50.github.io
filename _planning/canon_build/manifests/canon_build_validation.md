# Canon Build Layer Validation

- status: PASS
- checked_files: 25
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
| table:evidence | PASS | `_planning/canon_build/tables/canon_evidence.tsv (13 columns)` |
| table:review_decisions | PASS | `_planning/canon_build/tables/canon_review_decisions.yml` |
| table:scores | PASS | `_planning/canon_build/tables/canon_scores.tsv (27 columns)` |
| table:source_weights | PASS | `_planning/canon_build/tables/canon_source_weights.yml` |
| table:source_debt_rules | PASS | `_planning/canon_build/tables/canon_source_debt_rules.yml` |
| table:source_debt_status | PASS | `_planning/canon_build/tables/canon_source_debt_status.tsv (15 columns)` |
| table:coverage_targets | PASS | `_planning/canon_build/tables/canon_coverage_targets.yml` |
| table:path_selection | PASS | `_planning/canon_build/tables/canon_path_selection.tsv (8 columns)` |
| table:replacement_candidates | PASS | `_planning/canon_build/tables/canon_replacement_candidates.tsv (18 columns)` |
| table:packet_status | PASS | `_planning/canon_build/tables/canon_packet_status.tsv (8 columns)` |
| policy:source_weights.source_type_mapping | PASS | `42 source types mapped` |
| policy:source_debt_rules.source_class_rules | PASS | `10 source classes covered` |
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
| integrity:path_selection.work_id | PASS | `all selected work IDs exist` |
| integrity:source_debt_status.work_id | PASS | `one source-debt status row per work candidate` |
| integrity:path_selection.selected_rank_continuity | PASS | `3000 selected rows` |
