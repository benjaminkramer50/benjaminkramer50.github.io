# X Batch 14 Report: X030 Title-Route Review

Date: 2026-05-03

Status: title-route decisions recorded; public canon unchanged.

## Summary

X030 manually routes the clearest X029 title-level rows. This prevents already-covered components and title variants from being mistaken for new omissions.

| Review decision | Rows |
|---|---:|
| contained_in_current_collection | 9 |
| contained_in_current_work | 5 |
| existing_current_match_needs_creator_disambiguation | 1 |
| new_omission_candidate_boundary_review | 1 |
| new_omission_candidate_short_story_review | 2 |
| new_or_collection_candidate_review | 1 |
| orthographic_alias_to_current_work | 1 |
| variant_alias_to_current_work | 5 |

## Decisions

| Subject | Decision | Target | Next action |
|---|---|---|---|
| Invitation to the Voyage | contained_in_current_collection | work_candidate_fleurs_du_mal | record_selection_or_alias_relation_to_current_collection |
| Kubla Khan | variant_alias_to_current_work | work_candidate_bloom_late_032_literature_bloom_democratic_age_reviewed_0482_christabel_kubla_khan_a_vision_in_a_dream_the_pa | add_alias_or_match_review_decision |
| "The Song of Lasting Regret" / The Song of Lasting Regret | variant_alias_to_current_work | work_candidate_eastasia_lit_song_everlasting_sorrow | add_alias_or_match_review_decision |
| Agamemnon / AGAMEMNON | contained_in_current_work | work_canon_oresteia | record_contained_work_scope_not_new_omission |
| Fuenteovejuna | orthographic_alias_to_current_work | work_candidate_bloom_fuente_ovejuna | add_alias_or_match_review_decision |
| Holy Sonnets / HOLY SONNETS | new_or_collection_candidate_review |  | review_collection_boundary_and_existing_donne_coverage |
| Ithaka | contained_in_current_collection | work_candidate_euro_under_lit_cavafy_poems | record_selection_or_alias_relation_to_current_collection |
| O Captain! My Captain! | contained_in_current_collection | work_candidate_leaves_of_grass | record_selection_scope_not_new_work |
| Ode on a Grecian Urn | contained_in_current_collection | work_candidate_bloom_keats_poems | record_selection_scope_not_new_work |
| Ode to a Nightingale | contained_in_current_collection | work_candidate_bloom_keats_poems | record_selection_scope_not_new_work |
| Of Cannibals | contained_in_current_collection | work_candidate_essays_montaigne | record_selection_scope_not_new_work |
| Of the Power of the Imagination | contained_in_current_collection | work_candidate_essays_montaigne | record_selection_scope_not_new_work |
| Prologue in Heaven | contained_in_current_work | work_candidate_faust_goethe | record_selection_scope_not_new_work |
| Tales Of Heike / THE TALES OF THE HEIKE | variant_alias_to_current_work | work_candidate_tale_of_heike | add_alias_or_match_review_decision |
| The Dead | existing_current_match_needs_creator_disambiguation | work_candidate_bloom_reviewed_dubliners | split_by_creator_then_match_joyce_rows_to_dubliners |
| The General Prologue | contained_in_current_work | work_canon_canterbury_tales | record_selection_scope_not_new_work |
| The Prince | new_omission_candidate_boundary_review |  | create_candidate_after_boundary_policy_review |
| The Ramayana of Valmiki / THE RAMAYANA OF VALMIKI | variant_alias_to_current_work | work_canon_ramayana | add_alias_or_match_review_decision |
| The Tyger | contained_in_current_collection | work_candidate_bloom_reviewed_songs_innocence_experience | record_selection_scope_not_new_work |
| The Wife of Bath's Prologue | contained_in_current_work | work_canon_canterbury_tales | record_selection_scope_not_new_work |
| The Wife of Bath's Tale | contained_in_current_work | work_canon_canterbury_tales | record_selection_scope_not_new_work |
| To Autumn | contained_in_current_collection | work_candidate_bloom_keats_poems | record_selection_scope_not_new_work |
| Yellow Woman | new_omission_candidate_short_story_review |  | review_short_story_granularity_and_create_candidate_if_policy_allows |
| Zaabalawi | new_omission_candidate_short_story_review |  | review_short_story_granularity_and_create_candidate_if_policy_allows |
| from Life of a Sensuous Woman / From Life of a Sensuous Woman | variant_alias_to_current_work | work_candidate_global_lit_life_amorous_woman | add_alias_or_match_review_decision |

## Interpretation

These are route decisions, not public-list transactions. Alias, contained-work, and selection decisions should be written into match/relation review tables before any scoring or replacement packet. New omission candidates still need source-scope, boundary, duplicate, chronology, and source-debt gates.

## Next Actions

1. Write alias/match decisions for clear variants such as Fuenteovejuna, Ramayana of Valmiki, Tales of Heike, and Life of a Sensuous Woman.
2. Write contained/selection scope decisions for Canterbury, Montaigne, Keats, Blake, Whitman, Cavafy, Baudelaire, and Oresteia component rows.
3. Open candidate-boundary review for The Prince, Yellow Woman, Zaabalawi, and unresolved collection-level rows such as Holy Sonnets.
