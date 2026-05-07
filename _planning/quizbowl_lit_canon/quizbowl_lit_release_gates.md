# Quizbowl Literature Release Gates

Generated from `_data/quizbowl_literature_canon.yml`.

## Counts

- Public accepted rows: `4993`
- Chronology-ready rows: `2837`
- Creator-ready rows: `3094`
- Default reading-path rows: `2812`
- Creator-risk rows: `460`
- Duplicate-risk rows: `113`
- Boundary-risk rows: `147`
- Mandatory release-queue rows: `479`

## Stop Rule

Do not manually clear the full unplaced backlog for v1. Resolve the mandatory release queue, fix the default-path UI, and leave the low-salience long tail in the Unplaced view.

## Top Release Queue

| Rank | Count | Tier | Title | Gate Reasons | Issue Buckets | Action |
| ---: | ---: | --- | --- | --- | --- | --- |
| 2 | 2248 | `qb_core` | The Odyssey | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 22 | 1628 | `qb_core` | The Iliad | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 98 | 339 | `qb_core` | No Exit | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 109 | 573 | `qb_core` | Ramayana | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 127 | 600 | `qb_core` | Peer Gynt | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 272 | 663 | `qb_core` | Bhagavad Gita | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 291 | 250 | `qb_core` | Book of Daniel | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 349 | 357 | `qb_core` | The Threepenny Opera | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 351 | 231 | `qb_core` | The Myth of Sisyphus | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 369 | 266 | `qb_core` | Epic of Gilgamesh | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 429 | 213 | `qb_core` | The Kreutzer Sonata | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 441 | 344 | `qb_core` | Happy Days | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 458 | 177 | `qb_core` | Book of Esther | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 462 | 192 | `qb_core` | The Song of Roland | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 490 | 220 | `qb_core` | Marriage a la Mode | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 497 | 174 | `qb_core` | The Phantom of the Opera | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 510 | 356 | `qb_core` | Book of Genesis | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 516 | 207 | `qb_core` | Works and Days | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 579 | 146 | `qb_core` | The Beggar's Opera | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 592 | 150 | `qb_core` | Book of Job | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 617 | 143 | `qb_core` | Book of Judges | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 691 | 262 | `qb_core` | The Pastoral Symphony | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 703 | 180 | `qb_core` | Gospel of Luke | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 761 | 118 | `qb_core` | Requiem | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 781 | 61 | `qb_major` | Kalevala | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 789 | 174 | `qb_core` | The Ghost Sonata | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 931 | 104 | `qb_core` | Popol Vuh | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 936 | 90 | `qb_core` | Book of Isaiah | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 956 | 157 | `qb_core` | Self-Portrait in a Convex Mirror | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 993 | 90 | `qb_core` | Zend-Avesta | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |

## Output Files

- `quizbowl_lit_creator_risk.tsv`
- `quizbowl_lit_duplicate_risk.tsv`
- `quizbowl_lit_boundary_risk.tsv`
- `quizbowl_lit_release_queue.tsv`
- `quizbowl_lit_release_gate_summary.json`
