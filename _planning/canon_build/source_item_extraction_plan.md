# Canon Source-Item Extraction Plan

Generated on: 2026-05-03

Status: active.

## Purpose

The source registry says which sources matter. It does not yet prove coverage. This plan defines the next extraction packets that convert registered sources into `canon_source_items.tsv` rows, then into matched evidence rows.

Direct public-list replacements remain paused until these packets produce source items, matches, and evidence.

## Registered Source-Crosswalk Batches

| Batch | Packets | Status | Report |
|---|---|---|---|
| E Batch 1 | E001-E006 | Registered; E001 extracted; E004 Norton World Literature 5e extracted by X026; E005 Longman World Literature 2e extracted by X027; E006 Bedford fragment extraction pending | `source_crosswalk_reports/e_batch_001_e001_e006.md` |
| E Batch 2 | E007-E012 | Registered; X001-X006 pilot rows ingested; full extraction pending | `source_crosswalk_reports/e_batch_002_e007_e012.md` |
| E Batch 3 | E013-E018 | Registered; X020-X025 generated/updated 2,690 E013/E014/E015/E016/E017/E018 source-item observations; current table has 5,942 total source-item rows after X027; X013/X014/X017 queues rerun after X027; remaining source debt is explicit for blocked full Traditional Chinese CPL TOC and official Oxford modern Indian poem-level reconciliation | `source_crosswalk_reports/e_batch_003_e013_e018.md` |

## Extraction Contract

Each extraction packet must return:

- source pages, files, APIs, or catalog endpoints checked,
- extraction feasibility: complete, partial, metadata-only, blocked, or context-only,
- source-item rows using the `canon_source_items.tsv` schema,
- match status: `matched_current_path`, `represented_by_selection`, `duplicate_or_variant`, `out_of_scope`, or `unresolved`,
- alias/contained-work/cycle risks,
- copyright/access limits.

No packet may treat a corpus/database as a canon list. Corpus rows supply metadata and access evidence; anthology, syllabus, edition-series, and reference rows receive different weights later.

## Completed Extraction Batches

| Packet | Source layers | Status | Output target |
|---|---|---|---|
| X001 | `e008_perseus_catalog_greek_latin_works`; `e008_phi_classical_latin_texts` | Pilot ingested | Classical open metadata pilot rows |
| X002 | `library_of_america_catalog`; `e012_loa_slave_narratives`; `e012_loa_african_american_poetry_2020` | Pilot ingested | LOA catalog and contained-work pilot rows |
| X003 | `icelandic_saga_database`; `philobiblon_iberian_romance`; `arlima_medieval_literature`; `lancelot_grail_lacy_5vol`; `dante_digital_anchor_layer` | Pilot ingested | Medieval corpus/catalog pilot rows |
| X004 | `norton_english_lit_11e_full_2024`; `longman_british_lit_period_volumes_2009_2017`; `broadview_british_lit_concise_a_b_2019_2024`; `longman_brit_lit_middle_ages_1a_4e`; `broadview_brit_lit_medieval_r3_2023`; `broadview_medieval_drama_2012` | Pilot ingested | English/British and medieval anthology TOC feasibility and pilot rows |
| X005 | `columbia_lithum_current_2026`; `columbia_lithum_historical_1937_present`; `princeton_humanities_sequences_2024`; `oxford_worlds_classics_online`; `princeton_damrosch_world_literature_2003` | Pilot ingested | University/reference list pilot rows |
| X006 | `e012_norton_african_american_lit_4e_v1_2025`; `e012_norton_african_american_lit_4e_v2_2025`; `e012_locke_new_negro_1925` | Pilot ingested | African American anthology pilot rows |
| X007 | `e008_loeb_classical_library_digital`; `e008_oxford_classical_dictionary_online`; `e008_oxford_scholarly_editions_oct`; `e008_cambridge_greek_latin_classics` | Feasibility complete, pilot rows held | Classical edition/reference metadata; corpus/edition rows cannot count as canon votes without source-weight policy |
| X008 | `norton_world_lit_5e_full_pre1650`; `norton_world_lit_5e_full_post1650`; `longman_world_lit_2e_2009`; `bedford_world_lit_compact_v1_2009`; `bedford_world_lit_compact_v2_2008` | Feasibility complete, pilot rows held | Norton 5e official TOC extractable; Longman partial; Bedford fragment-only |
| X009 | `dumbarton_oaks_medieval_library`; `mgh_medieval_latin_sources`; `bibliotheca_augustana_germanica`; `wimmer_medieval_german_anthology`; `minnereden_lovesongs_digital`; `osta_2_old_spanish_textual_archive` | Feasibility complete, pilot rows held | Medieval edition/corpus metadata; mostly identity/access/context evidence |
| X010 | `norton_american_lit_10e_pre1865`; `norton_american_lit_10e_post1865`; `heath_american_lit_7e_2014` | Feasibility complete, pilot rows held | American anthology TOCs; Heath Vol. A item-level gap remains |
| X011 | `bloom_curated_seed_layer` | Blocked | Exact 200-row seed cannot be recovered from target repo or current path annotations |
| X012 | `bloom_full_appendix_1994`; `bloom_full_appendix_review_batches` | Recoverable but policy-gated | Local untracked Bloom artifacts found outside target worktree; do not publish or score full appendix blindly |
| X020 | `e018_columbia_modern_korean_fiction_2005`; `e018_columbia_premodern_korean_prose_2018`; `e014_rienner_anthology_african_lit_2007` | Source items ingested, X013/X014 queued | 85 E014/E018 source-item observations; no evidence rows or public path changes |
| X021 | `e013_oxford_latin_american_short_stories_1997`; `e013_oxford_latin_american_poetry_2009`; `e013_fsg_20c_latin_american_poetry_2011`; `columbia_modern_chinese_lit_2e_2007`; `columbia_traditional_chinese_lit_1996`; `e017_columbia_modern_japanese_lit_v1_2005` | Source items ingested, X013/X014 queued | 238 E013/E016/E017 source-item observations; 2 complete public TOCs and 4 partial pilots; no evidence rows or public path changes |
| X022 | `e013_fsg_20c_latin_american_poetry_2011`; `e013_oxford_latin_american_poetry_2009`; `e014_rienner_anthology_african_lit_2007`; `oxford_modern_indian_poetry_1998`; `clay_sanskrit_library_56vol`; `murty_classical_library_india`; `e017_columbia_modern_japanese_lit_v2_2007`; `e018_columbia_traditional_korean_poetry_2003`; `e018_lti_korea_digital_library_classics` | Source items ingested, X013/X014 queued | 697 parser-backed E013/E014/E015/E017/E018 source-item observations generated/updated across public TOCs, series lists, and metadata endpoints; no evidence rows or public path changes |
| X023 | `brians_modern_south_asian_lit_english_2003`; `e014_penguin_modern_african_poetry_4e_2007`; `e014_african_writers_series_heinemann_penguin`; `e017_columbia_traditional_japanese_lit_2007`; `e017_columbia_early_modern_japanese_lit_2002` | Source items ingested, X013/X014/X017 rerun | 334 additional rows: 239 Penguin African poem-level rows, 48 African Writers Series metadata rows, 15 Brians chapter-context rows, and 32 audited Japanese major-work rows; 55 new evidence rows after matching; no public path changes |
| X024 | `columbia_modern_chinese_lit_2e_2007`; `e017_columbia_traditional_japanese_lit_2007`; `e017_columbia_early_modern_japanese_lit_2002`; `e014_cambridge_history_african_caribbean_lit_2000`; `e013_cambridge_history_latin_american_lit_1996`; `chinese_text_project_premodern` | Source items ingested, X013/X014/X017 rerun | 1,059 generated rows from LOC Modern Chinese, LOC/Dandelon Japanese, Cambridge African/Caribbean and Latin American chapter-context rows, and Chinese Text Project metadata; full Columbia Traditional Chinese and Oxford modern Indian poem-level official-copy debt retained explicitly |
| X025 | `shorter_columbia_traditional_chinese_lit_2000`; `cambridge_history_chinese_lit_2010`; `columbia_traditional_chinese_lit_1996`; `oxford_modern_indian_poetry_1998` | Source items ingested, X013/X014/X017 rerun | 277 generated rows: 262 Shorter Columbia Traditional Chinese public TOC rows and 15 Cambridge Chinese chapter-context rows; full Columbia CPL and Oxford Indian poem-level official-copy debts remain unresolved and explicit |
| X026 | `norton_world_lit_5e_full_pre1650`; `norton_world_lit_5e_full_post1650` | Source items ingested, X013/X014/X017 rerun | 1,586 official Norton World Literature 5e TOC rows from Vols. A-F; 116 provisional exact matches generated evidence rows after rerun; no public path changes |
| X027 | `longman_world_lit_2e_2009` | Source items ingested, X013/X014/X017 rerun | 1,644 Longman World Literature 2e public TOC rows from Vols. A-F; 112 provisional exact matches generated evidence rows after rerun; no public path changes |
| X028 | All current works, source items, evidence rows, source debt rows, and sentinel targets | Diagnostics generated | Coverage matrix, 57 sentinel checks, 185 gap diagnostics, and 120 red-cell audit rows generated; Washington Irving, Frederick Douglass, and Emily Dickinson sentinels resolve as present; public path unchanged |
| X029 | X028 red-cell audit queue | Triage generated | 120 red-cell rows classified into omission-candidate, variant-alias, existing-match, subwork/scope, coverage, and source-debt/taxonomy routes; public path unchanged |
| X030 | X029 title-level rows | Review decisions recorded | 25 clear title-route decisions recorded: variants/aliases, contained-work or collection coverage, and a small set of boundary-review omission candidates; public path unchanged |
| X031 | X030 reviewed title variants | Aliases added | 7 safe source-title variant aliases added for existing selected works; contained poem/excerpt rows intentionally left for relation/scope review; public path unchanged |

## Planned Extraction Packets

| Packet | Source layers | Purpose |
|---|---|---|
| X013 | All extracted source items | Generated after X027: 529 title/creator normalization candidates and 5,474 explicit match-review decisions |
| X014 | All extracted source items | Generated after X027: 7,567 alias, contained-work, series, selection, variant, adaptation, and duplicate relation-scope rows; 0 final relations ready |
| X015 | All source and work tables | Hardening pass: controlled-value validation, status coherence, source-fetch/extraction denominators, and packet status table |
| X016 | All source types | Draft created: evidence weighting policy by anthology, syllabus, edition, reference, corpus, access metadata, award, national canon, and internal record |
| X017 | All matched source items | Evidence-row generation and source-debt closure rules after X016 policy is encoded |
| X018 | All unresolved source items | Omission queue creation with duplicate, boundary, chronology, source-family, and item-scope checks |
| X019 | Current path plus omissions | Scored replacement transaction candidates only after coverage targets and quality issues exist |

## Integration Gate

An extraction packet can be integrated only after:

- generated rows pass schema validation,
- source IDs exist in `canon_source_registry.tsv`,
- source item IDs are stable and unique,
- source URLs/citations are traceable,
- match status is explicit,
- source-type weight is not assumed from registry presence,
- source-class, item-scope, access/provenance, and extraction-denominator status are explicit or queued,
- source-item `evidence_weight` is treated as provisional observation metadata until derived scoring exists,
- no copyrighted text is copied into the repo.
