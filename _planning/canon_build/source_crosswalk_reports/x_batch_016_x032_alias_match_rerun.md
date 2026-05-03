# X Batch 16 Report: X032 Alias Match Rerun

Date: 2026-05-03

Status: matching rerun generated; public canon unchanged.

## Summary

X032 reruns source-item matching after the X031 reviewed title-variant aliases. This checkpoint updates the match candidates and review decisions only. It does not write evidence rows, relation rows, omission candidates, scores, replacements, or public canon changes.

| Metric | Count |
|---|---:|
| Match candidates | 541 |
| Match-review queue rows | 5,474 |
| Match-review decision rows | 5,474 |
| Net candidate rows added after X031 | 12 |

## Decision Summary

| Decision | Rows |
|---|---:|
| candidate_match_requires_manual_confirmation | 50 |
| out_of_scope_media_boundary | 1 |
| unresolved_ambiguous_candidate_match | 10 |
| unresolved_no_candidate_match | 5,413 |

## Alias Effects

The rerun confirms that reviewed X031 aliases now create candidate matches for these source-title variants:

| Source title | Candidate work |
|---|---|
| The Ramayana of Valmiki | `work_canon_ramayana` |
| Tales of Heike | `work_candidate_tale_of_heike` |
| Kubla Khan | `work_candidate_bloom_late_032_literature_bloom_democratic_age_reviewed_0482_christabel_kubla_khan_a_vision_in_a_dream_the_pa` |
| Fuenteovejuna | `work_candidate_bloom_fuente_ovejuna` |
| The Song of Lasting Regret | `work_candidate_eastasia_lit_song_everlasting_sorrow` |

Creator normalization still needs review where source creators use alternate romanizations, such as `Po Chu-yi` for Bai Juyi.

## Known Defect

The source matcher still treats leading `from` as part of the title. Two reviewed X030 rows therefore remain unresolved even though X031 added the plain-title alias:

| Source row | Raw title | Expected target |
|---|---|---|
| `longman2e_vold_102_ihara_saikaku_from_life_of_a_sensuous_woman` | from Life of a Sensuous Woman | `work_candidate_global_lit_life_amorous_woman` |
| `nawol5e_vold_073_from_life_of_a_sensuous_woman` | From Life of a Sensuous Woman | `work_candidate_global_lit_life_amorous_woman` |

This should be fixed in matcher logic, not by manually adding every `from` variant as an alias.

## Next Actions

1. Add title-normalization support for leading `from` in source-item matching.
2. Rerun X013 match candidates and review decisions after that matcher change.
3. Keep creator-alias and romanization normalization separate from title aliases so creator evidence remains reviewable.
