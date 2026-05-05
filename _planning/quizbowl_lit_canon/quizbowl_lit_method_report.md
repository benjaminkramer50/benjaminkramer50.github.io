# Quizbowl Literature Canon Method Report

Generated: 2026-05-05T04:20:35Z

## Corpus

- Database: `/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db`
- Source table: `archive_parsed_questions`
- Rows processed: 2216999
- Evidence fields: raw `answerline` and raw `clue_text`
- Diagnostic field: `archive_practice_questions.track_id` for quizbowl category counts only
- Adjudication file: `_planning/quizbowl_lit_canon/quizbowl_lit_adjudications.yml` (1002 decisions)
- Worker processes: 4
- Explicitly not used for evidence: `archive_canon_refinement_runs`, `archive_canon_answerline_candidates`
- Threshold: total distinct quizbowl questions >= 4

## Candidate Extraction

- Raw answerline work candidates: 9543
- Exact-match work-title seeds from answerlines and clues: 5523
- Exact-match seed basis counts: `answerline`=721, `answerline_and_clue`=1042, `clue`=3760
- Raw normalized candidates: 81872
- Candidates clearing threshold: 14396
- Public YAML rows after accepted-work filtering: 5023
- Rejected non-literature candidates: 2472
- Audit queue rows: 13195
- LLM review queue rows: 500
- Evidence/example rows written: 68864

## Review Routing

- Accepted works require repeated quizbowl evidence and are strongest when raw answerline prompts identify the title as a literary form.
- Non-literary context signals are counted across all observed snippets, not just displayed examples.
- Strong raw answerline forms such as novel, play, poem, story, epic, saga, and collection can override noisy clue mentions from music, film, or other adaptation contexts.
- Generic book/work/essay prompts do not override non-literary context dominance; those candidates are rejected from the public literature canon.

## Tier Counts

- `qb_candidate`: 6901
- `qb_contextual`: 2280
- `qb_core`: 1102
- `qb_major`: 1641
- `qb_rejected`: 2472

## Review Status Counts

- `accepted_likely_work`: 5023
- `needs_review_ambiguous_history_or_modern_novel_title`: 1
- `needs_review_ambiguous_literary_novella_or_opera_context`: 1
- `needs_review_ambiguous_multiple_works`: 1
- `needs_review_ambiguous_music_literature_title`: 2
- `needs_review_ambiguous_short_story_or_common_title`: 1
- `needs_review_ambiguous_title_and_evidence_points_to_chapter_phrase`: 1
- `needs_review_ambiguous_tolstoy_novel_or_mahler_symphony_context`: 1
- `needs_review_common_or_short_title`: 2457
- `needs_review_fragment_title`: 1
- `needs_review_journalism_history_boundary`: 1
- `needs_review_literary_criticism_philosophy_boundary`: 1
- `needs_review_literary_criticism_theory_boundary`: 9
- `needs_review_low_evidence`: 1208
- `needs_review_malformed_title_needs_canonicalization`: 1
- `needs_review_mixed_literary_poem_and_music_evidence`: 1
- `needs_review_mixed_poem_or_philosophy_example`: 1
- `needs_review_non_literature_track_context`: 500
- `needs_review_possible_character_or_person`: 1768
- `needs_review_possible_combined_title`: 478
- `needs_review_religion_devotional_boundary`: 2
- `needs_review_religious_autobiography_boundary`: 1
- `needs_review_scripture_religion_boundary`: 1
- `needs_review_section_or_subwork_title`: 462
- `needs_review_section_title_duplicate_of_labyrinth_of_solitude`: 1
- `rejected_art_criticism_not_literature`: 1
- `rejected_beat_memoir_low_lit_confidence`: 1
- `rejected_biblical_motif_or_subwork`: 1
- `rejected_biblical_parable_or_poem_fragment`: 1
- `rejected_character_not_work`: 3
- `rejected_christian_apologetics_not_literature_reading_list`: 1
- `rejected_comparative_mythology_not_literature_product`: 1
- `rejected_critical_theory_domain`: 5
- `rejected_critical_theory_section`: 1
- `rejected_descriptor_fragment`: 7
- `rejected_duplicate_or_art_context_variant`: 1
- `rejected_duplicate_or_phrase_fragment`: 1
- `rejected_duplicate_or_wrong_title_variant`: 1
- `rejected_duplicate_title_variant`: 25
- `rejected_duplicate_translation_variant_of_shahnameh`: 2
- `rejected_economics_domain`: 1
- `rejected_embedded_fictional_text_not_standalone_work`: 1
- `rejected_embedded_play_or_art_subject_not_work`: 1
- `rejected_feminist_social_criticism_domain`: 1
- `rejected_fictional_embedded_work`: 1
- `rejected_figures_not_work`: 1
- `rejected_film_context`: 2
- `rejected_film_context_artifact`: 1
- `rejected_film_not_literature_product`: 3
- `rejected_film_pop_context`: 1
- `rejected_film_title_or_wrong_work_variant`: 1
- `rejected_fragment_title_artifact`: 6
- `rejected_historical_document_domain`: 2
- `rejected_historical_event_not_work`: 2
- `rejected_history_biography_domain`: 1
- `rejected_history_domain`: 7
- `rejected_history_essay_domain`: 1
- `rejected_history_religion_domain`: 2
- `rejected_institution_not_work`: 1
- `rejected_language_or_period_label_not_work`: 1
- `rejected_law_domain`: 1
- `rejected_legal_document_domain`: 1
- `rejected_linguistics_cognitive_science_not_literature`: 1
- `rejected_linguistics_domain`: 1
- `rejected_linguistics_nonfiction_domain`: 1
- `rejected_literary_movement_label_not_work`: 2
- `rejected_magazine_feature_not_work`: 1
- `rejected_malformed_title_fragment`: 1
- `rejected_medical_parenting_domain`: 1
- `rejected_music_adjective_or_language_fragment_not_work`: 1
- `rejected_music_not_literature`: 1
- `rejected_music_prayer_title_collision`: 1
- `rejected_mythology_category_not_work`: 4
- `rejected_newspaper_not_work`: 1
- `rejected_nickname_or_character_fragment`: 1
- `rejected_non_literary_context`: 2181
- `rejected_non_literary_music`: 9
- `rejected_non_literary_music_context`: 2
- `rejected_non_literary_musical`: 5
- `rejected_non_literary_opera`: 2
- `rejected_non_literary_opera_cycle`: 2
- `rejected_non_literary_or_insufficient_literary_work_evidence`: 30
- `rejected_parser_artifact`: 4
- `rejected_parser_artifact_or_tv_channel`: 1
- `rejected_person_case_not_work`: 1
- `rejected_person_epithet_not_work`: 2
- `rejected_person_not_work`: 6
- `rejected_philosophy_concept`: 2
- `rejected_philosophy_concept_not_evidenced_shelley_novel`: 1
- `rejected_philosophy_critical_theory`: 1
- `rejected_philosophy_domain`: 11
- `rejected_philosophy_essay_domain`: 1
- `rejected_philosophy_fragment`: 2
- `rejected_philosophy_hermeneutics_not_literature`: 1
- `rejected_philosophy_lecture_not_literature`: 1
- `rejected_philosophy_phrase`: 1
- `rejected_philosophy_section_or_concept`: 1
- `rejected_philosophy_section_or_subwork`: 1
- `rejected_photo_documentary_domain`: 1
- `rejected_photography_domain`: 2
- `rejected_photojournalism_social_history`: 1
- `rejected_place_not_work`: 1
- `rejected_place_or_music_fragment_not_work`: 1
- `rejected_policy_document`: 1
- `rejected_political_document_domain`: 1
- `rejected_political_economics_not_literature`: 1
- `rejected_political_history_nonfiction`: 1
- `rejected_political_manifesto_history_domain`: 1
- `rejected_political_nonfiction_domain`: 1
- `rejected_political_philosophy_domain`: 6
- `rejected_political_philosophy_not_literature`: 1
- `rejected_political_science_domain`: 1
- `rejected_political_science_not_literature`: 1
- `rejected_political_theory_domain`: 1
- `rejected_psychoanalysis_not_literature`: 1
- `rejected_quotation_fragment`: 5
- `rejected_quotation_fragment_duplicate_of_ode_to_joy`: 1
- `rejected_quotation_fragment_not_work`: 1
- `rejected_quotation_line_not_title`: 1
- `rejected_religion_motif_not_work`: 1
- `rejected_religion_science_polemic_domain`: 1
- `rejected_religion_scripture_domain`: 3
- `rejected_religion_theology_domain`: 2
- `rejected_religious_historical_criticism_not_literature_reading_list`: 1
- `rejected_science_domain`: 1
- `rejected_science_not_literature`: 4
- `rejected_science_psychology_domain`: 1
- `rejected_science_term_not_work`: 2
- `rejected_sermon_historical_document`: 1
- `rejected_slogan_or_motto_context`: 1
- `rejected_social_science_anthropology`: 4
- `rejected_social_science_psychoanalysis`: 5
- `rejected_social_science_psychology`: 7
- `rejected_sociopolitical_concept`: 1
- `rejected_song_anthem_not_literature_product`: 4
- `rejected_song_fragment`: 1
- `rejected_song_not_literature_product`: 6
- `rejected_song_not_work`: 1
- `rejected_song_or_anthem_not_literature_reading_list`: 1
- `rejected_song_title_collision`: 1
- `rejected_sports_not_work`: 1
- `rejected_subtitle_duplicate_of_walden`: 1
- `rejected_subtitle_fragment_not_work`: 1
- `rejected_subwork_or_section_title`: 1
- `rejected_subwork_title_variant`: 1
- `rejected_television_not_literature`: 4
- `rejected_television_or_sports_context`: 1
- `rejected_theater_title_but_pop_context_low_confidence`: 1
- `rejected_theology_philosophy_not_literature`: 1
- `rejected_title_fragment`: 1
- `rejected_title_fragment_duplicate`: 1
- `rejected_title_fragment_duplicate_of_tristram_shandy`: 1
- `rejected_visual_art_not_literature`: 1

## Outputs

- `quizbowl_lit_title_candidates.tsv`
- `quizbowl_lit_mentions.tsv`
- `quizbowl_lit_clusters.tsv`
- `quizbowl_lit_canon_scores.tsv`
- `quizbowl_lit_false_positive_review.tsv`
- `quizbowl_lit_rejected.tsv`
- `quizbowl_lit_audit_queue.tsv`
- `quizbowl_lit_llm_review_queue.jsonl`
- `_data/quizbowl_literature_canon.yml`

## Caveats

This is an independent quizbowl-corpus build. It uses answerlines only when the raw question prompt asks for a literary work, then counts both answerline frequency and clue-text mentions. Quizbowl track labels are diagnostic metadata for audit and category sanity checks, not inclusion evidence.
