# X024 Full-Line TOC and Context Cleanup

- status: source_items_ingested_matching_required
- generated_rows: 1059
- replaced_sources: 6
- direct_public_path_changes: 0
- direct_evidence_rows_added_by_ingester: 0

## Source Counts

| Source ID | Rows | Status After X024 | Notes |
|---|---:|---|---|
| `chinese_text_project_premodern` | 108 | metadata_ready | Chinese Text Project public Pre-Qin/Han index parsed into 108 title/access metadata rows; rows are not canon-selection evidence. |
| `columbia_modern_chinese_lit_2e_2007` | 168 | extracted | LOC public prepublication TOC parsed into 168 line-level rows; count supersedes the earlier 14-row pilot and older 166-item estimate. |
| `e013_cambridge_history_latin_american_lit_1996` | 52 | context_only | Cambridge Core chapter lists parsed into 52 chapter-context rows across Vols. 1-3. |
| `e014_cambridge_history_african_caribbean_lit_2000` | 40 | context_only | Cambridge Core chapter lists parsed into 40 chapter-context rows across Vols. 1-2. |
| `e017_columbia_early_modern_japanese_lit_2002` | 282 | extracted | Dandelon public TOC PDF parsed into 282 line-level rows after excluding chapter 1 editorial historical context. |
| `e017_columbia_traditional_japanese_lit_2007` | 409 | extracted | LOC public prepublication TOC parsed into 409 line-level rows; generic subheadings are retained as source rows but only explicit matches count downstream. |
| `columbia_traditional_chinese_lit_1996` | 22 retained | in_progress | CPL public TOC remains blocked to automated extraction; search snippets are insufficient for reliable line-level ingestion, so the earlier 22-row pilot is retained pending alternate access or physical copy. |
| `oxford_modern_indian_poetry_1998` | 124 retained | in_progress | OUP India official metadata confirms 125 poets in 14 Indian languages and thematic organization; it does not expose poem-level TOC, so Book Excerptise rows remain pending official-copy reconciliation. |

## Parser Boundaries

- LOC modern Chinese rows are line-level title rows under author headings. The source page is prepublication metadata, so rows are selection/excerpt evidence, not whole-work proof.
- LOC traditional Japanese rows preserve line-level contents after merging obvious wrapped lines and removing front/back matter. Generic subheadings are retained so later review can distinguish author headings, nested works, and excerpts.
- Dandelon early modern Japanese rows are page-bearing TOC rows after chapter 1 editorial history is excluded. Wrapped Chushingura-style titles are merged before ingestion.
- Cambridge rows are chapter-context rows only. They help map regional literary-history coverage and gaps, but they are not anthology inclusion evidence.
- Chinese Text Project rows are public index/access metadata only; the site explicitly functions as a text database, not a canon list.
- Traditional Chinese remains a real open gap: the CPL line-level TOC is blocked to automated access, and search snippets are not reliable enough for ingestion.
- Oxford modern Indian poetry remains an official-copy gap at poem level: OUP confirms anthology scope and denominator, but not the line-level poem list.

## Source URLs

- https://www.loc.gov/catdir/toc/ecip0615/2006019770.html
- https://www.loc.gov/catdir/toc/ecip064/2005034052.html
- https://external.dandelon.com/download/attachments/dandelon/ids/CH001B27FFCAAB5C83CF8C1257AD900519E1E.pdf
- https://www.cambridge.org/core/books/the-cambridge-history-of-african-and-caribbean-literature/1B9F2963235BC68CB3CA5EA6D534AC60
- https://www.cambridge.org/core/books/cambridge-history-of-african-and-caribbean-literature/383D7F023CD01BFB6AF3F29A7CDD7EB7
- https://www.cambridge.org/core/books/cambridge-history-of-latin-american-literature/1D0620D18EE73E2E7AC936C958296389
- https://www.cambridge.org/core/books/cambridge-history-of-latin-american-literature/7BD96D692CE735A7F0F92C1E91E3310A
- https://www.cambridge.org/core/books/cambridge-history-of-latin-american-literature/1CDA8EEB9673D751DBFA8A54EC3EAA07
- https://ctext.org/pre-qin-and-han?if=en
- https://india.oup.com/product/the-oxford-anthology-of-modern-indian-poetry-9780195639179/
