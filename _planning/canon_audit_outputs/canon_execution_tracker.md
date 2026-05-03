# Canon Audit Execution Tracker

Last updated: 2026-05-03

## Phase Status

| Phase | Scope | Status | Output |
|---|---|---|---|
| Phase S0 | Freeze current baseline and claims | Complete for Wave 005 baseline | Commit `64600ddb264839d57a173438490f36eeed4c31b3`; validation outputs current |
| Phase S1 | Source/candidate universe scaffolding | Complete for first scaffold | `_planning/canon_build/` schemas, empty tables, validation, and incumbent bootstrap created |
| Phase S1H | Hardening pass after workflow review | Active next | Controlled values, source-class policy, packet status, source-fetch logs, stronger validation, and idempotent upserts |
| Phase S2 | Source registry triage and prioritized extraction | In progress | E001-E012 registered; X001-X006 pilot ingested; X007-X012 feasibility complete but rows held pending hardening |
| Phase S3 | Continuous normalize, dedupe, and relations | Started | X013/X014 generated review queues, reviewed decisions, relation-scope status, and 8 provisional source-backed candidates |
| Phase S4 | Evidence policy and source weighting | Started | Source weights, source-debt rules, 9 provisional X017 evidence rows, a 3,008-row source-debt status table, and scoring-input blockers exist; 0 source-debt rows are closed |
| Phase S5 | First-class taxonomy and boundary policy | Pending | Required before boundary-sensitive rows are locked |
| Phase S6 | Coverage targets, scoring, and coverage matrix | Started | `canon_scoring_inputs.tsv` covers 3,008 candidates; 0 rows are ready for score computation, and coverage targets/scores are not generated |
| Phase S7 | Period, region, form, sentinel, and intersection validation | Pending | B/C/D/F/I packets challenge scored universe, not direct replacement |
| Phase S8 | Source-backed integration H packets | Paused | No further content replacements until S1H-S6 gates exist |
| Phase S9 | Public UI and generated path | Pending | Conservative simplification allowed; precise filters wait for first-class taxonomy fields |
| Phase S10 | Final adversarial review | Pending | Q packets not started |

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

## Source-Item Extraction Batches

| Batch | Packets | Status | Output Contract |
|---|---|---|---|
| X Batch 1 | X001, X002, X003, X004, X005, X006 | Pilot ingested | 57 pilot source items and 47 pilot evidence rows; full extraction/matching pending |
| X Batch 2 | X007, X008, X009, X010, X011, X012 | Feasibility complete; rows held | Classical editions/reference, world/American anthologies, medieval metadata, and Bloom recovery/blocker decisions |
| X Batch 3 | X013, X014, X015, X016, X017, X018, X019 | Started | X013 candidates, X014 relation-scope status, X017 source-debt status, X018 draft omission queue, and X019 scoring inputs created; remaining work is evidence acceptance, coverage targets, scores, and replacement candidates |

## Active Structural Debt

- Source gate: 2,939 source-debt rows and 2,938 `manual_only` rows remain; no new row should enter as `manual_only`.
- Validation gate: current PASS means headers/foreign keys plus the current hardening checks. Controlled vocabularies, source-role semantics, extraction-status coherence, source-debt closure, scoring readiness, and replacement readiness still need further hardening before public integration.
- E002: Bloom curated seed table is blocked; exact 200-row seed cannot be reconstructed from target repo or current path annotations without guessing.
- E003: Bloom full appendix/review tables are recoverable from local untracked artifacts outside the target worktree, but publication/scoring is policy-gated.
- E004-E006: Norton, Longman, and Bedford layers are registered, but line-item TOC extraction remains pending and access-limited.
- E007-E012: 38 additional source layers are registered for core curricula, classics, medieval Europe, English/British, American, and African American literature.
- Source-item gate: source registry rows alone do not support additions. Each layer still needs extracted source items, creator-aware matching, and evidence rows.
- Evidence gate: access metadata, corpus records, bibliographic databases, internal accepted records, and packet outputs cannot count as external canon support until source-class weighting and source-debt rules are integrated into scoring. X017 source-debt status has 0 closed rows; this is expected because accepted independent external support has not been adjudicated.
- Matching gate: source rows must pass exact/normalized/creator-aware/alias/contained-work/selection/series matching before being called true omissions. X013 has 8 provisional source-backed candidate rows, 1 existing-selection representation, and 1 out-of-scope media boundary; none are public-path additions.
- Relation gate: selection, contained-work, series, variant, duplicate, and adaptation decisions must be reviewed before final relation rows are written. X014 has 41 relation-scope status rows; 24 are policy-blocked and 17 need scope review, so 0 are ready to write as final relations.
- Omission gate: X018 currently has 8 source-backed omission rows and 0 ready-for-scoring rows; every gap still has source-debt, selection/scope, chronology, or corroboration blockers.
- Scoring gate: X019 currently has 3,008 scoring input rows and 0 ready-for-score rows. This is expected until source debt is closed under the evidence rules and relation/date/boundary blockers are resolved.
- Taxonomy gate: public category reports are still keyword-inferred; first-class region, language/tradition, form, selection, and boundary fields are required.
- A029-A031/H013: replacement-induced chronology inversions must be repaired or explicitly waived before the path is locked.
- H014: duplicate-like clusters and collection/selection overlaps remain; these now move into alias/relation/decision tables.
- A009-A011: generic `Selected Poems`, `Selected Stories`, and anthology rows need selection bases.
- G001-G025: boundary-sensitive rows need explicit literature-inclusion rationales.

## Operating Rule

Direct replacement waves are paused. Each source-crosswalk or harvest wave must end with:

- a written wave report,
- source registry/source item/evidence updates only when hardening gates permit them,
- match/relation/quality-issue updates when applicable,
- a replacement log update only if no content changed or if a later gated integration batch merges changes,
- regenerated validation outputs,
- duplicate and chronology warning review,
- a build check when public data changes,
- and a commit before the next integrated batch.
