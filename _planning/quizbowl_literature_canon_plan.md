# Quizbowl-Only Literature Canon Plan

Date: 2026-05-04

Status: proposed_parallel_track

## Core Idea

Build a literature canon from quizbowl question clues only. Do not use Bloom, online lists, anthology tables of contents, syllabi, or the existing canon as evidence. The current canon is preserved as-is; this becomes a separate experimental canon and comparison layer.

The inclusion signal is simple in principle:

- A literary work becomes eligible when it is mentioned in quizbowl clue text more than three times.
- Answerlines do not count as evidence.
- Evidence is counted from `archive_parsed_questions.clue_text`, not `answerline`.
- Mentions are counted by distinct question rows, distinct sets, years, and circuits so repeated packet artifacts do not inflate status.

Observed local corpus baseline:

- Database: `/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db`
- Main clue table: `archive_parsed_questions`
- Rows: 2,216,999
- Sets: 2,160
- Year span: 1969-2026
- Tossups: 774,599
- Bonus parts: 1,442,400

## Why This Is Plausible

Quizbowl is not a neutral world canon, but it is a real, measurable cultural-pedagogical canon. It repeatedly encodes what question writers expect educated players to know, and it does so through clues, not just final answerlines. That makes it useful for a different claim:

> This is a quizbowl-salience literature canon: works that recur as objects, references, clues, settings, titles, sources, and interpretive anchors across a large quizbowl corpus.

This is more objective than hand-ranking because every inclusion can be traced to clue rows.

## Key Methodological Rule

Answerlines may be used only for optional title discovery or alias seeding, never as canon evidence. A work is included because it appears in clue text, not because it is an answer.

If we want the strictest version, we do not use answerlines even for title discovery. Instead we discover titles from clue text by extraction and review. The faster practical version can use answerline-derived title candidates as a lexicon, but every score and threshold must come from clue mentions only.

## Output Artifacts

Create a parallel build area:

- `_planning/quizbowl_lit_canon/quizbowl_lit_title_candidates.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_mentions.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_clusters.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_canon_scores.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_false_positive_review.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_method_report.md`
- `_data/quizbowl_literature_canon.yml`

Do not overwrite `_data/canon_quick_path.yml`.

## Data Model

### Title Candidate

One row per possible literary work title:

- `candidate_id`
- `canonical_title`
- `normalized_title`
- `creator_hint`
- `form_hint`: novel, play, poem, epic, story, collection, scripture/literary text, unknown
- `candidate_source`: clue_extraction, answerline_seed_no_evidence, existing_loci_node_no_evidence
- `disambiguation_status`: unreviewed, accepted_work, rejected_nonwork, needs_split, needs_merge
- `notes`

### Mention Evidence

One row per detected clue mention:

- `mention_id`
- `candidate_id`
- `archive_parsed_question_id`
- `set_title`
- `year`
- `question_type`
- `mention_text`
- `mention_start`
- `mention_end`
- `match_type`: exact, alias, quoted_title, pattern_extracted, adjudicated
- `evidence_status`: accepted, rejected_answer_leak, rejected_non_title, ambiguous
- `clue_snippet`

### Canon Score

One row per accepted work cluster:

- `work_id`
- `canonical_title`
- `creator`
- `accepted_mention_count`
- `distinct_question_count`
- `distinct_set_count`
- `distinct_year_count`
- `first_year`
- `last_year`
- `tossup_count`
- `bonus_count`
- `difficulty_weighted_count`
- `circuit_diversity_count`
- `quizbowl_salience_score`
- `tier`
- `review_status`

## Extraction Strategy

### Pass 1: Clue-Only Title Discovery

Extract likely work titles from `clue_text` using quizbowl-specific patterns:

- Quoted spans: `"Bartleby, the Scrivener"`, `"The Dead"`, `"The Waste Land"`.
- Explicit form patterns: `novel X`, `play X`, `poem X`, `story X`, `collection X`, `epic X`.
- Authorship patterns: `author of X`, `wrote X`, `in X`, `from X`, `title character of X`.
- Capitalized title spans near literary verbs: wrote, published, translated, adapted, narrates, opens, ends.
- Existing Loci clue/dossier fields if they were generated solely from quizbowl clue text.

This pass should overgenerate. False positives are handled later.

### Pass 2: Candidate Clustering And Alias Merge

Merge likely same-work strings:

- `Moby-Dick` / `Moby Dick`
- `The Brothers Karamazov` / `Brothers Karamazov`
- `One Hundred Years of Solitude` / `100 Years of Solitude`
- Transliterations and translated title variants where quizbowl clues make the relation explicit.

Keep separate:

- Work vs author.
- Work vs character.
- Whole collection vs individual poem/story when both are clueable.
- Generic short titles unless creator/context disambiguates them.

### Pass 3: Clue-Only Counting

Count only accepted mentions in `clue_text`.

Primary threshold:

- `distinct_question_count >= 4`

Secondary guards:

- `distinct_set_count >= 2`, unless all mentions are from very different years in the same long-running source.
- Exclude obvious answer-leak rows where clue text contains answer markers or parser failure artifacts.
- Deduplicate repeated imports using existing Loci dedup keys where available.

### Pass 4: Literature-Only Filtering

Keep literary works:

- Novels
- Plays
- Poems
- Short stories
- Epics
- Literary collections
- Major scriptural/mythic/oral texts when clue usage is literary

Reject or route separately:

- Authors as people
- Characters as people
- Countries, cities, schools, movements
- Films, operas, paintings, albums, unless the quizbowl clue is explicitly for a literary source work
- Philosophy/history/theory unless the product later asks for a humanities canon, not literature-only

### Pass 5: Tiering By Quizbowl Salience

The frequency count gives canon strength, but raw count is not enough. Score should include breadth and persistence:

```text
quizbowl_salience_score =
  log1p(distinct_question_count)
  + 0.8 * log1p(distinct_set_count)
  + 0.5 * log1p(distinct_year_count)
  + 0.3 * log1p(tossup_count)
  + difficulty/circuit diversity bonuses
  - duplicate/import/repeated-source penalties
```

Initial tiers:

- `qb_core`: very high score, broad set/year spread.
- `qb_major`: strong recurring work.
- `qb_contextual`: clears threshold but narrower circuit/time support.
- `qb_candidate`: clears raw threshold but needs review for ambiguity, parser leakage, or non-literary status.
- `qb_rejected`: false positive or out of literature scope.

## Validation

Run reviewer-style checks before trusting the output:

- Random sample of accepted mentions by tier.
- Top false-positive scan for short/generic titles: `Beloved`, `Emma`, `Fathers and Sons`, `The Trial`, `The Stranger`.
- Answer-leak scan: reject clue rows containing `answer:`, `answers:`, `answerline:`, or visible answer blocks.
- Same-set inflation scan: works whose mentions come mostly from one tournament or one packet family.
- Year-span check: distinguish old quizbowl artifacts from persistent canon.
- Answerline contamination check: prove that evidence counts do not use `answerline`.

## Expected Biases

This canon will be rigorous but not universal.

Likely biases:

- Stronger coverage of English-language, European, American, Russian, and classical literatures.
- Stronger coverage of works clueable in pyramidal question style.
- Underrepresentation of literatures rarely written about in quizbowl.
- Overrepresentation of works that produce memorable character/plot clues.
- Contemporary work lag unless recent quizbowl has adopted it.

These are not reasons to reject the project. They are reasons to label it honestly as quizbowl-derived.

## Implementation Phases

### QL1: Feasibility Slice

Target: 2-4 hours.

- Build a prototype extractor on a sample of clue rows.
- Test known works: `Moby-Dick`, `Hamlet`, `Beloved`, `Things Fall Apart`, `The Tale of Genji`, `The Waste Land`.
- Produce a small mention table and inspect false positives.

### QL2: Full Candidate Extraction

Target: 0.5-1 day.

- Run clue-only title extraction over all parsed question rows.
- Store raw candidates and evidence snippets.
- Generate candidate clusters.

### QL3: Review And Filtering

Target: 0.5-1 day.

- Review top candidates and high-risk ambiguous titles.
- Apply literature-only routing.
- Merge obvious aliases.

### QL4: Scoring And Public Data

Target: 0.5 day.

- Compute quizbowl salience scores.
- Assign tiers.
- Export `_data/quizbowl_literature_canon.yml`.

### QL5: UI Integration

Target: 0.5-1 day.

- Add a separate mode or page for the quizbowl-derived canon.
- Show frequency evidence: mentions, sets, years, first/last appearance.
- Let users filter by tier, form, era if available, and review status.
- Keep the current canon and quizbowl canon visually distinct.

## Decision Point

After QL1, decide whether to continue with:

- **Strict clue-only discovery:** slower, cleaner philosophically.
- **Answerline-seeded clue-only evidence:** faster, still valid if answerlines are not counted.

The recommended practical route is answerline-seeded clue-only evidence with transparent labeling, because it greatly improves title recall while preserving the core evidentiary rule.
