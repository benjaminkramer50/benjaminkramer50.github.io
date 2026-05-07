# Quizbowl Literature Release Gates

Generated from `_data/quizbowl_literature_canon.yml`.

## Counts

- Public accepted rows: `4981`
- Chronology-ready rows: `2989`
- Creator-ready rows: `3216`
- Default reading-path rows: `2964`
- Creator-risk rows: `374`
- Duplicate-risk rows: `111`
- Boundary-risk rows: `0`
- Mandatory release-queue rows: `223`

## Stop Rule

Do not manually clear the full unplaced backlog for v1. Resolve the mandatory release queue, fix the default-path UI, and leave the low-salience long tail in the Unplaced view.

## Top Release Queue

| Rank | Count | Tier | Title | Gate Reasons | Issue Buckets | Action |
| ---: | ---: | --- | --- | --- | --- | --- |
| 1139 | 58 | `qb_major` | Confessions | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1215 | 54 | `qb_major` | Jerusalem | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1731 | 37 | `qb_major` | Grace | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1990 | 65 | `qb_major` | The Fall of Rome | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2014 | 47 | `qb_major` | The Gas Heart | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2016 | 20 | `qb_major` | The Vagina Monologues | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2018 | 44 | `qb_major` | Every Man in His Humor | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2021 | 43 | `qb_major` | The Fox and the Grapes | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2022 | 68 | `qb_major` | The Sun Rising | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2024 | 22 | `qb_major` | Menaechmi | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2025 | 35 | `qb_major` | Hesperides | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2026 | 45 | `qb_major` | Maria Stuart | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2028 | 39 | `qb_major` | The Autobiography of Malcolm X | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2033 | 62 | `qb_major` | The Four Ages of Man | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2039 | 32 | `qb_major` | The Cry of the Children | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2042 | 33 | `qb_major` | Radio Golf | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2044 | 66 | `qb_major` | The Golden One | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2045 | 31 | `qb_major` | The Catch | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2047 | 47 | `qb_major` | The Third and Final Continent | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2052 | 47 | `qb_major` | Sizwe Bansi is Dead | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2056 | 24 | `qb_major` | Directive | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2057 | 42 | `qb_major` | Ah Sin | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2058 | 25 | `qb_major` | Zazie in the Metro | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2059 | 25 | `qb_major` | Pharsalia | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2063 | 41 | `qb_major` | The Day Lady Died | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2068 | 28 | `qb_major` | Conquistador | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2076 | 62 | `qb_major` | Church Without Christ | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2077 | 63 | `qb_major` | Evenings on a Farm | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2079 | 32 | `qb_major` | The Man He Killed | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2084 | 22 | `qb_major` | Rasselas | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |

## Output Files

- `quizbowl_lit_creator_risk.tsv`
- `quizbowl_lit_duplicate_risk.tsv`
- `quizbowl_lit_boundary_risk.tsv`
- `quizbowl_lit_release_queue.tsv`
- `quizbowl_lit_release_gate_summary.json`
