# Control Packets A001-A031

Generated: 2026-05-03T01:17:41Z

| Packet | Status | Check | Observed |
|---|---:|---|---|
| A001 | PASS | YAML schema and required fields | 0 rows missing required fields |
| A002 | PASS | Rank uniqueness, continuity, lifetime leakage | 0 duplicate rank values; 0 rank gaps |
| A003 | PASS | ID uniqueness and stable naming | 0 duplicate ID values |
| A004 | WARN | Title normalization and article stripping | 39 normalized duplicate/alias candidate keys |
| A005 | WARN | Creator normalization and traditional labels | 0 rows have empty creators; traditional labels still need review |
| A006 | WARN | Alias coverage for translated titles and spellings | 2737 rows have no aliases |
| A007 | WARN | Collection-contained title matching | Requires packet-specific source review; duplicate alias index generated |
| A008 | WARN | Series versus volume duplicate policy | Requires policy review; duplicate alias index generated |
| A009 | WARN | Generic Selected Poems audit | 141 poem/selected rows need selection basis review |
| A010 | WARN | Generic Selected Stories audit | 37 story/tale selection rows need review |
| A011 | WARN | Generic anthology and selection-basis audit | 267 generic/selection rows total |
| A012 | WARN | Placeholder date and approximate chronology audit | 123 rows have approximate/pending date labels |
| A013 | PASS | Future-date and ongoing-series audit | 0 rows sort after 2026 |
| A014 | WARN | Source-status debt audit | 2938 manual_only rows |
| A015 | WARN | Review-status debt audit | 2939 needs_sources rows |
| A016 | WARN | Tier drift audit | core=218, major=2576, contextual=206 |
| A017 | WARN | Completion-unit audit by form | Requires semantic review by form; inventory emitted |
| A018 | WARN | Public UI category audit | Presentation categories are generated; scholarly metadata still missing |
| A019 | PASS | Admin progress preservation audit | No progress edits performed by harness |
| A020 | WARN | Search discoverability audit | Alias/search fields emitted; sentinel packets must test false negatives |
| A021 | WARN | Duplicate candidate audit by title only | 39 candidate keys |
| A022 | WARN | Duplicate candidate audit by title plus creator | Needs second-stage review; raw duplicate report emitted |
| A023 | WARN | Duplicate candidate audit by alias | 39 alias/title candidate keys |
| A024 | WARN | Duplicate candidate audit by translated/original title | Depends on fuller alias metadata |
| A025 | WARN | Boundary-note missingness audit | 444 boundary-sensitive rows need explicit notes |
| A026 | WARN | Region/language metadata missingness audit | Macro region inferred, not authoritative; language metadata not yet first-class |
| A027 | PASS | Count cap and replacement-log audit | items=3000; target=3000 |
| A028 | WARN | Reproducible build and generated-file hygiene | Harness ran; Jekyll build not run by this script |
| A029 | WARN | Rank chronology inversion audit | 138 adjacent rank-sort inversions |
| A030 | WARN | Date-label and sort-year consistency audit | 123 rows still have approximate/pending date labels |
| A031 | WARN | Replacement-induced chronology drift audit | Review replacement slots in canon_chronology_inversions.tsv |
