# X043 Reference Corroboration

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X043 added targeted public reference and literary-history corroboration for source-backed candidates whose only accepted evidence was previously internal, single-family, selection-only, or bibliographic identity support.

This batch does not add anything to the public 3,000-work path. It only closes source debt or advances scoring readiness where the existing gates allow it.

## Sources Added

| Source ID | Source | Scope |
|---|---|---|
| `x043_encyclopedia_com_hrotsvit_reference` | Encyclopedia.com Hrotsvit entry | Work-specific reference support for Hrotsvitha's `Abraham` |
| `x043_britannica_abolitionist_texts_reference` | Britannica, "8 Influential Abolitionist Texts" | Work-specific reference support for William Wells Brown's narrative |
| `x043_yale_british_art_gronniosaw_reference` | Yale Center for British Art record | Reference/collection record for Gronniosaw's narrative |
| `x043_britannica_nat_turner_confessions_reference` | Britannica, `The Confessions of Nat Turner` | Work-specific reference support for Nat Turner/Thomas R. Gray |
| `x043_britannica_catalan_literature_reference` | Britannica, `Catalan literature` | Literary-history support for `Curial e Guelfa` |
| `x043_enciclopedia_cat_curial_reference` | Enciclopedia.cat, `Curial e Guelfa` | Catalan reference support for `Curial e Guelfa` |

## Rows Added Or Updated

- Added 6 source registry rows.
- Added 6 source item rows.
- Generated and accepted 6 policy-aware evidence rows.
- Added an explicit relation-scope outcome for reviewed same-work source-title variants.
- Routed William Wells Brown and Nat Turner LOA title variants as same-work aliases rather than unresolved duplicate risks.
- Updated scoring-input generation so confirmed same-work aliases, source-container rows, and selection-scope rows do not create false relation blockers.

## Scoring Result

After regeneration:

- `canon_source_items.tsv`: 5,950 rows.
- `canon_evidence.tsv`: 503 rows.
- `canon_source_debt_status.tsv`: 10 rows closed by independent external support.
- `canon_omission_queue.tsv`: 5 rows ready for scoring review, 7 not ready.
- `canon_scoring_inputs.tsv`: 5 rows ready for score computation, 3,007 blocked.
- `canon_scores.tsv`: 5 provisional score rows.

Ready/scored rows:

| Work ID | Title | Evidence rows | Final score |
|---|---:|---:|---:|
| `work_candidate_source_broadview_hrotsvitha_abraham` | `Abraham` | 2 | 2.500 |
| `work_candidate_source_aap_harper_bury_me_free_land` | `Bury Me in a Free Land` | 2 | 3.150 |
| `work_candidate_source_loa_brown_narrative` | `Narrative of William W. Brown, A Fugitive Slave. Written by Himself` | 3 | 3.950 |
| `work_candidate_source_loa_gronniosaw_narrative` | `Narrative of James Albert Ukawsaw Gronniosaw` | 2 | 3.000 |
| `work_candidate_source_loa_nat_turner_confessions` | `The Confessions of Nat Turner` | 2 | 3.000 |

`Curial e Guelfa` now has closed source debt, but remains blocked by omission/boundary/completion-scope gates. That is intentional; bibliographic and literary-history corroboration does not by itself resolve final canon-boundary policy.

## Validation

`ruby scripts/canon_validate_build_layer.rb` passed after regenerating match, relation-scope, source-debt, omission, scoring-input, and score tables.

Direct public replacements: 0.
