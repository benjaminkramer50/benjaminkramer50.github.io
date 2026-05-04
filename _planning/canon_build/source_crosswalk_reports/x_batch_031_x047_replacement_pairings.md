# X047 Blocked Replacement Pairings

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X047 pairs score-ready add candidates with high-priority cut-review rows so the replacement table can support concrete review work. Every generated row remains blocked.

This is not an integration packet and not an approval to cut any incumbent.

## Output

- Added `scripts/canon_generate_replacement_pairings.rb`.
- Regenerated `canon_replacement_candidates.tsv` with 1,185 blocked pair rows.
- Pairing universe: 5 score-ready add candidates x 237 high-priority cut-review candidates.

Gate summary:

| Gate status | Rows |
|---|---:|
| `blocked` | 1,185 |

## Pairing Rules

Rows are generated only from:

- X045 score-ready add-candidate prefilter rows,
- X046 `high_cut_review_priority` rows,
- non-approved cut-risk signals.

Rows remain blocked because:

- cut scores are not computed,
- duplicate and author-cluster checks are pending,
- chronology/path-position checks are pending,
- boundary checks are only flagged, not resolved,
- no path-count-preserving public transaction exists.

## Validation

`ruby scripts/canon_validate_build_layer.rb` passed after writing the blocked pair rows.

Direct public replacements: 0.
