# Quizbowl Literature Canon Method Report

Generated: 2026-05-06T05:27:37Z

## Corpus

- Database: `/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db`
- Source table: `archive_parsed_questions`
- Rows processed: 2216999
- Evidence fields: raw `answerline` and raw `clue_text`
- Diagnostic field: `archive_practice_questions.track_id` for quizbowl category counts only
- Adjudication file: `_planning/quizbowl_lit_canon/quizbowl_lit_adjudications.yml` (2567 decisions)
- Manual alias rules: 298 loaded, 297 applied after pass 1
- Worker processes: 6
- Explicitly not used for evidence: `archive_canon_refinement_runs`, `archive_canon_answerline_candidates`
- Threshold: total distinct quizbowl questions >= 3

## Candidate Extraction

- Raw answerline work candidates: 9334
- Exact-match work-title seeds from answerlines and clues: 6371
- Exact-match seed basis counts: `answerline`=964, `answerline_and_clue`=1276, `clue`=4131
- Raw normalized candidates: 81587
- Candidates clearing threshold: 20245
- Public YAML rows after accepted-work filtering: 5327
- Rejected non-literature candidates: 3902
- Audit queue rows: 19340
- LLM review queue rows: 500
- Evidence/example rows written: 87330

## Review Routing

- Accepted works require repeated quizbowl evidence and are strongest when raw answerline prompts identify the title as a literary form.
- Non-literary context signals are counted across all observed snippets, not just displayed examples.
- Strong raw answerline forms such as novel, play, poem, story, epic, saga, and collection can override noisy clue mentions from music, film, or other adaptation contexts.
- Generic book/work/essay prompts do not override non-literary context dominance; those candidates are rejected from the public literature canon.

## Tier Counts

- `qb_candidate`: 11016
- `qb_contextual`: 2615
- `qb_core`: 1066
- `qb_major`: 1646
- `qb_rejected`: 3902

## Review Status Counts

- `accepted_likely_work`: 5327
- `merged_duplicate_title_variant`: 1
- `needs_review_act_title_boundary`: 1
- `needs_review_alternate_poem_title_boundary`: 1
- `needs_review_ambiguous_collection_fragment_boundary`: 1
- `needs_review_ambiguous_common_literary_title`: 4
- `needs_review_ambiguous_generic_play_title_boundary`: 1
- `needs_review_ambiguous_history_or_modern_novel_title`: 1
- `needs_review_ambiguous_literary_novella_or_opera_context`: 1
- `needs_review_ambiguous_literary_title_boundary`: 1
- `needs_review_ambiguous_multiple_works`: 1
- `needs_review_ambiguous_music_literature_title`: 4
- `needs_review_ambiguous_novel_title_boundary`: 1
- `needs_review_ambiguous_play_title_boundary`: 1
- `needs_review_ambiguous_poem_story_title_boundary`: 1
- `needs_review_ambiguous_short_story_or_common_title`: 1
- `needs_review_ambiguous_short_story_or_title_story_boundary`: 1
- `needs_review_ambiguous_single_poem_boundary`: 1
- `needs_review_ambiguous_title_and_evidence_points_to_chapter_phrase`: 1
- `needs_review_ambiguous_tolstoy_novel_or_mahler_symphony_context`: 1
- `needs_review_chapter_title_boundary`: 1
- `needs_review_character_or_shelley_poem_boundary`: 1
- `needs_review_common_or_short_title`: 3085
- `needs_review_common_title_or_character_boundary`: 1
- `needs_review_essay_collection_boundary`: 1
- `needs_review_fragment_title`: 3
- `needs_review_hero_or_title_fragment_boundary`: 1
- `needs_review_journalism_history_boundary`: 1
- `needs_review_literary_criticism_philosophy_boundary`: 1
- `needs_review_literary_criticism_theory_boundary`: 9
- `needs_review_low_evidence`: 3327
- `needs_review_major_subwork_boundary`: 2
- `needs_review_malformed_title_needs_canonicalization`: 1
- `needs_review_mixed_literary_poem_and_music_evidence`: 1
- `needs_review_mixed_poem_or_philosophy_example`: 1
- `needs_review_non_literature_track_context`: 732
- `needs_review_philosophy_economics_satire_boundary`: 1
- `needs_review_poem_sequence_or_title_fragment_boundary`: 1
- `needs_review_possible_character_or_person`: 2686
- `needs_review_possible_combined_title`: 687
- `needs_review_preface_or_subwork_boundary`: 1
- `needs_review_religion_devotional_boundary`: 2
- `needs_review_religious_autobiography_boundary`: 2
- `needs_review_scripture_or_old_english_poem_boundary`: 1
- `needs_review_scripture_religion_boundary`: 1
- `needs_review_section_or_cycle_boundary`: 2
- `needs_review_section_or_poem_boundary`: 1
- `needs_review_section_or_refrain_boundary`: 1
- `needs_review_section_or_short_title_boundary`: 1
- `needs_review_section_or_subwork_title`: 411
- `needs_review_section_title_boundary`: 13
- `needs_review_section_title_duplicate_of_labyrinth_of_solitude`: 1
- `needs_review_section_title_or_ambiguous_work_boundary`: 1
- `needs_review_sequence_or_section_title_boundary`: 1
- `needs_review_single_poem_or_section_boundary`: 1
- `needs_review_speech_or_poetics_text_boundary`: 1
- `needs_review_title_collision_or_generic_phrase_requires_split`: 1
- `needs_review_title_collision_requires_author_aware_split`: 1
- `needs_review_title_fragment_boundary`: 1
- `needs_review_title_fragment_duplicate_boundary`: 2
- `needs_review_title_needs_canonicalization`: 1
- `needs_review_title_variant_boundary`: 1
- `rejected_abbreviated_title_fragment`: 1
- `rejected_act_title_not_standalone_work`: 3
- `rejected_address_fragment_or_common_title`: 1
- `rejected_adjective_not_work`: 2
- `rejected_adjective_or_culture_label_not_work`: 1
- `rejected_adjective_or_title_fragment`: 1
- `rejected_ambiguous_film_or_title_fragment`: 1
- `rejected_ambiguous_music_literature_title`: 1
- `rejected_ambiguous_non_literary_context`: 1
- `rejected_ambiguous_religion_or_section_title`: 1
- `rejected_ambiguous_title_fragment`: 1
- `rejected_anthem_or_music_not_literary_work`: 1
- `rejected_anthropology_section_title_not_standalone_work`: 1
- `rejected_art_criticism_not_literature`: 1
- `rejected_beat_memoir_low_lit_confidence`: 1
- `rejected_biblical_motif_or_subwork`: 2
- `rejected_biblical_parable_or_poem_fragment`: 1
- `rejected_biblical_phrase_not_work`: 1
- `rejected_carol_song_not_literary_work`: 1
- `rejected_chapter_title_duplicate_of_walden`: 1
- `rejected_chapter_title_not_standalone_work`: 1
- `rejected_character_alias_not_work`: 1
- `rejected_character_name_not_work`: 12
- `rejected_character_name_or_story_fragment`: 1
- `rejected_character_nickname_not_work`: 7
- `rejected_character_not_work`: 6
- `rejected_character_or_adjacent_title_fragment`: 1
- `rejected_character_or_title_fragment`: 4
- `rejected_character_pair_not_work`: 3
- `rejected_character_phrase_not_work`: 7
- `rejected_character_title_fragment`: 1
- `rejected_christian_apologetics_not_literature_reading_list`: 1
- `rejected_clue_fragment_not_work`: 2
- `rejected_combined_title_author_prompt`: 252
- `rejected_common_title_ambiguous_not_standalone`: 4
- `rejected_common_title_fragment`: 3
- `rejected_common_title_or_opera_section_not_work`: 1
- `rejected_common_word_parser_artifact`: 4
- `rejected_common_word_song_fragment`: 1
- `rejected_common_word_title_fragment`: 5
- `rejected_comparative_mythology_not_literature_product`: 1
- `rejected_computer_science_not_literature`: 1
- `rejected_critical_theory_domain`: 5
- `rejected_critical_theory_section`: 1
- `rejected_descriptor_fragment`: 16
- `rejected_dictionary_reference_not_literature`: 1
- `rejected_duplicate_history_title_variant`: 1
- `rejected_duplicate_or_art_context_variant`: 1
- `rejected_duplicate_or_malformed_title_variant`: 1
- `rejected_duplicate_or_phrase_fragment`: 1
- `rejected_duplicate_or_wrong_title_variant`: 1
- `rejected_duplicate_title_variant`: 27
- `rejected_duplicate_translation_variant_of_shahnameh`: 2
- `rejected_economics_domain`: 1
- `rejected_economics_nonfiction_domain`: 1
- `rejected_embedded_artwork_not_standalone_work`: 1
- `rejected_embedded_blog_or_motif_not_work`: 1
- `rejected_embedded_concept_not_work`: 1
- `rejected_embedded_fictional_or_philosophy_text_not_literary_work`: 1
- `rejected_embedded_fictional_text_not_standalone_work`: 2
- `rejected_embedded_fictional_work_not_standalone`: 1
- `rejected_embedded_play_or_art_subject_not_work`: 1
- `rejected_embedded_play_title_fragment`: 2
- `rejected_embedded_text_not_public_literature`: 1
- `rejected_environmental_ethics_not_literature`: 1
- `rejected_epithet_or_period_label_not_work`: 1
- `rejected_epithet_or_title_fragment`: 1
- `rejected_feminist_social_criticism_domain`: 1
- `rejected_fictional_book_not_work`: 1
- `rejected_fictional_book_or_film_context_not_work`: 1
- `rejected_fictional_embedded_work`: 1
- `rejected_figures_not_work`: 1
- `rejected_film_color_fragment_not_work`: 1
- `rejected_film_context`: 2
- `rejected_film_context_artifact`: 1
- `rejected_film_context_not_literary_work`: 1
- `rejected_film_not_literature_product`: 4
- `rejected_film_pop_context`: 1
- `rejected_film_theory_not_literature`: 1
- `rejected_film_title_or_common_word_not_literary_work`: 1
- `rejected_film_title_or_wrong_work_variant`: 1
- `rejected_film_trilogy_not_literary_work`: 1
- `rejected_fragment_title_artifact`: 6
- `rejected_game_or_section_inside_play_not_work`: 1
- `rejected_generic_category_label`: 1
- `rejected_generic_collection_title`: 2
- `rejected_generic_form_label_not_work`: 2
- `rejected_genre_label_not_work`: 1
- `rejected_genre_label_or_title_fragment`: 1
- `rejected_group_name_not_work`: 1
- `rejected_group_not_work`: 1
- `rejected_group_or_motif_not_work`: 1
- `rejected_historical_document_domain`: 2
- `rejected_historical_event_not_work`: 3
- `rejected_historical_period_or_epithet_not_work`: 1
- `rejected_history_biography_domain`: 4
- `rejected_history_cultural_criticism_not_literature`: 1
- `rejected_history_domain`: 11
- `rejected_history_essay_domain`: 1
- `rejected_history_geography_domain`: 1
- `rejected_history_journalism_not_literature`: 2
- `rejected_history_religion_domain`: 2
- `rejected_history_social_criticism_not_literature`: 1
- `rejected_history_social_science_domain`: 1
- `rejected_institution_not_work`: 1
- `rejected_institution_or_motif_not_work`: 1
- `rejected_journalism_history_boundary_not_public_literature`: 1
- `rejected_language_not_work`: 1
- `rejected_language_or_adjective_not_work`: 6
- `rejected_language_or_period_label_not_work`: 1
- `rejected_law_domain`: 1
- `rejected_legal_document_domain`: 1
- `rejected_legal_political_essay_domain`: 1
- `rejected_linguistics_cognitive_science_not_literature`: 1
- `rejected_linguistics_domain`: 1
- `rejected_linguistics_nonfiction_domain`: 1
- `rejected_literary_criticism_boundary_not_public_list`: 1
- `rejected_literary_movement_label_not_work`: 4
- `rejected_literary_period_label_not_work`: 1
- `rejected_literary_technical_study_boundary_not_public_list`: 1
- `rejected_magazine_feature_not_work`: 1
- `rejected_malformed_title_fragment`: 1
- `rejected_medical_parenting_domain`: 1
- `rejected_memoir_or_slogan_not_public_literature`: 1
- `rejected_misspelled_title_or_philosophy_example_fragment`: 1
- `rejected_motif_not_work`: 2
- `rejected_motif_or_refrain_not_work`: 1
- `rejected_music_adjective_or_language_fragment_not_work`: 1
- `rejected_music_collection_or_scripture_domain`: 1
- `rejected_music_context_not_literary_work`: 6
- `rejected_music_context_not_work`: 1
- `rejected_music_context_or_common_title`: 1
- `rejected_music_context_or_common_word_not_work`: 1
- `rejected_music_context_or_generic_label_not_work`: 1
- `rejected_music_context_or_generic_title`: 1
- `rejected_music_context_or_person_not_work`: 1
- `rejected_music_nickname_not_literary_work`: 1
- `rejected_music_not_literature`: 1
- `rejected_music_or_prop_title_fragment`: 1
- `rejected_music_or_section_title_fragment`: 1
- `rejected_music_prayer_title_collision`: 1
- `rejected_mythic_descriptor_not_work`: 1
- `rejected_mythic_object_not_work`: 1
- `rejected_mythology_category_not_work`: 4
- `rejected_name_or_music_context_not_work`: 1
- `rejected_newspaper_not_work`: 1
- `rejected_nickname_or_character_fragment`: 1
- `rejected_non_literary_context`: 2895
- `rejected_non_literary_music`: 13
- `rejected_non_literary_music_context`: 2
- `rejected_non_literary_music_piece`: 2
- `rejected_non_literary_musical`: 6
- `rejected_non_literary_opera`: 2
- `rejected_non_literary_opera_cycle`: 2
- `rejected_non_literary_or_insufficient_literary_work_evidence`: 30
- `rejected_non_literature_domain`: 9
- `rejected_object_name_not_work`: 1
- `rejected_object_or_pet_name_not_work`: 1
- `rejected_oeuvre_grouping_not_work`: 2
- `rejected_oratorio_not_literature`: 1
- `rejected_parser_artifact`: 11
- `rejected_parser_artifact_or_tv_channel`: 1
- `rejected_parser_fragment`: 1
- `rejected_part_title_duplicate_of_angels_in_america`: 1
- `rejected_period_label_not_work`: 1
- `rejected_person_case_not_work`: 1
- `rejected_person_epithet_not_work`: 5
- `rejected_person_name_not_work`: 1
- `rejected_person_not_work`: 8
- `rejected_person_or_character_name_not_work`: 1
- `rejected_person_or_essay_title_fragment`: 1
- `rejected_person_or_music_context_not_work`: 2
- `rejected_person_or_poem_address_not_work`: 1
- `rejected_person_or_title_fragment`: 1
- `rejected_philosophy_combined_title_domain`: 2
- `rejected_philosophy_concept`: 2
- `rejected_philosophy_concept_not_evidenced_shelley_novel`: 1
- `rejected_philosophy_critical_theory`: 1
- `rejected_philosophy_domain`: 17
- `rejected_philosophy_essay_domain`: 1
- `rejected_philosophy_ethics_domain`: 1
- `rejected_philosophy_example_or_common_title`: 1
- `rejected_philosophy_fragment`: 2
- `rejected_philosophy_hermeneutics_not_literature`: 1
- `rejected_philosophy_history_domain`: 1
- `rejected_philosophy_lecture_not_literature`: 1
- `rejected_philosophy_linguistics_domain`: 1
- `rejected_philosophy_memoir_boundary_not_literature_public_list`: 1
- `rejected_philosophy_phrase`: 1
- `rejected_philosophy_political_theory_domain`: 1
- `rejected_philosophy_section_or_concept`: 1
- `rejected_philosophy_section_or_subwork`: 1
- `rejected_philosophy_social_criticism_domain`: 1
- `rejected_philosophy_social_theory_domain`: 1
- `rejected_philosophy_subtitle_fragment`: 2
- `rejected_philosophy_title_fragment`: 1
- `rejected_photo_documentary_domain`: 1
- `rejected_photography_domain`: 2
- `rejected_photography_theory_not_literature`: 1
- `rejected_photojournalism_social_history`: 1
- `rejected_phrase_or_section_not_work`: 1
- `rejected_place_not_work`: 1
- `rejected_place_or_music_fragment_not_work`: 1
- `rejected_place_or_theater_category_not_work`: 1
- `rejected_place_or_title_fragment`: 1
- `rejected_policy_document`: 1
- `rejected_political_document_domain`: 3
- `rejected_political_economics_domain`: 1
- `rejected_political_economics_not_literature`: 1
- `rejected_political_essay_adjacent_domain`: 1
- `rejected_political_extremist_propaganda_not_literature`: 1
- `rejected_political_forgery_not_literature`: 1
- `rejected_political_history_nonfiction`: 1
- `rejected_political_history_not_literature`: 1
- `rejected_political_label_not_work`: 1
- `rejected_political_manifesto_history_domain`: 1
- `rejected_political_memoir_not_literature`: 2
- `rejected_political_nonfiction_domain`: 1
- `rejected_political_open_letter_domain`: 1
- `rejected_political_pamphlet_document_domain`: 1
- `rejected_political_pamphlet_or_common_title_fragment`: 1
- `rejected_political_philosophy_domain`: 7
- `rejected_political_philosophy_not_literature`: 1
- `rejected_political_science_domain`: 3
- `rejected_political_science_not_literature`: 1
- `rejected_political_theory_domain`: 1
- `rejected_possessive_title_fragment`: 1
- `rejected_pronoun_title_fragment`: 1
- `rejected_psychoanalysis_mythology_domain`: 2
- `rejected_psychoanalysis_not_literature`: 1
- `rejected_psychology_linguistics_domain`: 1
- `rejected_psychology_or_religion_domain_not_literature`: 1
- `rejected_psychology_pop_science_not_literature`: 1
- `rejected_psychology_psychoanalysis_domain`: 1
- `rejected_psychology_psychoanalysis_not_literature`: 1
- `rejected_quizbowl_award_prompt_artifact`: 1
- `rejected_quizbowl_parser_artifact`: 8
- `rejected_quotation_fragment`: 5
- `rejected_quotation_fragment_duplicate_of_ode_to_joy`: 1
- `rejected_quotation_fragment_not_work`: 9
- `rejected_quotation_line_not_title`: 1
- `rejected_quotation_or_name_list_fragment`: 1
- `rejected_quotation_phrase_not_work`: 2
- `rejected_religion_combined_title_author_prompt`: 1
- `rejected_religion_devotional_domain`: 2
- `rejected_religion_esotericism_domain`: 1
- `rejected_religion_label_not_work`: 1
- `rejected_religion_motif_not_work`: 1
- `rejected_religion_philosophy_domain`: 2
- `rejected_religion_science_polemic_domain`: 1
- `rejected_religion_scripture_domain`: 8
- `rejected_religion_scripture_language_fragment`: 1
- `rejected_religion_theology_domain`: 3
- `rejected_religious_historical_criticism_not_literature_reading_list`: 1
- `rejected_science_astronomy_not_literature`: 1
- `rejected_science_domain`: 1
- `rejected_science_geology_not_literature`: 1
- `rejected_science_neurology_not_literature`: 1
- `rejected_science_not_literature`: 9
- `rejected_science_parser_artifact`: 1
- `rejected_science_psychology_domain`: 1
- `rejected_science_term_not_work`: 3
- `rejected_scripture_religion_domain`: 2
- `rejected_section_or_common_title_not_standalone`: 1
- `rejected_section_or_cycle_title`: 2
- `rejected_section_or_person_name_not_work`: 1
- `rejected_section_or_refrain_fragment`: 1
- `rejected_section_or_subwork_duplicate_of_masnavi`: 3
- `rejected_section_title_duplicate_of_hopscotch`: 1
- `rejected_section_title_duplicate_of_the_bridge`: 1
- `rejected_section_title_fragment`: 1
- `rejected_section_title_not_standalone_work`: 29
- `rejected_section_title_or_generic_domain_label`: 1
- `rejected_series_or_character_title_fragment`: 1
- `rejected_sermon_historical_document`: 1
- `rejected_slogan_or_motto_context`: 1
- `rejected_social_history_nonfiction_domain`: 1
- `rejected_social_science_anthropology`: 4
- `rejected_social_science_anthropology_domain`: 1
- `rejected_social_science_chapter_title`: 1
- `rejected_social_science_combined_title_domain`: 2
- `rejected_social_science_domain`: 2
- `rejected_social_science_feminist_criticism_domain`: 1
- `rejected_social_science_feminist_economics_domain`: 1
- `rejected_social_science_journalism_not_literature`: 1
- `rejected_social_science_law_domain`: 1
- `rejected_social_science_or_title_fragment_not_public_literature`: 1
- `rejected_social_science_pop_nonfiction_domain`: 1
- `rejected_social_science_postcolonial_theory_domain`: 1
- `rejected_social_science_psychoanalysis`: 5
- `rejected_social_science_psychology`: 7
- `rejected_social_science_sexology_domain`: 1
- `rejected_social_science_title_fragment`: 1
- `rejected_social_theory_domain`: 3
- `rejected_social_theory_history_of_technology_domain`: 1
- `rejected_sociopolitical_concept`: 1
- `rejected_song_anthem_not_literature_product`: 4
- `rejected_song_fragment`: 1
- `rejected_song_fragment_not_literary_work`: 1
- `rejected_song_from_musical_not_literary_work`: 2
- `rejected_song_not_literary_work`: 2
- `rejected_song_not_literature_product`: 6
- `rejected_song_not_work`: 1
- `rejected_song_or_anthem_not_literature_reading_list`: 1
- `rejected_song_or_common_word_not_work`: 1
- `rejected_song_or_section_title_not_standalone_work`: 1
- `rejected_song_title_collision`: 1
- `rejected_sports_not_work`: 1
- `rejected_style_manual_not_literature`: 1
- `rejected_subtitle_duplicate_of_flatland`: 1
- `rejected_subtitle_duplicate_of_pamela`: 1
- `rejected_subtitle_duplicate_of_walden`: 1
- `rejected_subtitle_fragment_not_work`: 1
- `rejected_subtitle_or_title_fragment`: 1
- `rejected_subwork_or_section_title`: 1
- `rejected_subwork_title_variant`: 1
- `rejected_television_not_literature`: 4
- `rejected_television_or_sports_context`: 1
- `rejected_theater_method_manual_not_literary_work`: 1
- `rejected_theater_title_but_pop_context_low_confidence`: 1
- `rejected_theology_philosophy_not_literature`: 1
- `rejected_title_fragment`: 2
- `rejected_title_fragment_duplicate`: 62
- `rejected_title_fragment_duplicate_of_tristram_shandy`: 1
- `rejected_title_fragment_or_activity_not_work`: 1
- `rejected_title_fragment_or_character_label`: 1
- `rejected_title_fragment_or_character_name`: 1
- `rejected_title_fragment_or_descriptor`: 1
- `rejected_title_fragment_or_person`: 1
- `rejected_title_fragment_or_religion_philosophy_boundary`: 1
- `rejected_visual_art_not_literature`: 2
- `rejected_visual_art_or_common_name_not_work`: 1
- `rejected_visual_natural_history_not_literature`: 1

## Public Classification Counts

Work forms: `collection_or_cycle`=411, `drama`=751, `epic_or_romance`=78, `essay_memoir_nonfiction`=227, `long_fiction`=1809, `poetry`=1025, `scripture_myth_hymn`=14, `short_fiction`=772, `unknown_form`=240

Eras: `ancient_classical`=170, `contemporary`=104, `early_modern`=250, `eighteenth_century`=69, `long_19th_century`=452, `medieval`=99, `modernist`=363, `postwar_modern`=379, `unknown_era`=3441

Regions/traditions: `african`=98, `american`=431, `arabic_persian_turkic`=106, `biblical_religious`=65, `caribbean`=35, `chinese`=70, `english_british_irish`=489, `french`=127, `germanic_scandinavian`=161, `greek`=129, `iberian_lusophone`=57, `indigenous_oceania`=26, `italian`=65, `japanese_korean`=80, `latin_american`=160, `roman_latin`=62, `russian_eastern_european`=183, `south_asian`=96, `unknown_region`=2887

Reading units: `ancient_epic_scripture_myth`=12, `classical_drama`=41, `collections_and_cycles`=297, `contemporary_global_literature`=104, `drama`=472, `early_modern_drama`=75, `early_modern_world_literature`=175, `eighteenth_century_prose_and_drama`=69, `epic_romance_or_oral_tradition`=40, `fiction_and_narrative`=1144, `literary_nonfiction`=160, `medieval_romance_saga`=99, `modernism`=363, `nineteenth_century_fiction`=156, `nineteenth_century_poetry_and_drama`=296, `poetry`=716, `postwar_global_literature`=80, `postwar_literature`=299, `scripture_myth_hymn`=12, `short_fiction`=529, `unclassified_unit`=188

Classification confidence: `rule_high`=1157, `rule_low`=2177, `rule_medium`=1899, `unknown_metadata`=94

Creator source: `codex_manual_metadata_correction`=9, `quizbowl_author_answerline`=1840, `reviewed_canon_record`=46, `unknown`=2676, `wikidata_metadata_overlay`=756

Creator confidence: `high`=723, `low`=579, `medium`=1349, `unknown`=2676

Chronology source: `codex_manual_metadata_correction`=8, `reviewed_canon_record`=46, `title_override`=20, `unknown`=4573, `wikidata_metadata_overlay`=680

Chronology confidence: `high`=741, `medium`=13, `unknown`=4573

Chronology rows needing review: 4573

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

Creator metadata is imported from reviewed local canon records where available and otherwise inferred from recurring quizbowl author-answerline clues. Rows without reliable creator evidence remain blank rather than receiving guessed attributions.

Chronology is intentionally conservative. Only reviewed local canon dates and explicit title-level overrides drive public chronological sorting; raw clue-text date mentions are too often dates for authors, settings, influences, prizes, or other works in the same clue, so unresolved rows are marked `Unplaced` until date enrichment is audited separately.
