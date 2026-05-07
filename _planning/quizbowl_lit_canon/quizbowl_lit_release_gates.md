# Quizbowl Literature Release Gates

Generated from `_data/quizbowl_literature_canon.yml`.

## Counts

- Public accepted rows: `4981`
- Chronology-ready rows: `3084`
- Creator-ready rows: `3273`
- Default reading-path rows: `3059`
- Creator-risk rows: `353`
- Duplicate-risk rows: `111`
- Boundary-risk rows: `0`
- Mandatory release-queue rows: `128`

## Stop Rule

Do not manually clear the full unplaced backlog for v1. Resolve the mandatory release queue, fix the default-path UI, and leave the low-salience long tail in the Unplaced view.

## Top Release Queue

| Rank | Count | Tier | Title | Gate Reasons | Issue Buckets | Action |
| ---: | ---: | --- | --- | --- | --- | --- |
| 1139 | 58 | `qb_major` | Confessions | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1215 | 54 | `qb_major` | Jerusalem | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1731 | 37 | `qb_major` | Grace | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1990 | 65 | `qb_major` | The Fall of Rome | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2033 | 62 | `qb_major` | The Four Ages of Man | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2044 | 66 | `qb_major` | The Golden One | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2076 | 62 | `qb_major` | Church Without Christ | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2095 | 62 | `qb_major` | The Fig Tree | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2127 | 67 | `qb_major` | Stars of Destiny | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2145 | 60 | `qb_major` | Ali Baba and the Forty Thieves | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2175 | 29 | `qb_major` | The Storyteller | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2176 | 61 | `qb_major` | The Saddest Story | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2208 | 52 | `qb_major` | Refusal to Mourn the Death | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2219 | 55 | `qb_major` | The House on Eccles Street | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2231 | 57 | `qb_major` | Life on Mars | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2248 | 55 | `qb_major` | A World Without Collisions | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2259 | 50 | `qb_major` | Who is Sylvia | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2265 | 20 | `qb_major` | The Lady of Shallott | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2272 | 52 | `qb_major` | Spirit of Evil | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2277 | 51 | `qb_major` | Killing an Arab | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2288 | 29 | `qb_major` | Se una notte d'inverno un viaggiatore | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2294 | 23 | `qb_major` | John | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2296 | 26 | `qb_major` | reasonable equivalents | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2299 | 49 | `qb_major` | Two Minutes Hate | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2319 | 48 | `qb_major` | Who is John Galt | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2330 | 31 | `qb_major` | The Spanish Gypsy | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 2333 | 46 | `qb_major` | The Day of the Jackal | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2334 | 21 | `qb_major` | Clay | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2335 | 31 | `qb_major` | The Idiot Boy | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 2337 | 22 | `qb_major` | Crimes of the Heart | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |

## Output Files

- `quizbowl_lit_creator_risk.tsv`
- `quizbowl_lit_duplicate_risk.tsv`
- `quizbowl_lit_boundary_risk.tsv`
- `quizbowl_lit_release_queue.tsv`
- `quizbowl_lit_release_gate_summary.json`
