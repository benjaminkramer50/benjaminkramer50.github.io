# X023 Remaining Partial Source Cleanup

- status: source_items_ingested_matching_required
- generated_rows: 334
- replaced_sources: 5
- direct_public_path_changes: 0
- direct_evidence_rows_added_by_ingester: 0
- evidence_rows_after_x013_x014_x017_rerun: 55

## Source Counts

| Source ID | Rows | Status After X023 | Notes |
|---|---:|---|---|
| `brians_modern_south_asian_lit_english_2003` | 15 | extracted | Complete 15-row Gale public chapter TOC ingested; rows are literary-history context, not anthology selection evidence. |
| `e014_african_writers_series_heinemann_penguin` | 48 | metadata_ready | Pearson 2023 rights PDF parsed into 47 title rows and PRH series page added one non-duplicate relaunch row; edition-series metadata only. |
| `e014_penguin_modern_african_poetry_4e_2007` | 239 | extracted | Structured eCampus public TOC parsed into 239 poem rows under 99 poet headings; PRH official page confirms 99 poets/27 countries but not full TOC. |
| `e017_columbia_early_modern_japanese_lit_2002` | 12 | in_progress | Twelve audited major-work rows ingested from Dandelon public TOC PDF; full line-level TOC remains a later extraction packet. |
| `e017_columbia_traditional_japanese_lit_2007` | 20 | in_progress | Twenty audited major-work rows ingested from LOC public prepublication TOC; full line-level LOC TOC remains a later extraction packet. |

## Parser Boundaries

- `e014_penguin_modern_african_poetry_4e_2007`: ingested poem rows only when a page number was visible in the structured public TOC; author-date headings and country headings were used as metadata, not separate rows.
- `e014_african_writers_series_heinemann_penguin`: ingested clean title/creator blocks from the Pearson PDF and added non-duplicate PRH series-page titles; rights descriptions and sales territories were excluded.
- `e017_columbia_traditional_japanese_lit_2007` and `e017_columbia_early_modern_japanese_lit_2002`: ingested audited major-work rows only. Full line-level TOC extraction remains open because those TOCs include many nested excerpts and generic section headings.

## Source URLs

- https://www.gale.com/ebooks/9780313058257/modern-south-asian-literature-in-english
- https://www.pearson.com/content/dam/one-dot-com/one-dot-com/international-schools/pdfs/rights-and-licensing/African-Writers-Series-2023-Oct.pdf
- https://miamioh.ecampus.com/penguin-book-modern-african-poetry-fourth/bk/9780141181004
- https://www.loc.gov/catdir/toc/ecip064/2005034052.html
- https://external.dandelon.com/download/attachments/dandelon/ids/CH001B27FFCAAB5C83CF8C1257AD900519E1E.pdf
- https://www.penguinrandomhouse.com/series/PAF/penguin-african-writers-series/
- https://www.penguinrandomhouse.com/books/301584/the-penguin-book-of-modern-african-poetry-by-edited-by-gerald-moore-introduction-by-gerald-moore-and-ulli-beier/
