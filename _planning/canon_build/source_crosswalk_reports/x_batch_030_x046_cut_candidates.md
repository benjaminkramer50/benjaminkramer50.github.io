# X046 Cut Candidate Risk Table

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X046 creates an all-incumbent cut-risk table so replacement review can use explicit risk signals rather than arbitrary manual cuts.

This is not a cut list. It is a review-priority table. Core rows are protected for special review, and no row can be paired with an add candidate without later manual/automated gate checks.

## Output

- Added `scripts/canon_generate_cut_candidates.rb`.
- Wrote `canon_cut_candidates.tsv` with 3,000 selected incumbent rows.

Gate summary:

| Gate status | Rows |
|---|---:|
| `high_cut_review_priority` | 239 |
| `medium_cut_review_priority` | 2,421 |
| `low_cut_review_priority` | 122 |
| `protected_core_review_required` | 218 |

## Risk Signals

Each row records:

- source-debt status and evidence count,
- generic-title flag,
- duplicate-cluster key and size,
- chronology issue count,
- boundary-case flag,
- tier/source/review status,
- composite risk score.

The current top rows are dominated by generic duplicate clusters such as `Selected Poems`. That does not mean those rows should be cut automatically; it means they require edition/selection-basis review before any add/cut transaction is proposed.

## Remaining Gate

The next safe step is add/cut pairing under strict blocked status:

- pair only score-ready add candidates with high-priority cut-review rows,
- keep pair rows blocked unless the cut is non-core or has explicit waiver,
- require duplicate, author-cluster, chronology, boundary, and path-count checks before `ready_for_review`.

## Validation

`ruby scripts/canon_validate_build_layer.rb` passed after writing the cut-risk table.

Direct public replacements: 0.
