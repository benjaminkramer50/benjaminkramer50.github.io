# X044 Coverage Targets

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X044 turns the X028 diagnostic coverage matrix into machine-readable review targets and lets provisional scores include a capped coverage-scarcity bonus.

These targets are not hard quotas and do not authorize replacements. They are ranking priors for already score-ready candidates.

## Outputs

- Added `scripts/canon_generate_coverage_targets.rb`.
- Regenerated `canon_coverage_targets.yml` with 72 medium/high-risk review targets.
- Updated `scripts/canon_generate_scores.rb` to read coverage targets.
- Regenerated `canon_scores.tsv`.

## Scoring Policy

Coverage bonuses are deliberately conservative because many incumbent rows still use inferred taxonomy in the diagnostic matrix.

- Max single target bonus: `0.40`.
- Max total coverage-scarcity score bonus: `0.40`.
- Replacement authority: none.

## Current Scores

| Work ID | Title | Coverage bonus | Final score |
|---|---|---:|---:|
| `work_candidate_source_broadview_hrotsvitha_abraham` | `Abraham` | 0.400 | 2.900 |
| `work_candidate_source_aap_harper_bury_me_free_land` | `Bury Me in a Free Land` | 0.400 | 3.550 |
| `work_candidate_source_loa_brown_narrative` | `Narrative of William W. Brown, A Fugitive Slave. Written by Himself` | 0.400 | 4.350 |
| `work_candidate_source_loa_gronniosaw_narrative` | `Narrative of James Albert Ukawsaw Gronniosaw` | 0.400 | 3.400 |
| `work_candidate_source_loa_nat_turner_confessions` | `The Confessions of Nat Turner` | 0.400 | 3.400 |

## Validation

`ruby scripts/canon_validate_build_layer.rb` passed after target generation and score regeneration.

Direct public replacements: 0.
