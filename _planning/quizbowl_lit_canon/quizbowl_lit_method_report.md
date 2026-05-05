# Quizbowl Literature Canon Method Report

Generated: 2026-05-05T00:51:15Z

## Corpus

- Database: `/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db`
- Source table: `archive_parsed_questions`
- Rows processed: 2216999
- Evidence fields: raw `answerline` and raw `clue_text`
- Diagnostic field: `archive_practice_questions.track_id` for quizbowl category counts only
- Explicitly not used for evidence: `archive_canon_refinement_runs`, `archive_canon_answerline_candidates`
- Threshold: total distinct quizbowl questions >= 4

## Candidate Extraction

- Raw answerline work candidates: 9543
- Exact-match work-title seeds from answerlines and clues: 5271
- Exact-match seed basis counts: `answerline`=740, `answerline_and_clue`=1023, `clue`=3508
- Raw normalized candidates: 81872
- Candidates clearing threshold: 14396
- Public YAML rows after excluding rejected non-literature: 10477
- Rejected non-literature candidates: 3919
- Evidence/example rows written: 68825

## Review Routing

- Accepted works require repeated quizbowl evidence and are strongest when raw answerline prompts identify the title as a literary form.
- Non-literary context signals are counted across all observed snippets, not just displayed examples.
- Strong raw answerline forms such as novel, play, poem, story, epic, saga, and collection can override noisy clue mentions from music, film, or other adaptation contexts.
- Generic book/work/essay prompts do not override non-literary context dominance; those candidates are rejected from the public literature canon.

## Tier Counts

- `qb_candidate`: 6131
- `qb_contextual`: 2192
- `qb_core`: 967
- `qb_major`: 1187
- `qb_rejected`: 3919

## Review Status Counts

- `accepted_likely_work`: 4346
- `needs_review_common_or_short_title`: 2207
- `needs_review_fragment_title`: 1
- `needs_review_low_evidence`: 1214
- `needs_review_possible_character_or_person`: 1818
- `needs_review_possible_combined_title`: 478
- `needs_review_section_or_subwork_title`: 413
- `rejected_non_literary_context`: 3919

## Outputs

- `quizbowl_lit_title_candidates.tsv`
- `quizbowl_lit_mentions.tsv`
- `quizbowl_lit_clusters.tsv`
- `quizbowl_lit_canon_scores.tsv`
- `quizbowl_lit_false_positive_review.tsv`
- `quizbowl_lit_rejected.tsv`
- `_data/quizbowl_literature_canon.yml`

## Caveats

This is an independent quizbowl-corpus build. It uses answerlines only when the raw question prompt asks for a literary work, then counts both answerline frequency and clue-text mentions. Quizbowl track labels are diagnostic metadata for audit and category sanity checks, not inclusion evidence.
