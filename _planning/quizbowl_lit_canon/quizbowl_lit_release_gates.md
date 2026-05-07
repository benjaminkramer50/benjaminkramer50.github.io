# Quizbowl Literature Release Gates

Generated from `_data/quizbowl_literature_canon.yml`.

## Counts

- Public accepted rows: `4993`
- Chronology-ready rows: `2837`
- Creator-ready rows: `3094`
- Default reading-path rows: `2812`
- Creator-risk rows: `460`
- Duplicate-risk rows: `113`
- Boundary-risk rows: `97`
- Mandatory release-queue rows: `429`

## Stop Rule

Do not manually clear the full unplaced backlog for v1. Resolve the mandatory release queue, fix the default-path UI, and leave the low-salience long tail in the Unplaced view.

## Top Release Queue

| Rank | Count | Tier | Title | Gate Reasons | Issue Buckets | Action |
| ---: | ---: | --- | --- | --- | --- | --- |
| 1021 | 172 | `qb_core` | Beauty and the Beast | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1139 | 58 | `qb_major` | Confessions | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1145 | 114 | `qb_major` | The Gospel According to Jesus Christ | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1215 | 54 | `qb_major` | Jerusalem | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1262 | 62 | `qb_major` | Elegy for Alto | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1270 | 69 | `qb_major` | The East Wing | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; boundary_risk | chronology; boundary | Set boundary disposition or route to sibling list before default release. |
| 1284 | 47 | `qb_major` | Die Blechtrommel | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1354 | 56 | `qb_major` | Book of Jonah | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; boundary_risk | chronology; boundary | Set boundary disposition or route to sibling list before default release. |
| 1365 | 39 | `qb_major` | The Wasteland | qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1390 | 36 | `qb_major` | Poetics | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1392 | 41 | `qb_major` | Book of Psalms | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1404 | 73 | `qb_major` | White Buildings | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1443 | 57 | `qb_major` | Gösta Berling’s Saga | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk; boundary_risk | chronology; creator; boundary | Set boundary disposition or route to sibling list before default release. |
| 1453 | 55 | `qb_major` | Calling Out to Yeti | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1455 | 55 | `qb_major` | Book of Ruth | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; boundary_risk | chronology; boundary | Set boundary disposition or route to sibling list before default release. |
| 1473 | 66 | `qb_major` | The Deptford Trilogy | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk; boundary_risk | chronology; creator; boundary | Set boundary disposition or route to sibling list before default release. |
| 1477 | 69 | `qb_major` | Quincas Borba | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1546 | 31 | `qb_major` | Mahabharata | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1551 | 44 | `qb_major` | Book of Proverbs | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1554 | 57 | `qb_major` | Apology for Raymond Sebond | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1558 | 33 | `qb_major` | Book of Joshua | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1560 | 43 | `qb_major` | An Epistle to Dr. Arbuthnot | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; boundary_risk | chronology; boundary | Set boundary disposition or route to sibling list before default release. |
| 1561 | 56 | `qb_major` | Kristin Lavransdatter | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1563 | 45 | `qb_major` | The Poisonwood Bible | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1580 | 71 | `qb_major` | Of Time and the River | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1584 | 55 | `qb_major` | Girl | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1586 | 33 | `qb_major` | The Knights | qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |
| 1594 | 113 | `qb_major` | Call to Arms | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 1596 | 47 | `qb_major` | The Broken Tower | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology; creator_risk | chronology; creator | Replace/suppress creator before default release. |
| 1598 | 42 | `qb_major` | Anna in the Tropics | count_ge_40_unresolved_chronology; qb_major_unresolved_chronology | chronology | Add conservative date metadata or keep outside default path. |

## Output Files

- `quizbowl_lit_creator_risk.tsv`
- `quizbowl_lit_duplicate_risk.tsv`
- `quizbowl_lit_boundary_risk.tsv`
- `quizbowl_lit_release_queue.tsv`
- `quizbowl_lit_release_gate_summary.json`
