# X Batch 17 Report: X033 From-Prefix Matcher

Date: 2026-05-03

Status: matcher rule added and rerun; public canon unchanged.

## Summary

X033 updates `scripts/canon_match_source_items.rb` so source titles beginning with `from` are matched two ways: the literal title and the title with the leading `from` removed. This catches anthology excerpt headings without turning them into accepted matches.

| Metric | Count |
|---|---:|
| Match candidates | 557 |
| Match-review queue rows | 5,474 |
| Match-review decision rows | 5,474 |
| From-prefix candidate rows | 16 |
| From-prefix source rows | 10 |

## Decision Summary

| Decision | Rows |
|---|---:|
| candidate_match_requires_manual_confirmation | 54 |
| out_of_scope_media_boundary | 1 |
| unresolved_ambiguous_candidate_match | 16 |
| unresolved_no_candidate_match | 5,403 |

## From-Prefix Rows

| Source row | Raw title | Candidate target(s) |
|---|---|---|
| `e016_shorter_columbia_tradch_176_anonymous_from_the_nineteen_old_poems` | From the "Nineteen Old Poems" | `work_candidate_global_lit_nineteen_old_poems` |
| `longman2e_vola_314_jean_jacques_rousseau_from_the_confessions` | from The Confessions | `work_candidate_bloom_gap_031_0319_confessions`; `work_candidate_confessions_augustine` |
| `longman2e_vold_011_mir_muhammad_taqi_mir_from_the_autobiography` | from The Autobiography | `work_candidate_bloom_gap_031_0119_autobiography`; `work_candidate_wave001_franklin_autobiography` |
| `longman2e_vold_102_ihara_saikaku_from_life_of_a_sensuous_woman` | from Life of a Sensuous Woman | `work_candidate_global_lit_life_amorous_woman` |
| `nawol5e_vola_157_from_metamorphoses` | From Metamorphoses | `work_candidate_golden_ass_apuleius`; `work_candidate_metamorphoses_ovid` |
| `nawol5e_vola_244_from_the_classic_of_poetry` | From THE CLASSIC OF POETRY | `work_candidate_book_of_songs` |
| `nawol5e_volb_319_from_confessions` | From Confessions | `work_candidate_bloom_gap_031_0319_confessions`; `work_candidate_confessions_augustine` |
| `nawol5e_volc_069_ibn_sina_avicenna_from_the_autobiography` | FROM THE AUTOBIOGRAPHY | `work_candidate_bloom_gap_031_0119_autobiography`; `work_candidate_wave001_franklin_autobiography` |
| `nawol5e_vold_073_from_life_of_a_sensuous_woman` | From Life of a Sensuous Woman | `work_candidate_global_lit_life_amorous_woman` |
| `nawol5e_vole_016_from_confessions` | From Confessions | `work_candidate_bloom_gap_031_0319_confessions`; `work_candidate_confessions_augustine` |

## Interpretation

This is not a public-list integration. The rule correctly resolves the reviewed Life of a Sensuous Woman alias rows into candidate matches, but it also surfaces ambiguous title collisions such as `Confessions`, `Metamorphoses`, and `The Autobiography`. Those rows remain in manual review and should not be materialized until creator, date, and scope are checked.

## Next Actions

1. Review the 16 from-prefix candidate rows and accept only rows where creator/scope is unambiguous.
2. Add creator-alias normalization for clear romanization variants such as Po Chu-yi/Bai Juyi in a separate packet.
3. Continue routing X030 contained-work decisions into relation/scope decisions before creating omission candidates.
