# Canon Build Phase Plan

Date: 2026-05-04

Status: fast_finish_active

## Decision

The old plan is too slow for the current product goal. It treats final source validation, exact-title source rescue, replacement optimization, taxonomy cleanup, and UI launch as one blocking sequence. That is methodologically conservative, but it is not the right operating plan if the goal is to have a much better public canon page in a few days.

The revised plan separates two standards:

- **Ship-ready working canon:** useful public page, broad categories, honest provisional labels, obvious gap repair, duplicate/time cleanup, and clear next-step backlog.
- **Locked scholarly canon:** fully source-backed, score-derived, replacement-optimized, and exhaustively validated against all packet namespaces.

We should target the first standard now. The second standard remains the post-launch hardening track.

## Near-Term Definition Of Done

The build is ship-ready when:

- The public canon page is visually simpler and does not read like an AI-generated chronological dump.
- Users can filter by broad era, macro region/tradition, form, tier, and reading status.
- The list can support more than 3,000 rows through `core`, `major`, `contextual`, `supplemental`, and `candidate` tiers, so obvious omissions do not require slow displacement debates.
- The current 3,000-work path remains available as the curated reading path.
- The Desktop humanities draft is used as a high-recall gap source, not as final proof.
- Obvious high-confidence omissions are added or queued with visible status.
- Duplicate candidates, chronology inversions, generic-title rows, and missing metadata are reported and the highest-confidence fixes are applied.
- Every row has an honest provenance/status label such as `source_backed`, `accepted_incumbent`, `needs_source_review`, `supplemental_candidate`, or `deferred`.
- Jekyll build passes.

The ship-ready build does **not** claim that nothing is missing. It claims that this is a transparent working edition with a visible audit backlog.

## Active Fast-Finish Phases

### Phase A: Freeze, Classify, And Report

Target time: 0.5 day.

Inputs:

- `_data/canon_quick_path.yml`
- `/Users/benjaminkramer/Desktop/complete_humanities_canon.md`
- `_planning/canon_audit_outputs/`
- `_planning/canon_build/tables/`

Actions:

- Keep the current 3,000-work path intact as the primary reading path.
- Generate broad public-facing categories from existing fields and conservative normalization.
- Refresh duplicate, chronology, generic-title, and metadata reports.
- Treat Washington Irving-style checks as sentinel visibility tests, not as manual search tasks.

Done when:

- Current path still has 3,000 rows.
- Broad category fields are available for UI filtering.
- Quality reports identify the main cleanup targets.

### Phase B: Fast Gap Intake

Target time: 0.5-1 day.

Actions:

- Parse the Desktop humanities canon as a high-recall comparison source.
- Compare against the current literature path by normalized title, creator, and common aliases.
- Classify unmatched items as `add_now`, `candidate`, `needs_review`, `out_of_scope`, or `already_represented`.
- Add high-confidence literary omissions as supplemental/candidate rows instead of forcing immediate one-for-one cuts.
- Keep disputed or field-boundary items in the backlog rather than blocking launch.

Done when:

- A visible gap queue exists.
- High-confidence omissions are no longer hidden.
- The canon can grow without waiting for displacement logic.

### Phase C: Public UI Rebuild

Target time: 1 day.

Actions:

- Replace the long chronological wall with a simpler reading interface.
- Add compact summary stats, search, tier filters, category filters, status filters, and a clean work list.
- Make categories human-readable: era, region/tradition, form, tier, and status.
- Show the curated 3,000-work path separately from supplemental/candidate material.
- Avoid overclaiming precision where taxonomy is inferred.

Done when:

- The page is usable on desktop and mobile.
- The first screen makes the project legible.
- Filtering works without requiring manual browser search.

### Phase D: High-Confidence Cleanup

Target time: 0.5-1 day.

Actions:

- Fix obvious duplicate rows.
- Fix obvious chronology/date-basis errors.
- Fix the most visible generic-title problems where the intended edition/work is clear.
- Leave ambiguous source-debt and selection-basis issues in the post-launch backlog.

Done when:

- The quality report has no high-confidence easy fixes left.
- Remaining problems are explicitly labeled as source review or boundary review.

### Phase E: Ship Working Edition

Target time: 0.25 day.

Actions:

- Run validation and Jekyll build.
- Commit and push the working edition.
- Keep public wording honest: this is a working canon, not a final exhaustive lock.

Done when:

- Site builds.
- Changes are pushed.
- The page explains its provisional/auditable status without apologizing for it.

## Post-Launch Hardening Track

This track continues after the working edition ships. It should not block the public UI/category rebuild.

Post-launch work:

- Exact-title source rescue packets such as X074-X083.
- Source-item extraction at scale.
- Evidence ledger completion.
- Source-weight and score derivation.
- Replacement optimization if the user wants a fixed 3,000-item locked path.
- Full packet namespace validation.
- Final adversarial review.

The old Phases 0-10 remain valid as lock criteria, but they are no longer launch criteria.

## Operating Rules

- Do not run 340 manual packet audits sequentially before launch.
- Do not spend days closing low-value source debt while the public UI remains hard to use.
- Do not make the user manually find gaps.
- Prefer adding visible supplemental/candidate rows over slow displacement debates.
- Use exact source validation only for rows that are high-impact, disputed, or about to become `core`/`major`.
- Keep provenance visible so imperfect rows are honest rather than hidden.
