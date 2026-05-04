# X056 Cut Evidence Item Decisions

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X056 adjudicates X054 source-item rescue rows at item level. This avoids accepting an entire grouped proposal when only some source items are scope-compatible.

## Output

- Added `scripts/canon_generate_cut_evidence_item_decisions.rb`.
- Added `canon_cut_evidence_item_decisions.tsv`.
- Generated 48 item-decision rows.

Item decision summary:

| Decision | Rows |
|---|---:|
| `blocked_high_scope_risk` | 19 |
| `blocked_named_collection_exact_support_required` | 4 |
| `existing_evidence_scope_review_required` | 2 |
| `needs_form_review_before_representative_evidence` | 2 |
| `ready_for_representative_selection_evidence_review` | 21 |

Evidence effect summary:

| Effect | Rows |
|---|---:|
| `may_generate_review_gated_representative_selection_evidence` | 21 |
| `may_update_existing_evidence_status_after_scope_review` | 2 |
| `no_evidence_change` | 25 |

Ready-for-review item rows:

| Decision ID | Cut title | Creator | Raw title | Source |
|---|---|---|---|---|
| `x056_cut_item_decision_0010` | Selected Poems | Carlos Drummond de Andrade | Os ombros suportam o mundo : your shoulders hold up the world ; O elefante : the elephant ; Desapareciemento de Luisa Porto : the disappearance of Luisa Porto ; Retrato de familia : family portrait ; Procura da poesia : looking for poetry | `e013_fsg_20c_latin_american_poetry_2011` |
| `x056_cut_item_decision_0011` | Selected Poems | Carlos Drummond de Andrade | This is that ; A passion for measure ; In the middle of the way ; F | `e013_oxford_latin_american_poetry_2009` |
| `x056_cut_item_decision_0012` | Selected Poems | Carlos Drummond de Andrade | In the Middle of the Road | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0013` | Poems | Catullus | 3 "Cry out lamenting, Venuses and Cupids" | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0014` | Poems | Catullus | 5 "Lesbia, let us live only for loving" | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0015` | Poems | Catullus | 13 "You will dine well with me, my dear Fabullus" | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0016` | Poems | Catullus | 51 "To me that man seems like a god in heaven" | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0017` | Poems | Catullus | 76 "If any pleasure can come to a man through recalling" | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0018` | Poems | Catullus | 107 "If ever something which someone with no expectation" | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0019` | Poems | Catullus | POEM | `norton_world_lit_5e_full_pre1650` |
| `x056_cut_item_decision_0024` | Poems | Giacomo Leopardi | The Infinite | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0026` | Odes | Horace | from Odes: 1.24: Why should our grief for a man so loved | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0029` | Odes | Horace | Ode 1.25 "The young bloods are not so eager now" | `longman_world_lit_2e_2009` |
| `x056_cut_item_decision_0030` | Odes | Horace | Ode 1.9 "Soracte standing white and deep" | `longman_world_lit_2e_2009` |

## Interpretation

This packet still does not write accepted evidence. It identifies which source items can proceed to evidence review and which remain blocked because they support a different form, a named collection only indirectly, or a high-risk membership question.

Direct public replacements: 0.
