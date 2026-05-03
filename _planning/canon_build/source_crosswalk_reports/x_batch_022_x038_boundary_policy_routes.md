# X Batch 22 Report: X038 Boundary Policy Routes

Date: 2026-05-03

Status: boundary policy routes recorded for X036 provisional candidates; public canon unchanged.

## Summary

X038 records first-pass conditional boundary policies for the four X036 source-backed candidates and keeps them blocked from scoring until evidence, relation scope, duplicate/granularity, and coverage review are complete.

| Metric | Count |
|---|---:|
| Boundary policy routes recorded | 3 |
| Work candidates updated | 4 |
| Evidence rows annotated with boundary policy support | 8 |
| Omission-queue rows | 12 |
| Score-ready rows | 0 |

## Policy Routes

| Policy ID | Route | Candidate rows | Current gate |
|---|---|---:|---|
| `boundary_policy_political_philosophical_prose_conditional` | Political-philosophical prose can be reviewed as literature when source-backed by literature-anthology context and read for rhetoric, form, style, and influence. | 1 | Evidence, complete-work scope, and coverage comparison |
| `boundary_policy_poetry_sequence_collection_conditional` | Named poetry sequences or stable collections can be reviewed as work-level candidates, with duplicate review against selected-poem rows. | 1 | Evidence and Donne-overlap review |
| `boundary_policy_short_story_granularity_conditional` | Individual short stories can be reviewed as work-level candidates when multiple independent literature-anthology sources present the story by title. | 2 | Evidence, author-representation, and granularity review |

## Candidate Updates

| Work ID | Title | Boundary flag after X038 | Boundary policy |
|---|---|---|---|
| `work_candidate_x030_machiavelli_prince` | The Prince | `political_philosophical_prose_conditional_scope_open` | `boundary_policy_political_philosophical_prose_conditional` |
| `work_candidate_x030_donne_holy_sonnets` | Holy Sonnets | `poetry_sequence_collection_duplicate_scope_open` | `boundary_policy_poetry_sequence_collection_conditional` |
| `work_candidate_x030_mahfouz_zaabalawi` | Zaabalawi | `short_story_granularity_conditional_scope_open` | `boundary_policy_short_story_granularity_conditional` |
| `work_candidate_x030_silko_yellow_woman` | Yellow Woman | `short_story_granularity_conditional_scope_open` | `boundary_policy_short_story_granularity_conditional` |

## Derived Table State

| Table | Result |
|---|---|
| `canon_review_decisions.yml` | 3 boundary-policy route decisions recorded |
| `canon_work_candidates.tsv` | 4 candidates carry conditional `boundary_policy_id` values |
| `canon_evidence.tsv` | 8 existing evidence rows now carry `supports_boundary_policy_id` |
| `canon_omission_queue.tsv` | 12 rows, all `not_ready_for_scoring` |
| `canon_scoring_inputs.tsv` | 3,012 rows, all `blocked_from_score_computation` |

## Validation

`ruby scripts/canon_validate_build_layer.rb` passed after regeneration.

## Interpretation

This packet does not decide that these four works belong in the public 3,000-work path. It only prevents them from being stuck in an unclassified boundary state. The candidates are now conditionally eligible for later scoring review, but the open boundary flags intentionally keep them blocked until source evidence and scope gates are reviewed.

## Next Actions

1. Review the eight X036/X038 evidence rows and decide whether the anthology evidence can be accepted.
2. Close or keep open the relation-scope blockers for these rows.
3. Continue red-cell packet routing for remaining high-risk omissions and variant/selection cases.
