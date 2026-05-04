# X049 Pair Review Queue

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X049 reduces the 1,185 blocked X047/X048 pair rows to a bounded review queue. This is a triage artifact, not a replacement approval.

The queue keeps all five score-ready add candidates represented while limiting repeated cut-title clusters.

## Output

- Added `scripts/canon_generate_pair_review_queue.rb`.
- Added `canon_replacement_pair_review_queue.tsv`.
- Updated validation so the queue is structurally checked.
- Generated 75 review rows.

Review bucket summary:

| Review bucket | Rows |
|---|---:|
| `generic_duplicate_cluster_first` | 42 |
| `source_debt_first` | 27 |
| `chronology_first` | 4 |
| `duplicate_cluster_first` | 2 |

Add-candidate representation:

| Add candidate | Rows |
|---|---:|
| `Narrative of William W. Brown, A Fugitive Slave. Written by Himself` | 15 |
| `Bury Me in a Free Land` | 15 |
| `Narrative of James Albert Ukawsaw Gronniosaw` | 15 |
| `The Confessions of Nat Turner` | 15 |
| `Abraham` | 15 |

The top cut-title clusters are capped, so `Selected Poems` does not consume the whole review queue.

## Remaining Gate

Every queue row still has `next_action=manual_pair_review_before_any_ready_for_review_promotion`. No row is promoted to public replacement review.

Direct public replacements: 0.
