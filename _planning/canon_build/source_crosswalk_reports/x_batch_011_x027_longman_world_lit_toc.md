# X Batch 11 Report: X027 Longman World Literature 2e TOC Extraction

Date: 2026-05-03

Status: source items ingested; X013/X014/X017 rerun; public canon unchanged.

## Summary

X027 extracted public table-of-contents rows for `longman_world_lit_2e_2009`, covering Volumes A-F of *The Longman Anthology of World Literature*, 2nd ed. Pearson's public product-page `tableOfContents` JSON was used where accessible. Volumes B and C were extracted from eCampus product-page TOC tables whose page labels the TOC as publisher-provided, because Pearson live public B/C TOC access was uneven.

These rows expand the source-evidence universe only. They do not authorize additions, cuts, or score changes until X013/X014/X017 review gates and source-debt/scope blockers are resolved.

## Extraction Counts

| Volume | Source provenance | Rows |
|---|---|---:|
| A | Pearson public product page tableOfContents JSON | 314 |
| B | eCampus public product page publisher-provided table of contents | 367 |
| C | eCampus public product page publisher-provided table of contents | 293 |
| D | Pearson public product page tableOfContents JSON | 118 |
| E | Pearson public product page tableOfContents JSON | 258 |
| F | Pearson public product page tableOfContents JSON | 294 |

Total source-item rows added or replaced: 1644

## Provisional Matching

| Match status | Rows |
|---|---:|
| matched_current_path | 68 |
| represented_by_selection | 44 |
| unmatched | 1532 |

| Evidence type | Rows |
|---|---:|
| boundary_context | 443 |
| inclusion | 913 |
| representative_selection | 288 |

Provisional exact matches use unique normalized title/alias matches only. They remain provisional until the expanded match, relation, evidence, and source-debt queues are rerun.

After rerunning X013/X014/X017, the Longman rows generated 112 policy-aware evidence rows. The global build now has 468 evidence rows, 5,474 match-review decisions, and 7,567 relation-scope rows; no public path rows changed.

## Source Limits

- Volumes A/D/E/F are Pearson-direct public TOC JSON rows.
- Volumes B/C are public retailer-hosted TOC tables marked as publisher-provided; they are useful for source discovery but should be reviewed before any high-stakes boundary decision.
- The Longman TOC mixes complete works, excerpts, poem selections, author headings, translations features, resonances, perspectives, and crosscurrents. The script marks obvious structure rows as `boundary_context` and obvious excerpts as `representative_selection`, but final scope remains gated.
- No public `_data/canon_quick_path.yml` row changed.

## Next Actions

1. Review Longman rows that exact-match current path titles but may be selections/excerpts.
2. Continue E006 Bedford fragment extraction only as partial anchor evidence unless a complete authorized TOC is found.
