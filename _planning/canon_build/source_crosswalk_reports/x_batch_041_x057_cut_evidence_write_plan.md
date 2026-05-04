# X057 Cut Evidence Write Plan

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X057 turns X056 ready item decisions into a proposed evidence write plan. It does not modify `canon_evidence.tsv`; each row is review-gated.

## Output

- Added `scripts/canon_generate_cut_evidence_write_plan.rb`.
- Added `canon_cut_evidence_write_plan.tsv`.
- Generated 21 evidence write-plan rows.

Target action summary:

| Target action | Rows |
|---|---:|
| `create_new_evidence_after_review` | 21 |

Evidence strength summary:

| Strength | Rows |
|---|---:|
| `moderate` | 21 |

First planned writes:

| Write plan ID | Work | Source item | Action | Gate |
|---|---|---|---|---|
| `x057_cut_evidence_write_0001` | `work_candidate_latcarib_lit_drummond_poems` | `e013_fsg20c_025_carlos_drummond_de_andrade_os_ombros_suportam_o_mundo_your_shoulders_h` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0002` | `work_candidate_latcarib_lit_drummond_poems` | `e013_oblap_054_carlos_drummond_de_andrade_this_is_that_a_passion_for_measure_in_the_m` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0003` | `work_candidate_latcarib_lit_drummond_poems` | `longman2e_volf_058_carlos_drummond_de_andrade_in_the_middle_of_the_road` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0004` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_267_catullus_3_cry_out_lamenting_venuses_and_cupids` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0005` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_268_catullus_5_lesbia_let_us_live_only_for_loving` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0006` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_269_catullus_13_you_will_dine_well_with_me_my_dear_fabullus` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0007` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_270_catullus_51_to_me_that_man_seems_like_a_god_in_heaven` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0008` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_271_catullus_76_if_any_pleasure_can_come_to_a_man_through_recalling` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0009` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_272_catullus_107_if_ever_something_which_someone_with_no_expectation` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0010` | `work_candidate_bloom_catullus_poems` | `nawol5e_vola_143_catullus_poem` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0011` | `work_candidate_bloom_leopardi_poems` | `longman2e_vole_031_giacomo_leopardi_the_infinite` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |
| `x057_cut_evidence_write_0012` | `work_candidate_bloom_horace_odes` | `longman2e_vola_244_horace_from_odes_1_24_why_should_our_grief_for_a_man_so_loved` | `create_new_evidence_after_review` | `review_required_before_evidence_table_update` |

## Interpretation

This is a staging table. The evidence ledger should be updated only after review acceptance, then source debt and cut-side scoring can be recomputed.

Direct public replacements: 0.
