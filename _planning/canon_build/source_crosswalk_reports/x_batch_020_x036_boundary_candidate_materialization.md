# X Batch 20 Report: X036 Boundary Candidate Materialization

Date: 2026-05-03

Status: provisional build-layer candidates materialized; public canon unchanged.

## Summary

X036 materializes the X035 boundary-review proposals as provisional `source_backed_candidate` rows, then regenerates matching, relation review, relation scope, evidence, source-debt, omission, and scoring-input tables.

| Metric | Count |
|---|---:|
| New work candidates | 4 |
| Source items updated in this run | 27 |
| Evidence rows created in this run | 27 |
| Total work candidates | 3,012 |
| Total source-backed candidates | 12 |
| Total omission-queue rows | 12 |
| Score-ready rows | 0 |

## New Provisional Candidates

| Work ID | Title | Creator | Evidence rows | Blocking boundary |
|---|---|---|---:|---|
| `work_candidate_x030_machiavelli_prince` | The Prince | Niccolo Machiavelli | 2 | political/philosophical prose boundary pending |
| `work_candidate_x030_donne_holy_sonnets` | Holy Sonnets | John Donne | 2 | poetry collection boundary pending |
| `work_candidate_x030_mahfouz_zaabalawi` | Zaabalawi | Naguib Mahfouz | 2 | short-story granularity pending |
| `work_candidate_x030_silko_yellow_woman` | Yellow Woman | Leslie Marmon Silko | 2 | short-story granularity pending |

## Regenerated Tables

| Table | Rows |
|---|---:|
| `canon_match_candidates.tsv` | 584 |
| `canon_match_review_queue.tsv` | 5,447 |
| `canon_relation_review_queue.tsv` | 7,586 |
| `canon_relation_scope_status.tsv` | 7,586 |
| `canon_evidence.tsv` | 495 |
| `canon_source_debt_status.tsv` | 3,012 |
| `canon_omission_queue.tsv` | 12 |
| `canon_scoring_inputs.tsv` | 3,012 |

## Omission Queue Status

All 12 source-backed candidates remain `not_ready_for_scoring`. The four X036 candidates have two provisional anthology evidence rows each, but evidence is still `needs_followup`, dates are pending or uncertain, boundary/scope flags are open, and scoring remains blocked.

## Interpretation

This is candidate discovery, not list integration. `The Prince`, `Holy Sonnets`, `Yellow Woman`, and `Zaabalawi` are now visible to the build layer and can be tracked through evidence and blockers instead of remaining loose red-cell notes. None can enter a public replacement batch until boundary, scope, source-debt, duplicate, taxonomy, and scoring gates are resolved.

## Next Actions

1. Add date/taxonomy metadata for the four X036 candidates.
2. Review whether each boundary class should be eligible for the literature canon.
3. Accept or reject provisional evidence only after source scope is checked.
