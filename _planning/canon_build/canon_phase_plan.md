# Canon Build Phase Plan

Date: 2026-05-03

Status: active.

This plan defines how we know when the source-backed canon rebuild is done. The public 3,000-work path remains provisional until all lock gates pass.

## Phase 0: Baseline Freeze

Goal: preserve the incumbent public path while the scholarly build layer is built.

Done when:

- The current path has exactly 3,000 selected rows.
- Duplicate IDs and duplicate ranks are zero.
- Public copy says the canon is provisional.
- No direct add/cut replacements are made outside a gated H integration packet.

Current status: complete for the Wave 005 incumbent baseline.

## Phase 1: Build-Layer Hardening

Goal: make the tables mechanically trustworthy before scaling extraction.

Done when:

- Schemas include the controlled values actually used by the tables.
- Validator checks controlled values, source refs, evidence refs, relation refs, selected-rank continuity, and source-weight mappings.
- Packet status is machine-readable.
- Source-class/source-weight policy exists.
- Source-item row weights are treated as provisional observations, not final scoring.

Current status: mostly complete; keep expanding validation as new tables are added.

## Phase 2: Matching And Relation Substrate

Goal: prevent false omissions by matching source rows through title, creator, alias, selection, contained-work, and series logic before gap claims are made.

Done when:

- `canon_match_candidates.tsv` is generated from every source item.
- `canon_match_review_queue.tsv` lists unresolved or ambiguous matches.
- `canon_relation_review_queue.tsv` lists selection, contained-work, series, duplicate, adaptation, and variant cases that need relation decisions.
- Unmatched source items are classified as candidate gaps, possible aliases, represented-by-selection, boundary cases, or no-current-work candidates.
- No source row is promoted to a true omission before matching/relation review.

Current status: started; X013/X014 were rerun after X027, and X013 matching was rerun again after X031 aliases, the X033 `from`-prefix matcher fix, X034 creator variants, and X035 X030 scope routes. The build now has 557 match candidates, 5,474 match-review decisions, and 7,567 relation-scope status rows. No final relation rows are ready to write.

## Phase 3: Source Extraction At Scale

Goal: extract source items from priority sources without confusing access/corpus metadata with canon support.

Done when:

- High-priority extractor specs exist for Norton World Literature 5e, Norton American Literature 10e, LOA, Columbia/Princeton, and other feasible sources.
- Each extraction records denominator status: complete, partial, metadata-only, context-only, blocked, sampled, or unknown.
- Source fetch/access logs identify exact pages, files, APIs, and access limits.
- Extracted rows pass matching and relation review queues.

Current status: E001-E018 source layers registered; X001-X006 pilot source items ingested; X007-X012 feasibility complete with rows held; X020-X025 generated/updated 2,690 E013/E014/E015/E016/E017/E018 source-item observations; X026 added 1,586 official Norton World Literature 5e TOC rows; X027 added 1,644 Longman World Literature 2e public TOC rows; `canon_source_items.tsv` now has 5,942 total rows. Expanded matching/relation/evidence queues now exist; full Traditional Chinese CPL line-level access and Oxford modern Indian poem-level official-copy reconciliation remain pending.

## Phase 4: Evidence Ledger And Source-Debt Rules

Goal: turn matched source observations into evidence without inflating weak source classes.

Done when:

- Evidence rows are generated from matched source items using source-weight policy.
- Internal records and access metadata do not close external source debt.
- Corpus/database rows support identity/provenance only unless explicitly waived.
- At least two independent canon-support source families support non-obvious additions.

Current status: started; source weights, source-debt rules, 468 total evidence rows, a 3,008-row source-debt status report, and scoring-input blockers exist. Source-debt closure remains 0 until evidence is accepted under the rules.

## Phase 5: Taxonomy, Boundary, And Quality Gates

Goal: make categories and boundary decisions first-class instead of inferred.

Done when:

- Candidate works have region, subregion, original language, literary tradition, period, form, unit type, selection basis, and boundary policy where needed.
- Boundary policies exist for scripture, philosophy, theology, history, oral tradition, Indigenous/public material, memoir/testimonio, children's/YA, genre fiction, graphic narrative, series, and anthology excerpts.
- Quality reports cover duplicates, generic titles, chronology/date-basis issues, and boundary cases from build tables.

Current status: started for the X018 pilot queue only; 8 source-backed omissions are queued, and 0 are ready for scoring.

## Phase 6: Coverage Targets And Scoring

Goal: compare incumbents and omissions on the same evidence scale.

Done when:

- Coverage targets exist by period, region, language/tradition, form, source class, and boundary class.
- `canon_scores.tsv` is generated for current works and source-backed omissions.
- Scores include source support, source diversity, coverage scarcity, boundary penalty, duplicate penalty, source debt penalty, generic-title penalty, date uncertainty, recency, and incumbent bonus.

Current status: started; `canon_scoring_inputs.tsv` now covers all 3,008 work candidates, but 0 rows are ready for score computation because source debt and other blockers remain open. Coverage targets and final scores are not generated yet.

## Phase 7: Diagnostic-First Validation Sweeps

Goal: use B/C/D/F/I packets as a coverage map, not as 340 sequential hand audits. First generate whole-canon diagnostics that rank coverage cells, sentinel works, and source-backed unmatched clusters. Then manually audit only flagged red cells and high-risk omissions.

Done when:

- `canon_coverage_matrix.tsv` exists and summarizes selected counts, candidate counts, source-item pressure, evidence counts, and source-debt state across period, region, form, and intersection cells.
- `canon_sentinel_checks.tsv` exists and tests a maintained sentinel list against current path rows, aliases, source items, and evidence.
- `canon_gap_diagnostics.tsv` ranks missing or suspicious cells by severity, source support, sentinel failure, and source-debt status.
- `canon_red_cell_audit_queue.tsv` identifies the small subset of B/C/D/F/I cells that need manual review.
- Period packets B001-B034, region/tradition packets C001-C196, form packets D001-D046, sentinel packets F001-F034, and intersection packets I001-I030 are complete, waived, or represented by generated diagnostics with no red-cell flag.
- All high-priority gaps are added to the omission queue, rejected with rationale, or deferred with source-gap rationale.

Current status: first X028-X035 diagnostic pass generated. The old 340-packet sweep remains the coverage namespace, but execution now starts with automated diagnostics and red-cell triage. The initial pass checks 57 sentinel targets, finds 0 sentinel failures, produces a 120-row red-cell queue, routes all 120 rows into manual review classes, records 25 title-route decisions, writes 7 safe title-variant aliases for already selected works, reruns matching with the `from`-prefix rule to lift the candidate-match table to 557 rows, adds reviewed Tao Yuanming/Bai Juyi creator romanization variants, and applies 39 reviewed X030 scope routes to match/relation decisions.

## Phase 8: Source-Backed Integration

Goal: generate public-path add/cut transactions without increasing debt.

Done when:

- `canon_replacement_candidates.tsv` names every proposed add, cut, evidence basis, score delta, coverage effect, and gate status.
- Each approved batch keeps the path at 3,000 works.
- No batch increases source debt, duplicate debt, chronology debt, generic-title debt, or unresolved boundary debt.
- Validation and site build pass after every integration batch.

Current status: paused.

## Phase 9: Public UI Regeneration

Goal: make the canon page simpler and honest about the data.

Done when:

- Public data is generated from selected path rows.
- UI uses first-class period, region, language/tradition, form, tier, source status, and review status where available.
- Provisional/source-review status remains visible.
- Inferred categories are not presented as scholarly final taxonomy.

Current status: pending; conservative simplification is allowed before final taxonomy.

## Phase 10: Final Adversarial Review

Goal: try to break the locked list.

Done when:

- Q packets are complete.
- Any discovered omission opens a packet rather than an ad hoc edit.
- All waivers and exclusions are documented.
- Final validation and build pass.

Current status: not started.

## Lock Criteria

The canon is not locked until Phases 0-10 are complete or explicitly waived, the generated public path has 3,000 selected works, and the final validation report has zero unwaived structural, source, duplicate, chronology, generic-title, boundary, and coverage blockers.
