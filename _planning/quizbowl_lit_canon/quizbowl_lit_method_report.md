# Quizbowl Literature Canon Method Report

Generated: 2026-05-04T19:17:02Z

## Corpus

- Database: `/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db`
- Source tables: `archive_practice_questions` joined to `archive_parsed_questions`
- Track filter: `literature`
- Evidence field: `clue_text`
- Answerline policy: answerlines are not counted as evidence.
- Local answerline seed lexicon enabled: true
- Local refined literature-work seeds: 405
- Unambiguous seed title variants: 760
- Processed rows: 104185
- Skipped parser-artifact rows with long clue text: 4
- Skipped rows with visible answer markers in clue text: 258

## Candidate Extraction

- Raw normalized clue-title candidates: 17357
- Candidates clearing threshold `distinct_question_count >= 4`: 3086
- Accepted mention rows written: 68561

## Tier Counts

- `qb_candidate`: 1239
- `qb_contextual`: 1444
- `qb_core`: 170
- `qb_major`: 233

## Review Status Counts

- `accepted_likely_work`: 1847
- `needs_review_alias_dominated`: 3
- `needs_review_common_or_short_title`: 775
- `needs_review_possible_character_or_person`: 444
- `needs_review_short_title`: 17

## Outputs

- `quizbowl_lit_title_candidates.tsv`
- `quizbowl_lit_mentions.tsv`
- `quizbowl_lit_clusters.tsv`
- `quizbowl_lit_canon_scores.tsv`
- `quizbowl_lit_false_positive_review.tsv`
- `_data/quizbowl_literature_canon.yml`

## Caveats

This is a first automatic quizbowl-only build. It intentionally favors recall and routes ambiguous short titles, character/person-like strings, and context-only capitalized spans to review. Tiers should be treated as quizbowl-salience tiers, not a universal literature canon.
