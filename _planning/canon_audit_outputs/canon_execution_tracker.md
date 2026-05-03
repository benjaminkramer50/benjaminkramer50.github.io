# Canon Audit Execution Tracker

Last updated: 2026-05-03

## Phase Status

| Phase | Scope | Status | Output |
|---|---|---|---|
| Phase S0 | Freeze current baseline and claims | Complete for Wave 005 baseline | Commit `64600ddb264839d57a173438490f36eeed4c31b3`; validation outputs current |
| Phase S1 | Source/candidate universe scaffolding | Complete for first scaffold | `_planning/canon_build/` schemas, empty tables, validation, and incumbent bootstrap created |
| Phase S2 | Source crosswalk ingestion E001-E030 | In progress | E001-E012 registered; E001 ingested; Bloom/anthology/source-item blockers documented |
| Phase S3 | Normalize, dedupe, and first-class taxonomy | Pending | Alias/relation/taxonomy tables required before broad integration |
| Phase S4 | Scoring and coverage matrix | Pending | Current items and omissions scored together |
| Phase S5 | Boundary and policy adjudication G001-G025 | Pending | Required before boundary-sensitive rows are locked |
| Phase S6 | Period, region, and form validation B/C/D packets | Pending | Used to challenge scored universe, not direct replacement |
| Phase S7 | Source-backed integration H packets | Paused | No further content replacements until S1-S5 gates exist |
| Phase S8 | Public UI and generated path | Pending | UI filters wait for first-class taxonomy fields |
| Phase S9 | Final adversarial review | Pending | Not started |

## Completed Waves

| Wave | Packets | Status | Notes |
|---|---|---|---|
| Wave 001 | F001, F002, F003, F009, F023, F024 | Integrated | 9 replacements plus 1 alias repair; deferred queue opened |
| Wave 002 | F004, F005, F006, F007, F008, F010 | Integrated | 21 replacements plus Hughes metadata repair; duplicate and chronology debt queued for A029-A031/H013-H014 |
| Wave 003 | F011, F012, F013, F014, F015, F016 | Integrated | 33 replacements plus metadata repairs across British Romantic/Victorian/modernist and French premodern through modernist packets |
| Wave 004 | F017, F018, F019, F020, F021, F022 | Integrated | 54 replacement-log entries plus metadata repairs across Spanish/Iberian, Portuguese/Lusophone, Italian, German-language, Russian, and Scandinavian packets |
| Wave 005 | F025, F026, F027, F028, F029, F030 | Integrated | 28 replacements plus title/category repairs across South Asian modern, Chinese/Sinophone, Japanese, Korean, Arabic/Persian/Turkic, and African packets |

## Deferred/Recoded Wave

| Wave | Packets | Purpose |
|---|---|---|
| Wave 006 | F031, F032, F033, F034 | Deferred as direct integration. If run before source scoring, these packets are harvest-only: identify source-backed gaps, alias issues, boundary cases, and duplicate risks without add/cut merges |

## Next Source-Crosswalk Batches

| Batch | Packets | Output Contract |
|---|---|---|
| E Batch 1 | E001, E002, E003, E004, E005, E006 | Source registry rows, source item rows, matched/unmatched current works, unresolved omissions |
| E Batch 2 | E007, E008, E009, E010, E011, E012 | Registry complete; source-item extraction pending |
| E Batch 3 | E013, E014, E015, E016, E017, E018 | Same structured evidence output |
| E Batch 4 | E019, E020, E021, E022, E023, E024 | Same structured evidence output |
| E Batch 5 | E025, E026, E027, E028, E029, E030 | Same structured evidence output |

## Active Structural Debt

- Source gate: 2,939 source-debt rows and 2,938 `manual_only` rows remain; no new row should enter as `manual_only`.
- E002/E003: Bloom seed/raw/review tables are missing as machine-readable artifacts; current Bloom path annotations cannot close source debt.
- E004-E006: Norton, Longman, and Bedford layers are registered, but line-item TOC extraction remains pending and access-limited.
- E007-E012: 38 additional source layers are registered for core curricula, classics, medieval Europe, English/British, American, and African American literature.
- Source-item gate: source registry rows alone do not support additions. Each layer still needs extracted source items, creator-aware matching, and evidence rows.
- Taxonomy gate: public category reports are still keyword-inferred; first-class region, language/tradition, form, selection, and boundary fields are required.
- A029-A031/H013: replacement-induced chronology inversions must be repaired or explicitly waived before the path is locked.
- H014: duplicate-like clusters and collection/selection overlaps remain; these now move into alias/relation/decision tables.
- A009-A011: generic `Selected Poems`, `Selected Stories`, and anthology rows need selection bases.
- G001-G025: boundary-sensitive rows need explicit literature-inclusion rationales.

## Operating Rule

Direct replacement waves are paused. Each source-crosswalk or harvest wave must end with:

- a written wave report,
- an omission queue update,
- source registry/source item evidence updates when applicable,
- a replacement log update only if no content changed or if a later gated integration batch merges changes,
- regenerated validation outputs,
- duplicate and chronology warning review,
- a build check when public data changes,
- and a commit before the next integrated batch.
