# X Batch 26 Report: X042 Score-Ready Row Scoring

Date: 2026-05-03

Status: first provisional score generated; public canon unchanged.

## Summary

X042 adds `scripts/canon_generate_scores.rb` and generates `canon_scores.tsv` for rows already marked `ready_for_score_computation`.

Only one row is currently score-ready:

| Work ID | Title | Final score | Notes |
|---|---|---:|---|
| `work_candidate_source_aap_harper_bury_me_free_land` | Bury Me in a Free Land | 3.150 | Provisional source-backed score; no replacement action implied |

## Scoring Inputs

The Harper row has:

- two accepted independent support families,
- no relation-scope blocker,
- no date uncertainty,
- no open boundary or completion-scope flag,
- no source-debt penalty.

## Formula Scope

The first scoring generator is intentionally conservative:

- it scores only rows marked `ready_for_score_computation`,
- it derives support from accepted evidence rows,
- it uses source-item evidence weights where available,
- it keeps coverage-scarcity and balance bonuses at `0` until coverage targets are populated,
- it does not create add/cut replacement transactions.

## Validation

`ruby scripts/canon_generate_scores.rb` wrote 1 score row, and `ruby scripts/canon_validate_build_layer.rb` passed.

## Next Actions

1. Continue corroboration and boundary-review work to move more rows into `ready_for_score_computation`.
2. Build replacement-candidate logic only after more score-ready rows and coverage targets exist.
