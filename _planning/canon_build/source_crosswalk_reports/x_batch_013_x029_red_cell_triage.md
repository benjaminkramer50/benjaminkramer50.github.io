# X Batch 13 Report: X029 Red-Cell Queue Triage

Date: 2026-05-03

Status: triage generated; public canon unchanged.

## Summary

X029 classifies every row in `canon_red_cell_audit_queue.tsv` so the next pass can review specific actions instead of manually searching the raw source tables.

| Triage class | Rows |
|---|---:|
| coverage_cell_review | 3 |
| existing_current_match_or_alias_gap | 1 |
| homonymous_title_collision_review | 17 |
| possible_variant_alias_to_current_work | 2 |
| source_backed_omission_candidate | 40 |
| source_debt_and_taxonomy_pressure | 8 |
| subwork_or_selection_scope_review | 49 |

| Confidence | Rows |
|---|---:|
| high | 1 |
| medium | 119 |

## Top Triage Rows

| Queue | Class | Confidence | Subject | Action |
|---|---|---|---|---|
| x028_red_0001 | homonymous_title_collision_review | medium | Fireflies | split_by_creator_before_candidate_creation |
| x028_red_0002 | source_backed_omission_candidate | medium | Invitation to the Voyage | manual_match_or_create_candidate_review |
| x028_red_0003 | possible_variant_alias_to_current_work | medium | Kubla Khan | manual_variant_alias_review |
| x028_red_0004 | homonymous_title_collision_review | medium | "A Peacock Southeast Flew" / A Peacock Southeast Flew | split_by_creator_before_candidate_creation |
| x028_red_0005 | subwork_or_selection_scope_review | medium | "Deer Enclosure" / Deer Enclosure | review_scope_before_candidate_creation |
| x028_red_0006 | homonymous_title_collision_review | medium | "Midnight Songs" / Midnight Songs | split_by_creator_before_candidate_creation |
| x028_red_0007 | homonymous_title_collision_review | medium | "The Ballad of Mulan" / Ballad of Mulan | split_by_creator_before_candidate_creation |
| x028_red_0008 | subwork_or_selection_scope_review | medium | "The Song of Lasting Regret" / The Song of Lasting Regret | review_scope_before_candidate_creation |
| x028_red_0009 | subwork_or_selection_scope_review | medium | 5 "Lesbia, let us live only for loving" / 5 [Lesbia, let us live only for loving] | review_scope_before_candidate_creation |
| x028_red_0010 | subwork_or_selection_scope_review | medium | 51 "To me that man seems like a god in heaven" / 51 [To me that man seems like a god in heaven] | review_scope_before_candidate_creation |
| x028_red_0011 | subwork_or_selection_scope_review | medium | 76 "If any pleasure can come to a man through recalling" / 76 [If any pleasure can come to a man through recalling] | review_scope_before_candidate_creation |
| x028_red_0012 | source_backed_omission_candidate | medium | A Martyr / The Martyr | manual_match_or_create_candidate_review |
| x028_red_0013 | source_backed_omission_candidate | medium | Agamemnon / AGAMEMNON | manual_match_or_create_candidate_review |
| x028_red_0014 | subwork_or_selection_scope_review | medium | Akashi | review_scope_before_candidate_creation |
| x028_red_0015 | subwork_or_selection_scope_review | medium | An Autumn Excursion | review_scope_before_candidate_creation |
| x028_red_0016 | subwork_or_selection_scope_review | medium | An Old and Established Name | review_scope_before_candidate_creation |
| x028_red_0017 | subwork_or_selection_scope_review | medium | Atsumori | review_scope_before_candidate_creation |
| x028_red_0018 | homonymous_title_collision_review | medium | Autumn Night / The autumn night | split_by_creator_before_candidate_creation |
| x028_red_0019 | source_backed_omission_candidate | medium | Begging for Food | manual_match_or_create_candidate_review |
| x028_red_0020 | source_backed_omission_candidate | medium | Bells of Gion Monastery / The Bells of Gion Monastery | manual_match_or_create_candidate_review |
| x028_red_0021 | subwork_or_selection_scope_review | medium | Bring in the Wine | review_scope_before_candidate_creation |
| x028_red_0022 | source_backed_omission_candidate | medium | Byzantium | manual_match_or_create_candidate_review |
| x028_red_0023 | source_backed_omission_candidate | medium | Central Park | manual_match_or_create_candidate_review |
| x028_red_0024 | source_backed_omission_candidate | medium | Correspondences | manual_match_or_create_candidate_review |
| x028_red_0025 | subwork_or_selection_scope_review | medium | Delicious Poison | review_scope_before_candidate_creation |

## Interpretation

This is a routing layer, not a final canon decision. A high-confidence omission candidate still needs source scope, boundary, duplicate, and coverage review before any public-path change. A variant row should usually resolve as an alias or match-decision update, not a new work.

## Next Actions

1. Review `source_backed_omission_candidate` rows that look like complete works before poem/excerpt rows.
2. Review `possible_variant_alias_to_current_work` and `existing_current_match_or_alias_gap` rows before creating candidates.
3. Split `homonymous_title_collision_review` rows by creator before treating repeated bare titles as omissions.
4. Use coverage and source-debt rows to open focused C/D/I audits after the title-level rows.
