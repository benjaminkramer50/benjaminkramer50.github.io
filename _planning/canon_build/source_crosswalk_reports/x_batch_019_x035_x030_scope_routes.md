# X Batch 19 Report: X035 X030 Scope Routes

Date: 2026-05-03

Status: X030 routes applied to generated match/relation decisions; public canon unchanged.

## Summary

X035 makes the X030 reviewed title-route decisions machine-readable. It updates `scripts/canon_review_match_relation_queues.rb` so future decision reruns preserve reviewed contained-work, selection, boundary-candidate, and creator-disambiguation routes instead of reverting those rows to generic unresolved matches.

| Metric | Count |
|---|---:|
| X030-routed match rows | 39 |
| Represented by existing selection/collection | 19 |
| Contained in existing work | 10 |
| Boundary-review candidate proposals | 8 |
| Creator-disambiguation holds | 2 |
| Relation-scope status rows | 7,567 |

## Match Decision Summary

| Decision | Rows |
|---|---:|
| candidate_match_requires_manual_confirmation | 54 |
| contained_in_existing_work | 10 |
| create_source_backed_candidate_needs_boundary_review | 8 |
| existing_match_requires_creator_disambiguation | 2 |
| out_of_scope_media_boundary | 1 |
| represented_by_existing_selection | 19 |
| unresolved_ambiguous_candidate_match | 14 |
| unresolved_no_candidate_match | 5,366 |

## Relation Scope Summary

| Scope status | Rows |
|---|---:|
| alias_or_variant_review_required | 8 |
| contained_component_review_required | 10 |
| creator_disambiguation_required | 2 |
| cycle_container_required | 2 |
| represented_by_existing_selection_review_required | 21 |
| selection_scope_pending | 2,409 |
| source_container_only | 5,107 |
| target_exists_scope_review_required | 8 |

## Boundary-Review Candidate Proposals

These are proposed build-layer IDs only. They are not materialized work candidates yet.

| Proposed ID | Title | Creator | Scope |
|---|---|---|---|
| `work_candidate_x030_donne_holy_sonnets` | Holy Sonnets | John Donne | collection boundary pending |
| `work_candidate_x030_machiavelli_prince` | The Prince | Niccolo Machiavelli | political/philosophical prose boundary pending |
| `work_candidate_x030_silko_yellow_woman` | Yellow Woman | Leslie Marmon Silko | short-story granularity pending |
| `work_candidate_x030_mahfouz_zaabalawi` | Zaabalawi | Naguib Mahfouz | short-story granularity pending |

## Interpretation

This removes false omission pressure from component rows such as `Agamemnon`, Canterbury Tales sections, Keats odes, Montaigne essays, `The Tyger`, `Ithaka`, and `Invitation to the Voyage`. It also preserves actual open questions: `The Prince`, `Holy Sonnets`, `Yellow Woman`, and `Zaabalawi` still require boundary/granularity review before any candidate materialization.

## Next Actions

1. Review the 8 target-missing boundary rows and decide whether to materialize candidate rows.
2. Keep relation-scope rows blocked until contained-work and selection policy is finalized.
3. Continue reducing false gaps before running scoring or public replacement transactions.
