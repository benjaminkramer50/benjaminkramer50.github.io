# X069 Current High-Risk Resolution Queue

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X069 converts the remaining current high-risk source-item rescue rows into explicit resolution decisions. It does not write evidence. Its job is to prevent high-risk component rows from being promoted as collection or selected-work support without exact form, membership, or external work-level support.

## Output

- Added `scripts/canon_generate_current_high_risk_resolution_queue_x069.rb`.
- Added `canon_current_high_risk_resolution_queue.tsv`.
- Added `canon_current_high_risk_work_resolution.tsv`.
- Classified 17 high-risk source rows across 7 incumbent works.

Issue summary:

| Issue | Rows |
|---|---:|
| `component_form_not_proven_for_current_selected_work` | 6 |
| `named_collection_membership_not_proven_by_current_source_item` | 11 |

Decision summary:

| Decision | Rows |
|---|---:|
| `hold_for_exact_named_collection_membership_source` | 7 |
| `hold_for_exact_story_collection_membership_source` | 2 |
| `needs_verified_poem_form_before_selection_evidence` | 4 |
| `reject_or_hold_component_form_mismatch` | 2 |
| `reject_wrong_form_for_story_collection_support` | 2 |

Work-level resolution:

| Work | Rows | Decision | Next action |
|---|---:|---|---|
| `work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0835_collected_poems` | 1 | `external_collection_support_needed_and_local_row_probable_mismatch` | `acquire_external_poetry_collection_support` |
| `work_candidate_completion_lit_selected_poems_milosz` | 1 | `form_verification_then_selection_only_possible` | `verify_form_then_acquire_selected_work_support` |
| `work_candidate_global_lit_nazim_hikmet_poems` | 1 | `external_selected_work_or_form_correction_needed` | `acquire_external_selected_work_support` |
| `work_candidate_latcarib_lit_all_fires_fire` | 2 | `external_story_collection_support_needed` | `acquire_external_story_collection_support` |
| `work_candidate_latcarib_lit_blow_up` | 2 | `external_story_collection_support_needed` | `acquire_external_story_collection_support` |
| `work_candidate_latcarib_lit_walcott_collected_poems` | 3 | `external_collection_support_needed` | `acquire_external_poetry_collection_support` |
| `work_candidate_mandatory_bradstreet_tenth_muse` | 7 | `external_complete_work_support_needed` | `acquire_external_complete_work_support` |

## Interpretation

The medium-risk lane is empty. The remaining local source rows are not safe evidence writes: they either require named-collection membership, independent collection support, or public component-form verification. X070 should therefore acquire targeted public sources for these seven works rather than continue trying to rescue high-risk rows from anthology components.

Direct public replacements: 0.
