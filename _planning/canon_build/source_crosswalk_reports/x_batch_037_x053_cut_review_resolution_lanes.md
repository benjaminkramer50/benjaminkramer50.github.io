# X053 Cut Review Resolution Lanes

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X053 splits the 50 X051 cut-side rows into actionable lanes: process existing source-item rescue rows first, then run external source acquisition for rows with no local support.

## Output

- Added `scripts/canon_generate_cut_review_resolution_lanes.rb`.
- Added `canon_cut_review_resolution_lanes.tsv`.
- Generated 50 resolution-lane rows.

Resolution lane summary:

| Lane | Rows |
|---|---:|
| `existing_source_item_rescue_review` | 17 |
| `external_source_acquisition` | 33 |

Top existing-source rescue rows:

| Resolution ID | Cut title | Creator | Rescue rows | Next action |
|---|---|---|---:|---|
| `x053_cut_resolution_0001` | Odes | Horace | 8 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0002` | Poems | Catullus | 7 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0003` | The Tenth Muse | Anne Bradstreet | 7 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0004` | Selected Poems | Carlos Drummond de Andrade | 3 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0005` | Selected Stories | Julio Cortazar | 3 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0006` | All Fires the Fire | Julio Cortazar | 3 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0007` | Blow-Up and Other Stories | Julio Cortazar | 3 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0008` | Collected Poems 1948-1984 | Derek Walcott | 3 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0009` | Poems | Giacomo Leopardi | 2 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0010` | Selected Poems | Mahmoud Darwish | 2 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0011` | Lyrics of Lowly Life | Paul Laurence Dunbar | 1 | `process_rescue_rows_before_external_search` |
| `x053_cut_resolution_0012` | Collected Poems | Primo Levi | 1 | `process_rescue_rows_before_external_search` |

Top external-source acquisition rows:

| Resolution ID | Cut title | Creator | Query |
|---|---|---|---|
| `x053_cut_resolution_0018` | Poems | Alcman | `"Alcman" "Poems" anthology literature canon` |
| `x053_cut_resolution_0019` | Odes | Pindar | `"Pindar" "Odes" anthology literature canon` |
| `x053_cut_resolution_0020` | Cold Mountain Poems | Hanshan | `"Hanshan" "Cold Mountain Poems" anthology literature canon` |
| `x053_cut_resolution_0021` | Selected Ci Poems | Xin Qiji | `"Xin Qiji" "Selected Ci Poems" anthology literature canon` |
| `x053_cut_resolution_0022` | Selected Ci Poems | Li Qingzhao | `"Li Qingzhao" "Selected Ci Poems" anthology literature canon` |
| `x053_cut_resolution_0023` | Selected Poems | Ibn al-Farid | `"Ibn al-Farid" "Selected Poems" anthology literature canon` |
| `x053_cut_resolution_0024` | Count Lucanor | Don Juan Manuel | `"Don Juan Manuel" "Count Lucanor" anthology literature canon` |
| `x053_cut_resolution_0025` | Selected Ghazals | Ali-Shir Nava'i | `"Ali-Shir Nava'i" "Selected Ghazals" anthology literature canon` |

## Interpretation

This packet does not approve cuts. It prevents the next work from branching randomly: first review source items already in the build layer, then source the genuinely unsupported rows.

Direct public replacements: 0.
