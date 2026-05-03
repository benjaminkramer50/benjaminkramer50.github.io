# X054 Cut Rescue Scope Review

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X054 reviews the X052 rescue rows for scope risk. A creator-exact source item is not automatically evidence for a selected collection, named collection, or generic title.

## Output

- Added `scripts/canon_generate_cut_rescue_scope_review.rb`.
- Added `canon_cut_rescue_scope_review.tsv`.
- Generated 48 scope-review rows.

Scope class summary:

| Scope class | Rows |
|---|---:|
| `creator_only_form_mismatch` | 2 |
| `existing_linked_selection_evidence_review` | 2 |
| `named_collection_membership_review` | 7 |
| `representative_poetry_selection_review` | 21 |
| `story_collection_membership_review` | 10 |
| `title_family_match_ode_source_item` | 6 |

Scope risk summary:

| Risk | Rows |
|---|---:|
| `high` | 19 |
| `medium` | 29 |

High-risk rows needing membership or form review:

| Scope review ID | Cut title | Creator | Raw title | Class |
|---|---|---|---|---|
| `x054_cut_scope_0003` | The Tenth Muse | Anne Bradstreet | The Author to Her Book | `named_collection_membership_review` |
| `x054_cut_scope_0004` | The Tenth Muse | Anne Bradstreet | To my Dear and Loving Husband | `named_collection_membership_review` |
| `x054_cut_scope_0005` | The Tenth Muse | Anne Bradstreet | A Letter to Her Husband, Absent upon Public Employment | `named_collection_membership_review` |
| `x054_cut_scope_0006` | The Tenth Muse | Anne Bradstreet | Before the Birth of One of Her Children | `named_collection_membership_review` |
| `x054_cut_scope_0007` | The Tenth Muse | Anne Bradstreet | Upon the Burning of Our House, July 10th, 1666 | `named_collection_membership_review` |
| `x054_cut_scope_0008` | The Tenth Muse | Anne Bradstreet | On My Dear Grand-child Simon Bradstreet | `named_collection_membership_review` |
| `x054_cut_scope_0009` | The Tenth Muse | Anne Bradstreet | To My Dear Children | `named_collection_membership_review` |
| `x054_cut_scope_0023` | Selected Stories | Felisberto Hernandez | The daisy dolls | `story_collection_membership_review` |
| `x054_cut_scope_0027` | Odes | Horace | Satire 1.8 "Once I was wood from a worthless old fig tree" | `creator_only_form_mismatch` |
| `x054_cut_scope_0028` | Odes | Horace | Satire 1.5 "Leaving the big city behind I found lodgings at Aricia" | `creator_only_form_mismatch` |
| `x054_cut_scope_0034` | Blow-Up and Other Stories | Julio Cortazar | Para leer en forma interrogative : to be read in the interrogative | `story_collection_membership_review` |
| `x054_cut_scope_0035` | Selected Stories | Julio Cortazar | Para leer en forma interrogative : to be read in the interrogative | `story_collection_membership_review` |

## Interpretation

This packet keeps the rescue lane conservative: source items may support representative selection evidence, but collection membership and form mismatches must be resolved before any cut-side score changes.

Direct public replacements: 0.
