# X Batch 25 Report: X041 NAAL Volume 1 Corroboration

Date: 2026-05-03

Status: targeted Norton African American Literature Volume 1 corroboration added; public canon unchanged.

## Summary

X041 checks the already-registered Norton African American Literature 4e Volume 1 public TOC for unresolved source-backed candidates before adding new source classes. The TOC corroborates two rows:

- William Wells Brown, `Narrative of William W. Brown, a Fugitive Slave`
- Frances Ellen Watkins Harper, `Bury Me in a Free Land`

The Harper row is poem-level support, so it can count as work-level poem evidence. The Brown row is selection support only because the TOC lists `Chapter V` and `From Chapter VI`, so it does not close complete-work source debt.

| Metric | Count |
|---|---:|
| New source-item rows | 2 |
| New evidence rows | 2 |
| New accepted evidence rows | 2 |
| Match-candidate rows after rerun | 586 |
| Relation-scope rows after rerun | 7,588 |
| Omission rows ready for scoring review | 1 |
| Score-ready rows | 1 |

## Added Source Items

| Source item ID | Candidate | Scope decision |
|---|---|---|
| `e012_naal4_v1_harper_bury_me_free_land` | `work_candidate_source_aap_harper_bury_me_free_land` | poem-level inclusion support |
| `e012_naal4_v1_brown_narrative_william_w_brown` | `work_candidate_source_loa_brown_narrative` | representative selection support only |

## Gate Effects

`Bury Me in a Free Land` now has two accepted independent support families and no date, boundary, selection, or relation blockers. It is the first row in this build layer to reach `ready_for_score_computation`.

`Narrative of William W. Brown` remains blocked because the new Norton row is selection support. The complete-work candidate still needs additional independent complete-work support or a waiver.

## Source

Norton African American Literature 4e Volume 1 public TOC: `https://seagull.wwnorton.com/africanamericanlit4/TOC/V1`.

The PDF text extraction found the Brown entry under `WILLIAM WELLS BROWN (1814?-1884)` with chapter-level selections, and the Harper poem under `FRANCES E. W. HARPER (1825-1911)`.

## Validation

After adding the rows, X041 reran matching, relation review, relation scope, evidence generation, source debt, omission queue, scoring inputs, and `ruby scripts/canon_validate_build_layer.rb`. Validation passed.

## Next Actions

1. Build or activate score computation for the now-ready Harper row.
2. Continue targeted corroboration for `Abraham`, the three slave/confession narratives, `Curial e Guelfa`, and selection-only novel rows.
