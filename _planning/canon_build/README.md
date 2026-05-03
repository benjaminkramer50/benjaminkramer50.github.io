# Canon Build Layer

This directory is the pivot from a hand-maintained 3,000-item path toward a source-backed canon build.

The public YAML path remains the incumbent display artifact. The scholarly build layer separates source evidence, candidate work identity, review decisions, scoring, and final path selection so omissions and cuts can be audited reproducibly.

## Layer Order

1. `tables/canon_source_registry.tsv`: sources to audit against.
2. `tables/canon_source_items.tsv`: raw works extracted from each source.
3. `tables/canon_work_candidates.tsv`: normalized work clusters, including current path rows and source-backed omissions.
4. `tables/canon_aliases.tsv` and `tables/canon_relations.tsv`: title variants, translations, contained works, series, duplicates, and selection relations.
5. `tables/canon_evidence.tsv`: work-level evidence records.
6. `tables/canon_review_decisions.yml`: human adjudication, waivers, and policy decisions.
7. `tables/canon_scores.tsv`: derived scores and penalties.
8. `tables/canon_replacement_candidates.tsv`: proposed add/cut transactions.
9. `tables/canon_path_selection.tsv`: selected rows for generated public paths.
10. `tables/canon_packet_status.tsv`: machine-readable packet status and next-action tracking.

## Gate

No further direct content-replacement wave should merge until the relevant rows in this build layer exist or the tracker records an explicit waiver.

Current validation is structural until the hardening pass is complete. A PASS means headers, uniqueness, and basic references are intact; it does not yet mean evidence is sufficient, taxonomy is complete, scoring is ready, or replacements are safe.

Source items are observations. Source-class policy and scoring scripts must derive weights centrally; row-level `evidence_weight` values are provisional notes until X016/source-weight policy is encoded.

Corpus rows, catalog records, edition-series metadata, and access metadata support identity, alias, edition, provenance, and boundary review. They must not be treated as standalone canon-selection evidence.
