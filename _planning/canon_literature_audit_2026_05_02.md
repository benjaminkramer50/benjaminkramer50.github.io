---
title: Literature Canon Full Audit
date: 2026-05-02
status: provisional_path_complete_source_review_pending
scope: literature_only_global_lifetime_path
---

# Literature Canon Full Audit

Verdict: the site now has a usable 3,000-item literature checklist, but it is not a locked academic canon yet. The structure is real and the list is followable, but the scholarly status is provisional until source review, Bloom cleanup, chronology repair, and alias-aware dedupe are completed.

## Current Verified State

- Public checklist target: 3,000 texts.
- Current public checklist: 3,000 texts.
- Remaining target slots: 0.
- Public scope check: 0 non-text items; all current public items are `textual_humanities`, medium `text`, and engagement target `read`.
- Structural check: 0 duplicate ranks, 0 duplicate IDs, 0 missing titles, 0 missing sort years, 0 future placeholder sort years.
- Source status: 62 entries are accepted or source-backed; 2,938 entries are still `manual_only`.
- Review status: 2,939 entries still have `review_status: needs_sources`.
- Chronology caveat: 257 entries still have approximate or pending date labels, mostly from late Bloom staging.
- Contemporary caveat: 42 entries have `sort_year >= 2020`; these should remain probationary until source-backed reception review.
- Completion-unit bug fixed: story/tale items no longer inherit the epic/saga completion instruction.
- Website trust fix: the public tracker now shows reviewed vs needs-source-review status and exposes a source-status filter.

## Audit Process

The audit used five independent review scopes plus local checks:

- Structural/data integrity: schema, IDs, ranks, dates, duplicates, enum drift, completion-unit logic.
- Global coverage: regional/topic balance, period balance, undercovered traditions, oral/Indigenous handling.
- Bloom integration: seed coverage, full-audit coverage, staged-vs-present Bloom decisions, late-wave quality.
- Boundary decisions: genre, children/YA, graphic narrative, scripture/myth, philosophy/religion leakage, contemporary instability.
- Website UX: text-only checklist usability, progress tracking, source-status visibility, 3,000-item rendering weight.

## Corrections Applied

- Removed high-confidence non-literary/prose spillover from the public literature path:
  - `Del Romanzo Storico`
  - `Genie du Christianisme`
  - `De l'Amour`
  - `A Defence of Poetry`
  - Ruskin/Newman/Pater prose-theory items
  - generic `Selected prose`, `Prose`, and `Translations` placeholders
- Removed performance-bound Gilbert/Sullivan operetta spillover from the literature-only path.
- Repaired future placeholder dates: no current public item now has `sort_year > 2026`.
- Added audit replacement waves:
  - `wave_043_literature_audit_replacements`
  - `wave_044_literature_audit_backfill`
  - `wave_045_literature_dedupe_replacements`
  - `wave_046_literature_boundary_replacements`
- Improved alias-aware dedupe for known variants:
  - `Frankenstein`
  - `Hard Times`
  - `Oliver Twist`
  - `Waverley`
  - `Erewhon`
  - `Huarochiri Manuscript`
  - `Heimskringla`
  - `Sundiata`
  - `Risalat al-Ghufran / The Epistle of Forgiveness`
  - `Kutadgu Bilig / Wisdom of Royal Glory`
  - `Os Sertoes / Rebellion in the Backlands`
  - `Life and Times of Michael K`
  - `The Changeling`
  - `The Broken Commandment`
  - `The River Ki`
  - `The Sailor Who Fell from Grace with the Sea`
- Updated `scripts/report_bloom_coverage.rb` so it reports both stale imported Bloom matches and recomputed current-path Bloom matches.

## Bloom Status

- Curated Bloom seed layer: 200/200 matched in the current path; 0 missing keep/representative-selection seed entries.
- Full imported Bloom audit: 2,107 entries.
- Full imported Bloom status: 132 reviewed seed-level entries and 1,975 unreviewed raw entries.
- Current path match count from stale imported flag: 274.
- Current path match count recomputed against the current checklist: 712.
- Bloom review batches: 576 decisions.
- Staged Bloom promotions declared: 554.
- Staged Bloom promotions still present in the current path by `source_id`: 510.
- Staged Bloom promotions absent/cut after audit cleanup: 44.

Interpretation: Bloom is represented as an important Western evidence layer, not as an authority to copy wholesale. The curated seed coverage is defensible. The late automated Bloom layer remains provisional because many dates are approximate and some records were mechanically generated from the appendix.

## Remaining Problems

1. Source review debt is the main blocker. A true academic canon needs source-backed inclusion evidence, not just manual candidate status.
2. Period balance remains too late. Current bins are:
   - `<-1000`: 31
   - `-1000..-1`: 111
   - `0..499`: 55
   - `500..999`: 77
   - `1000..1499`: 161
   - `1500..1699`: 159
   - `1700..1799`: 90
   - `1800..1899`: 451
   - `1900..1945`: 512
   - `1946..1989`: 765
   - `1990..2019`: 546
   - `2020+`: 42
3. Region/topic balance remains uneven because the current quick path has topics, not first-class `macro_region`, `original_language`, or `literary_tradition` metadata.
4. Southeast Asia, East Asia beyond the largest Chinese/Japanese/Korean cells, MENA minority languages, Central/Horn Africa, Arctic literatures, and premodern local-language traditions still need systematic source-reviewed strengthening.
5. Generic assignment titles remain common, especially `Selected Poems`. These are acceptable only if each gets a source-backed selection basis, edition, or anthology note.
6. Scripture, oral tradition, testimonio, philosophy-adjacent dialogues, and literary memoir need explicit `included_as_literature` / `boundary_note` metadata.
7. LocalStorage progress tracking is usable but not durable enough for a lifetime project unless exports are backed up regularly or progress is eventually written into site data.

## Definition Of Done For A Locked Canon

- Convert most `manual_only` items to source-backed review states.
- Add explicit `macro_region`, `original_language`, `literary_tradition`, `selection_basis`, and `boundary_note` fields.
- Replace approximate Bloom dates with verified work dates or documented period dates.
- Run alias-aware dedupe after every source-review batch.
- Cap very recent works with a probation rule unless a work has strong source-backed canonical reception.
- Keep the public page honest: reviewed/source-backed status must remain visible.
- Re-run validation, Bloom coverage, duplicate audit, chronology audit, and Jekyll build before calling the canon academically locked.
