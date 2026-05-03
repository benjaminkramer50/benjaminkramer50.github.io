# Canon Build Layer

This directory is the pivot from a hand-maintained 3,000-item path toward a source-backed canon build.

The public YAML path remains the incumbent display artifact. The scholarly build layer separates source evidence, candidate work identity, review decisions, scoring, and final path selection so omissions and cuts can be audited reproducibly.

The phase plan and lock criteria live in `canon_phase_plan.md`.

## Layer Order

1. `tables/canon_source_registry.tsv`: sources to audit against.
2. `tables/canon_source_items.tsv`: raw works extracted from each source.
3. `tables/canon_work_candidates.tsv`: normalized work clusters, including current path rows and source-backed omissions.
4. `tables/canon_aliases.tsv` and `tables/canon_relations.tsv`: title variants, translations, contained works, series, duplicates, and selection relations.
5. `tables/canon_match_candidates.tsv`, `tables/canon_match_review_queue.tsv`, and `tables/canon_match_review_decisions.tsv`: generated source-item match candidates, unresolved review rows, and reviewed next actions.
6. `tables/canon_relation_review_queue.tsv` and `tables/canon_relation_review_decisions.tsv`: candidate selection, contained-work, series, variant, duplicate, and adaptation decisions that should not yet be written as final relations.
7. `tables/canon_evidence.tsv`: work-level evidence records.
8. `tables/canon_review_decisions.yml`: human adjudication, waivers, and policy decisions.
9. `tables/canon_source_weights.yml`: central source-class policy used before scores are derived.
10. `tables/canon_scores.tsv`: derived scores and penalties.
11. `tables/canon_replacement_candidates.tsv`: proposed add/cut transactions.
12. `tables/canon_path_selection.tsv`: selected rows for generated public paths.
13. `tables/canon_packet_status.tsv`: machine-readable packet status and next-action tracking.

## Gate

No further direct content-replacement wave should merge until the relevant rows in this build layer exist or the tracker records an explicit waiver.

Current validation is structural until the hardening pass is complete. A PASS means headers, uniqueness, and basic references are intact; it does not yet mean evidence is sufficient, taxonomy is complete, scoring is ready, or replacements are safe.

Source items are observations. Source-class policy and scoring scripts must derive weights centrally; row-level `evidence_weight` values are provisional notes until X016/source-weight policy is encoded.

Corpus rows, catalog records, edition-series metadata, and access metadata support identity, alias, edition, provenance, and boundary review. They must not be treated as standalone canon-selection evidence.

Match/relation review decisions are routing records. A `create_source_backed_candidate` decision means "create a candidate row for later evidence, boundary, duplicate, and scoring review," not "add this work to the public path."

`scripts/canon_materialize_reviewed_candidates.rb` turns reviewed match decisions into provisional candidate rows and updates source-item, creator, work-creator, and alias tables. It does not generate evidence rows, write final relation rows, or change the public path.
