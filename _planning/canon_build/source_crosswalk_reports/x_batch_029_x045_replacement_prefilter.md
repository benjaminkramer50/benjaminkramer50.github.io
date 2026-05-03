# X045 Replacement Prefilter

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X045 creates a blocked replacement-candidate prefilter from score-ready source-backed candidates. This is not an integration packet: it ranks possible additions but deliberately leaves cut fields blank until cut-candidate logic, score deltas, duplicate checks, chronology checks, and path-count validation are generated.

## Output

- Added `scripts/canon_generate_replacement_prefilter.rb`.
- Wrote 5 rows to `canon_replacement_candidates.tsv`.
- All rows have `gate_status=blocked`.
- All cut fields are intentionally blank.

## Prefilter Ranking

| Rank | Add candidate | Score delta field | Gate |
|---:|---|---:|---|
| 1 | `Narrative of William W. Brown, A Fugitive Slave. Written by Himself` | `+4.350 before_cut_score` | blocked |
| 2 | `Bury Me in a Free Land` | `+3.550 before_cut_score` | blocked |
| 3 | `Narrative of James Albert Ukawsaw Gronniosaw` | `+3.400 before_cut_score` | blocked |
| 4 | `The Confessions of Nat Turner` | `+3.400 before_cut_score` | blocked |
| 5 | `Abraham` | `+2.900 before_cut_score` | blocked |

## Remaining Gate

The next safe step is cut-candidate generation. A public replacement transaction still requires:

- a named cut work,
- score comparison against that cut,
- duplicate and author-cluster review,
- chronology/path-position validation,
- boundary policy confirmation,
- a 3,000-row path-count-preserving transaction.

## Validation

`ruby scripts/canon_validate_build_layer.rb` passed after writing the prefilter rows.

Direct public replacements: 0.
