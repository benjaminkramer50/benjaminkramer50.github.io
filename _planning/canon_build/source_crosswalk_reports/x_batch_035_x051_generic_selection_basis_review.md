# X051 Generic Selection-Basis Review

Status: completed, build-layer only. Public canon path unchanged.

## Purpose

X051 reviews the current X050 cut-side work orders as selection-basis and source-support problems. The point is to avoid treating generic selected-work rows as easy cuts before their identity, edition/selection basis, and evidence state are checked.

## Output

- Added `scripts/canon_generate_generic_selection_basis_review.rb`.
- Added `canon_generic_selection_basis_review.tsv`.
- Generated 45 review rows from X050 work orders.
- Rows with alias support: 5.
- Rows with matched source items: 2.
- Generic-title rows without accepted evidence: 42.

Selection-basis status summary:

| Status | Rows |
|---|---:|
| `generic_title_has_evidence_selection_basis_review_required` | 2 |
| `generic_title_unresolved_no_source_support` | 42 |
| `non_generic_source_support_unresolved` | 1 |

Recommended resolution summary:

| Resolution | Rows |
|---|---:|
| `extract_or_accept_cut_side_source_support_before_cut_decision` | 1 |
| `hold_cut_pairing_until_selection_basis_and_external_support_are_verified` | 42 |
| `review_whether_row_is_collection_or_representative_selection` | 2 |

Highest-priority unresolved rows:

| Review ID | Cut title | Creator | Status | Next action |
|---|---|---|---|---|
| `x051_selection_basis_0001` | Selected Poems | Henry Wadsworth Longfellow | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0002` | Selected Poems | Archilochus | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0003` | Selected Poems | Cao Cao | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0004` | Selected Poems | Cao Zhi | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0005` | Selected Poems | Ruan Ji | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0006` | Selected Poems | Bao Zhao | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0007` | Selected Poems | Tao Yuanming | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0008` | Selected Poems | Briceida Cuevas Cob | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0009` | Selected Poems | Humberto Ak'abal | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |
| `x051_selection_basis_0010` | Selected Poems | Hubert Matiuwaa | `generic_title_unresolved_no_source_support` | `find_author_work_specific_source_or_mark_cut_basis_unresolved` |

## Interpretation

These rows are not approved cuts. X051 turns the highest-risk work orders into a concrete review queue: verify whether the incumbent is a canonical collection, a representative selection, an anthology convenience label, or an under-sourced duplicate-cluster row before any replacement pair can advance.

Direct public replacements: 0.
