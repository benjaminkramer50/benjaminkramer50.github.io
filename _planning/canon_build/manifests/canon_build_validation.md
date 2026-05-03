# Canon Build Layer Validation

- status: PASS
- checked_files: 16
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
| table:evidence | PASS | `_planning/canon_build/tables/canon_evidence.tsv (13 columns)` |
| table:review_decisions | PASS | `_planning/canon_build/tables/canon_review_decisions.yml` |
| table:scores | PASS | `_planning/canon_build/tables/canon_scores.tsv (27 columns)` |
| table:coverage_targets | PASS | `_planning/canon_build/tables/canon_coverage_targets.yml` |
| table:path_selection | PASS | `_planning/canon_build/tables/canon_path_selection.tsv (8 columns)` |
| table:replacement_candidates | PASS | `_planning/canon_build/tables/canon_replacement_candidates.tsv (18 columns)` |
| integrity:unique:source_registry.source_id | PASS | `0 duplicates` |
| integrity:unique:source_items.source_item_id | PASS | `0 duplicates` |
| integrity:unique:work_candidates.work_id | PASS | `0 duplicates` |
| integrity:unique:evidence.evidence_id | PASS | `0 duplicates` |
| integrity:source_items.source_id | PASS | `all source IDs registered` |
| integrity:evidence.source_id | PASS | `all source IDs registered` |
| integrity:evidence.source_item_id | PASS | `all nonblank source item IDs exist` |
| integrity:evidence.work_id | PASS | `all work IDs exist` |
