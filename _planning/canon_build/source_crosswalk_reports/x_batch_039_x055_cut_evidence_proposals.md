# X055 Cut Evidence Proposals

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X055 groups only medium-risk X054 rescue rows into evidence proposals. It does not accept evidence; it identifies the rows that can move next after manual scope acceptance.

## Output

- Added `scripts/canon_generate_cut_evidence_proposals.rb`.
- Added `canon_cut_evidence_proposals.tsv`.
- Generated 16 grouped evidence proposal rows.
- High-risk X054 rows skipped: 19.

Proposal class summary:

| Scope class | Proposals |
|---|---:|
| `existing_linked_selection_evidence_review` | 2 |
| `representative_poetry_selection_review` | 12 |
| `title_family_match_ode_source_item` | 2 |

Top proposals:

| Proposal ID | Cut title | Creator | Source | Items | Gate |
|---|---|---|---|---:|---|
| `x055_cut_evidence_0001` | Poems | Catullus | `longman_world_lit_2e_2009` | 6 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0002` | Odes | Horace | `longman_world_lit_2e_2009` | 5 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0003` | Collected Poems 1948-1984 | Derek Walcott | `longman_world_lit_2e_2009` | 3 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0004` | Poems | Giacomo Leopardi | `longman_world_lit_2e_2009` | 2 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0005` | Selected Poems | Mahmoud Darwish | `longman_world_lit_2e_2009` | 2 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0006` | Selected Poems | Carlos Drummond de Andrade | `e013_fsg_20c_latin_american_poetry_2011` | 1 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0007` | Selected Poems | Carlos Drummond de Andrade | `e013_oxford_latin_american_poetry_2009` | 1 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0008` | Selected Poems | Carlos Drummond de Andrade | `longman_world_lit_2e_2009` | 1 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0009` | Poems | Catullus | `norton_world_lit_5e_full_pre1650` | 1 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0010` | Odes | Horace | `norton_world_lit_5e_full_pre1650` | 1 | `manual_scope_acceptance_required` |
| `x055_cut_evidence_0011` | The Weary Blues and Selected Poems | Langston Hughes | `e012_loa_african_american_poetry_2020` | 1 | `review_existing_evidence_before_acceptance` |
| `x055_cut_evidence_0012` | Selected Poems | Nazim Hikmet | `longman_world_lit_2e_2009` | 1 | `manual_scope_acceptance_required` |

## Interpretation

These proposals are not accepted evidence. They are the next safe review set: medium-risk source rows that may become cut-side representative-selection evidence without touching high-risk collection-membership or form-mismatch cases.

Direct public replacements: 0.
