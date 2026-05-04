# X050 Cut Review Work Orders

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X050 turns the 75-row X049 pair-review queue into cut-side work orders. The goal is to review each proposed cut candidate once, with all relevant add pairings attached, instead of repeating the same cut review across multiple pair rows.

## Output

- Added `scripts/canon_generate_cut_review_work_orders.rb`.
- Added `canon_cut_review_work_orders.tsv`.
- Updated validation so the work-order table is structurally checked.
- Generated 46 cut-review work orders.

Review focus summary:

| Review focus | Rows |
|---|---:|
| `generic_title_selection_basis;duplicate_cluster;source_debt` | 29 |
| `generic_title_selection_basis;source_debt` | 14 |
| `generic_title_selection_basis;duplicate_cluster;chronology;source_debt` | 1 |
| `duplicate_cluster;source_debt` | 1 |
| `generic_title_selection_basis;chronology;source_debt` | 1 |

Dominant cut-title clusters:

| Cut title | Rows |
|---|---:|
| `Selected Poems` | 10 |
| `Selected Stories` | 5 |
| `Selected Haiku` | 3 |
| `Poems` | 2 |
| `Selected Ci Poems` | 2 |
| `Selected Ghazals` | 2 |
| `"Odes"` | 1 |

## Interpretation

The queue is exposing a real structural problem: many plausible cuts are not bad works; they are generic selected-work rows with unresolved selection basis and no accepted source evidence in the build layer.

The next pass should review these as edition/selection-basis cases, not blindly remove them.

Direct public replacements: 0.
