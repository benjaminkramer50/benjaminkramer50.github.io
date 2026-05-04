# X058 Cut Evidence Apply

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X058 applies the review-gated X057 write plan to `canon_evidence.tsv` as accepted representative-selection evidence and links the relevant source items to their cut-side work candidates. Representative-selection evidence does not close complete-work source debt under the current source-debt rules.

## Output

- Added `scripts/canon_apply_cut_evidence_write_plan.rb`.
- Added `canon_cut_evidence_applied_rows.tsv`.
- Confirmed 21 evidence rows present after apply.

Evidence action summary:

| Action | Rows |
|---|---:|
| `evidence_present_after_apply` | 21 |

Applied evidence rows:

| Applied ID | Work | Source item | Evidence ID |
|---|---|---|---|
| `x058_cut_evidence_apply_0001` | `work_candidate_latcarib_lit_drummond_poems` | `e013_fsg20c_025_carlos_drummond_de_andrade_os_ombros_suportam_o_mundo_your_shoulders_h` | `x057_ev_e013_fsg20c_025_carlos_drummond_de_andrade_os_ombros_suportam_o_mundo_your_shoulders_h` |
| `x058_cut_evidence_apply_0002` | `work_candidate_latcarib_lit_drummond_poems` | `e013_oblap_054_carlos_drummond_de_andrade_this_is_that_a_passion_for_measure_in_the_m` | `x057_ev_e013_oblap_054_carlos_drummond_de_andrade_this_is_that_a_passion_for_measure_in_the_m` |
| `x058_cut_evidence_apply_0003` | `work_candidate_latcarib_lit_drummond_poems` | `longman2e_volf_058_carlos_drummond_de_andrade_in_the_middle_of_the_road` | `x057_ev_longman2e_volf_058_carlos_drummond_de_andrade_in_the_middle_of_the_road` |
| `x058_cut_evidence_apply_0004` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_267_catullus_3_cry_out_lamenting_venuses_and_cupids` | `x057_ev_longman2e_vola_267_catullus_3_cry_out_lamenting_venuses_and_cupids` |
| `x058_cut_evidence_apply_0005` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_268_catullus_5_lesbia_let_us_live_only_for_loving` | `x057_ev_longman2e_vola_268_catullus_5_lesbia_let_us_live_only_for_loving` |
| `x058_cut_evidence_apply_0006` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_269_catullus_13_you_will_dine_well_with_me_my_dear_fabullus` | `x057_ev_longman2e_vola_269_catullus_13_you_will_dine_well_with_me_my_dear_fabullus` |
| `x058_cut_evidence_apply_0007` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_270_catullus_51_to_me_that_man_seems_like_a_god_in_heaven` | `x057_ev_longman2e_vola_270_catullus_51_to_me_that_man_seems_like_a_god_in_heaven` |
| `x058_cut_evidence_apply_0008` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_271_catullus_76_if_any_pleasure_can_come_to_a_man_through_recalling` | `x057_ev_longman2e_vola_271_catullus_76_if_any_pleasure_can_come_to_a_man_through_recalling` |
| `x058_cut_evidence_apply_0009` | `work_candidate_bloom_catullus_poems` | `longman2e_vola_272_catullus_107_if_ever_something_which_someone_with_no_expectation` | `x057_ev_longman2e_vola_272_catullus_107_if_ever_something_which_someone_with_no_expectation` |
| `x058_cut_evidence_apply_0010` | `work_candidate_bloom_catullus_poems` | `nawol5e_vola_143_catullus_poem` | `x057_ev_nawol5e_vola_143_catullus_poem` |
| `x058_cut_evidence_apply_0011` | `work_candidate_bloom_leopardi_poems` | `longman2e_vole_031_giacomo_leopardi_the_infinite` | `x057_ev_longman2e_vole_031_giacomo_leopardi_the_infinite` |
| `x058_cut_evidence_apply_0012` | `work_candidate_bloom_horace_odes` | `longman2e_vola_244_horace_from_odes_1_24_why_should_our_grief_for_a_man_so_loved` | `x057_ev_longman2e_vola_244_horace_from_odes_1_24_why_should_our_grief_for_a_man_so_loved` |
| `x058_cut_evidence_apply_0013` | `work_candidate_bloom_horace_odes` | `longman2e_vola_277_horace_ode_1_25_the_young_bloods_are_not_so_eager_now` | `x057_ev_longman2e_vola_277_horace_ode_1_25_the_young_bloods_are_not_so_eager_now` |
| `x058_cut_evidence_apply_0014` | `work_candidate_bloom_horace_odes` | `longman2e_vola_278_horace_ode_1_9_soracte_standing_white_and_deep` | `x057_ev_longman2e_vola_278_horace_ode_1_9_soracte_standing_white_and_deep` |
| `x058_cut_evidence_apply_0015` | `work_candidate_bloom_horace_odes` | `longman2e_vola_279_horace_ode_2_13_not_only_did_he_plant_you_on_an_unholy_day` | `x057_ev_longman2e_vola_279_horace_ode_2_13_not_only_did_he_plant_you_on_an_unholy_day` |
| `x058_cut_evidence_apply_0016` | `work_candidate_bloom_horace_odes` | `longman2e_vola_280_horace_ode_2_14_ah_how_quickly_postumus_postumus` | `x057_ev_longman2e_vola_280_horace_ode_2_14_ah_how_quickly_postumus_postumus` |

## Interpretation

This improves cut-side evidence accounting but still does not approve any cut or replacement. Source debt remains selection-only unless complete-work or independently closing inclusion evidence is added.

Direct public replacements: 0.
