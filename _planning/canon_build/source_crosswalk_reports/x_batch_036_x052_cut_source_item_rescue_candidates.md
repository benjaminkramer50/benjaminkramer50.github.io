# X052 Cut Source-Item Rescue Candidates

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X052 mines the existing extracted source-item table for source rows that can rescue X051 cut-side work orders from an apparent no-source-support state. This is still a review queue; it does not accept evidence or approve cuts.

## Output

- Added `scripts/canon_generate_cut_source_item_rescue_candidates.rb`.
- Added `canon_cut_source_item_rescue_candidates.tsv`.
- Generated 48 rescue candidate rows.
- High-confidence rescue rows: 48.

Rescue rule summary:

| Rule | Rows |
|---|---:|
| `creator_exact_unmatched_source_item` | 46 |
| `source_item_already_linked_to_cut` | 2 |

Work-order coverage:

| Cut title | Creator | Rescue rows |
|---|---|---:|
| Odes | Horace | 8 |
| Poems | Catullus | 7 |
| The Tenth Muse | Anne Bradstreet | 7 |
| Collected Poems 1948-1984 | Derek Walcott | 3 |
| Blow-Up and Other Stories | Julio Cortazar | 3 |
| All Fires the Fire | Julio Cortazar | 3 |
| Selected Poems | Carlos Drummond de Andrade | 3 |
| Selected Stories | Julio Cortazar | 3 |
| Selected Poems | Mahmoud Darwish | 2 |
| Poems | Giacomo Leopardi | 2 |
| Collected Poems | Primo Levi | 1 |
| Lyrics of Lowly Life | Paul Laurence Dunbar | 1 |

## Interpretation

The source table already contains some rows that can unblock cut-side evidence review. These rows should be routed through match/scope review first, especially poetry selections where source items are individual poems rather than whole collection titles.

Direct public replacements: 0.
