# Canon Source-Item Extraction Plan

Generated on: 2026-05-03

Status: active.

## Purpose

The source registry says which sources matter. It does not yet prove coverage. This plan defines the next extraction packets that convert registered sources into `canon_source_items.tsv` rows, then into matched evidence rows.

Direct public-list replacements remain paused until these packets produce source items, matches, and evidence.

## Extraction Contract

Each extraction packet must return:

- source pages, files, APIs, or catalog endpoints checked,
- extraction feasibility: complete, partial, metadata-only, blocked, or context-only,
- source-item rows using the `canon_source_items.tsv` schema,
- match status: `matched_current_path`, `represented_by_selection`, `duplicate_or_variant`, `out_of_scope`, or `unresolved`,
- alias/contained-work/cycle risks,
- copyright/access limits.

No packet may treat a corpus/database as a canon list. Corpus rows supply metadata and access evidence; anthology, syllabus, edition-series, and reference rows receive different weights later.

## Active Agent Batch

| Packet | Source layers | Status | Output target |
|---|---|---|---|
| X001 | `e008_perseus_catalog_greek_latin_works`; `e008_phi_classical_latin_texts` | Running | Classical open metadata pilot rows |
| X002 | `library_of_america_catalog`; `e012_loa_slave_narratives`; `e012_loa_african_american_poetry_2020` | Running | LOA catalog and contained-work pilot rows |
| X003 | `icelandic_saga_database`; `philobiblon_iberian_romance`; `arlima_medieval_literature`; `lancelot_grail_lacy_5vol`; `dante_digital_anchor_layer` | Running | Medieval corpus/catalog pilot rows |
| X004 | `norton_english_lit_11e_full_2024`; `longman_british_lit_period_volumes_2009_2017`; `broadview_british_lit_concise_a_b_2019_2024`; `longman_brit_lit_middle_ages_1a_4e`; `broadview_brit_lit_medieval_r3_2023`; `broadview_medieval_drama_2012` | Running | English/British and medieval anthology TOC feasibility and pilot rows |
| X005 | `columbia_lithum_current_2026`; `columbia_lithum_historical_1937_present`; `princeton_humanities_sequences_2024`; `oxford_worlds_classics_online`; `princeton_damrosch_world_literature_2003` | Running | University/reference list pilot rows |
| X006 | `e012_norton_african_american_lit_4e_v1_2025`; `e012_norton_african_american_lit_4e_v2_2025`; `e012_locke_new_negro_1925` | Running | African American anthology pilot rows |

## Planned Extraction Packets

| Packet | Source layers | Purpose |
|---|---|---|
| X007 | `e008_loeb_classical_library_digital`; `e008_oxford_classical_dictionary_online`; `e008_oxford_scholarly_editions_oct`; `e008_cambridge_greek_latin_classics` | Classical edition/reference metadata after open-catalog pilot |
| X008 | `norton_world_lit_5e_full_pre1650`; `norton_world_lit_5e_full_post1650`; `longman_world_lit_2e_2009`; `bedford_world_lit_compact_v1_2009`; `bedford_world_lit_compact_v2_2008` | World-literature anthology TOC extraction and access blockers |
| X009 | `dumbarton_oaks_medieval_library`; `mgh_medieval_latin_sources`; `bibliotheca_augustana_germanica`; `wimmer_medieval_german_anthology`; `minnereden_lovesongs_digital`; `osta_2_old_spanish_textual_archive` | Medieval edition/corpus metadata not covered by X003 |
| X010 | `norton_american_lit_10e_pre1865`; `norton_american_lit_10e_post1865`; `heath_american_lit_7e_2014` | American anthology TOC extraction |
| X011 | `bloom_curated_seed_layer` | Recover or reconstruct the 200-row Bloom seed layer |
| X012 | `bloom_full_appendix_1994`; `bloom_full_appendix_review_batches` | Recover, reconstruct, or permanently block Bloom appendix raw/review artifacts |
| X013 | All extracted source items | Title/creator normalization and incumbent path matching |
| X014 | All extracted source items | Alias, contained-work, series, and cycle relation creation |
| X015 | All matched source items | Evidence-row generation into `canon_evidence.tsv` |
| X016 | All source types | Evidence weighting policy by anthology, syllabus, edition, reference, corpus, and internal record |
| X017 | All unresolved source items | Omission queue creation with duplicate and boundary checks |
| X018 | Current path plus omissions | Scored replacement transaction candidates |

## Integration Gate

An extraction packet can be integrated only after:

- generated rows pass schema validation,
- source IDs exist in `canon_source_registry.tsv`,
- source item IDs are stable and unique,
- source URLs/citations are traceable,
- match status is explicit,
- source-type weight is not assumed from registry presence,
- no copyrighted text is copied into the repo.
