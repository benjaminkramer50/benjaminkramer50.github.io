# X025 Chinese and Indian Remaining Cleanup

- status: source_items_ingested_evidence_scope_review_required
- generated_rows: 277
- direct_public_path_changes: 0
- direct_evidence_rows_added_by_ingester: 0
- evidence_rows_after_x013_x014_x017_rerun: 14

## Source Counts

| Source ID | Rows | Status After X025 | Notes |
|---|---:|---|---|
| `shorter_columbia_traditional_chinese_lit_2000` | 262 | extracted | Accessible abridged comparator source parsed into 262 public TOC rows after the full Columbia CPL record remained access-blocked. |
| `cambridge_history_chinese_lit_2010` | 15 | context_only | Cambridge Core chapter lists parsed into 15 chapter-context rows across Vols. 1-2. |
| `columbia_traditional_chinese_lit_1996` | 22 | in_progress | Full Columbia TOC remains blocked at CPL by Cloudflare; eCampus page for ISBN 9780231074292 exposes an unrelated autobiography TOC, so it was rejected. Shorter Columbia was added separately as an abridged comparator source. |
| `oxford_modern_indian_poetry_1998` | 124 | in_progress | OUP India official metadata confirms 125 poets, 14 Indian languages, and eight thematic sections; NLA catalog access is Anubis-blocked and no official poem-level TOC was exposed, so 124 Book Excerptise rows remain unreconciled. |

## Access Decisions

- The full Columbia anthology CPL record remains Cloudflare-blocked. Search snippets are still insufficient for reliable row-level ingestion.
- The eCampus page for ISBN 9780231074292 was rejected because its TOC begins with memoir/autobiography chapter titles, not the Columbia anthology contents.
- The Shorter Columbia anthology is ingested as a separate abridged comparator source, not as a replacement for the full anthology.
- Cambridge Chinese rows are chapter-context evidence only.
- OUP India confirms denominator metadata for Oxford modern Indian poetry, but no official poem-level TOC was exposed. NLA access was blocked by Anubis.

## Source URLs

- https://cincinnatistate.ecampus.com/shorter-columbia-anthology-traditional/bk/9780231119986
- https://www.cambridge.org/core/books/cambridge-history-of-chinese-literature/76F4628F8A769EEF2DF952B530ED0CEE
- https://www.cambridge.org/core/books/cambridge-history-of-chinese-literature/6FEBDC1995B8D05749A1F453D7577D21
- https://search.cpl.org/Record/a207337
- https://india.oup.com/product/the-oxford-anthology-of-modern-indian-poetry-9780195639179/
- https://masters.ecampus.com/columbia-anthology-traditional-chinese/bk/9780231074292
- https://catalogue.nla.gov.au/catalog/1539648
