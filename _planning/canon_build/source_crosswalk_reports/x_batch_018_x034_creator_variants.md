# X Batch 18 Report: X034 Creator Variants

Date: 2026-05-03

Status: creator variants added and matching rerun; public canon unchanged.

## Summary

X034 adds reviewed creator-name variants to `canon_creators.tsv` and updates the source matcher to use those variants when comparing source creators with candidate creators. This addresses clear romanization variants without treating all title collisions as creator matches.

| Metric | Count |
|---|---:|
| Creator rows updated | 2 |
| Creator variant strings added | 4 |
| Match candidates | 557 |
| Match-review decision rows | 5,474 |
| Candidate rows changed from creator mismatch to creator match | 4 |

## Added Creator Variants

| Creator | Variants |
|---|---|
| Tao Yuanming | T'ao Ch'ien; Tao Qian; Tao Chien |
| Bai Juyi | Po Chu-yi |

## Corrected Candidate Rows

| Source row | Source creator | Candidate creator | Result |
|---|---|---|---|
| `e016_ctcl1996_008_t_ao_ch_ien_the_peach_blossom_spring` | T'ao Ch'ien | Tao Yuanming | creator_match `yes` |
| `longman2e_volb_021_tao_qian_peach_blossom_spring` | Tao Qian | Tao Yuanming | creator_match `yes` |
| `e016_shorter_columbia_tradch_191_po_chu_yi_the_song_of_lasting_regret` | Po Chu-yi | Bai Juyi | creator_match `yes` |
| `e016_shorter_columbia_tradch_214_t_ao_ch_ien_the_peach_blossom_spring` | T'ao Ch'ien | Tao Yuanming | creator_match `yes` |

## Decision Summary

| Decision | Rows |
|---|---:|
| candidate_match_requires_manual_confirmation | 54 |
| out_of_scope_media_boundary | 1 |
| unresolved_ambiguous_candidate_match | 16 |
| unresolved_no_candidate_match | 5,403 |

## Interpretation

This packet improves creator matching only. It does not accept matches, create evidence rows, or change the public path. Most remaining `creator_match=no` title matches are real homonymous-title collisions, such as `Homecoming`, `Woman`, `The Door`, `Salt`, and `Robinson Crusoe`; those should stay split by creator.

## Next Actions

1. Review remaining creator mismatches for additional safe variant groups.
2. Keep true homonymous-title collisions in manual review rather than widening creator matching.
3. Continue routing X030 contained-work and selection decisions into relation/scope review.
