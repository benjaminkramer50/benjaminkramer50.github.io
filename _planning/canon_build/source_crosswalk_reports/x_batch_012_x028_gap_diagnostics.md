# X Batch 12 Report: X028 Diagnostic-First Gap Triage

Date: 2026-05-03

Status: diagnostics generated; public canon unchanged.

## Summary

X028 replaces the slow default of hand-auditing every B/C/D/F/I packet in sequence. The B/C/D/F/I packets remain the coverage namespace, but the first pass is now automated:

- `canon_coverage_matrix.tsv` ranks period, region, form, and intersection cells by selected coverage, source pressure, evidence, and source debt.
- `canon_sentinel_checks.tsv` checks maintained sentinel works against current path candidates, aliases, source items, and evidence.
- `canon_gap_diagnostics.tsv` merges sentinel failures, source-backed unmatched clusters, and red coverage cells.
- `canon_red_cell_audit_queue.tsv` gives the prioritized manual-review queue.

## Counts

| Artifact | Rows |
|---|---:|
| Coverage matrix | 123 |
| Sentinel targets checked | 57 |
| Sentinel failures/reviews | 0 |
| Source-backed unmatched clusters | 114 |
| Coverage red cells | 73 |
| Gap diagnostics | 187 |
| Red-cell audit queue | 120 |

## Top Red Cells

| Priority | Severity | Subject | Rationale |
|---:|---|---|---|
| 120 | critical | region_form: east_asia/graphic_visual_narrative | selected=0; unmatched_source_pressure=20; no_evidence_selected=0 |
| 111 | high | Fireflies | Unmatched source-title cluster appears in 4 source(s) and 4 source item(s). |
| 94 | high | Invitation to the Voyage | Unmatched source-title cluster appears in 2 source(s) and 3 source item(s). |
| 94 | high | Kubla Khan | Unmatched source-title cluster appears in 2 source(s) and 3 source item(s). |
| 93 | high | "A Peacock Southeast Flew" / A Peacock Southeast Flew | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | "Deer Enclosure" / Deer Enclosure | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | "Midnight Songs" / Midnight Songs | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | "The Ballad of Mulan" / Ballad of Mulan | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | "The Song of Lasting Regret" / The Song of Lasting Regret | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | 5 "Lesbia, let us live only for loving" / 5 [Lesbia, let us live only for loving] | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | 51 "To me that man seems like a god in heaven" / 51 [To me that man seems like a god in heaven] | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | 76 "If any pleasure can come to a man through recalling" / 76 [If any pleasure can come to a man through recalling] | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | A Martyr / The Martyr | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | Agamemnon / AGAMEMNON | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | Akashi | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | An Autumn Excursion | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | An Old and Established Name | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | Atsumori | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | Autumn Night / The autumn night | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |
| 93 | high | Begging for Food | Unmatched source-title cluster appears in 2 source(s) and 2 source item(s). |

## Interpretation

These diagnostics are triage, not final judgments. They are designed to make the remaining audit faster by showing where manual review is actually needed. A flagged row can resolve as an alias, contained selection, source extraction gap, true omission, or justified exclusion.

## Next Actions

1. Review the highest-priority `canon_red_cell_audit_queue.tsv` rows before starting any broad B/C/D/F/I packet sweep.
2. Expand `canon_sentinel_targets.yml` by region/tradition after reviewing the first failures.
3. Continue high-yield source extraction where diagnostics show source gaps, including E006 Bedford fragments and later American/British anthology rows.
