# Quizbowl Literature Release Gates

Generated from `_data/quizbowl_literature_canon.yml`.

## Counts

- Public accepted rows: `4993`
- Chronology-ready rows: `2744`
- Creator-ready rows: `2999`
- Default reading-path rows: `2682`
- Creator-risk rows: `526`
- Duplicate-risk rows: `113`
- Boundary-risk rows: `147`
- Mandatory release-queue rows: `596`

## Stop Rule

Do not manually clear the full unplaced backlog for v1. Resolve the mandatory release queue, fix the default-path UI, and leave the low-salience long tail in the Unplaced view.

## Top Release Queue

| Rank | Count | Tier | Title | Gate Reasons | Issue Buckets | Action |
| ---: | ---: | --- | --- | --- | --- | --- |
| 2 | 2248 | `qb_core` | The Odyssey | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 22 | 1628 | `qb_core` | The Iliad | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 26 | 655 | `qb_core` | Les Miserables | creator_risk | creator | Replace/suppress creator before default release. |
| 39 | 514 | `qb_core` | The Tin Drum | creator_risk | creator | Replace/suppress creator before default release. |
| 60 | 420 | `qb_core` | Miss Julie | creator_risk | creator | Replace/suppress creator before default release. |
| 67 | 440 | `qb_core` | The Red Badge of Courage | creator_risk | creator | Replace/suppress creator before default release. |
| 98 | 339 | `qb_core` | No Exit | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 109 | 573 | `qb_core` | Ramayana | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 127 | 600 | `qb_core` | Peer Gynt | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 142 | 327 | `qb_core` | The Hunchback of Notre Dame | creator_risk | creator | Replace/suppress creator before default release. |
| 155 | 336 | `qb_core` | Rip Van Winkle | creator_risk | creator | Replace/suppress creator before default release. |
| 161 | 323 | `qb_core` | The Rape of the Lock | creator_risk | creator | Replace/suppress creator before default release. |
| 164 | 356 | `qb_core` | The Legend of Sleepy Hollow | creator_risk | creator | Replace/suppress creator before default release. |
| 197 | 239 | `qb_core` | The God of Small Things | creator_risk | creator | Replace/suppress creator before default release. |
| 272 | 663 | `qb_core` | Bhagavad Gita | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 277 | 284 | `qb_core` | Civil Disobedience | creator_risk | creator | Replace/suppress creator before default release. |
| 291 | 250 | `qb_core` | Book of Daniel | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 349 | 357 | `qb_core` | The Threepenny Opera | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 351 | 231 | `qb_core` | The Myth of Sisyphus | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 357 | 207 | `qb_core` | The Trojan Women | creator_risk | creator | Replace/suppress creator before default release. |
| 369 | 266 | `qb_core` | Epic of Gilgamesh | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 427 | 180 | `qb_core` | Mourning Becomes Electra | creator_risk | creator | Replace/suppress creator before default release. |
| 429 | 213 | `qb_core` | The Kreutzer Sonata | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 441 | 344 | `qb_core` | Happy Days | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 458 | 177 | `qb_core` | Book of Esther | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 462 | 192 | `qb_core` | The Song of Roland | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 470 | 236 | `qb_core` | The Red Room | creator_risk | creator | Replace/suppress creator before default release. |
| 490 | 220 | `qb_core` | Marriage a la Mode | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |
| 492 | 323 | `qb_core` | Cat and Mouse | creator_risk | creator | Replace/suppress creator before default release. |
| 497 | 174 | `qb_core` | The Phantom of the Opera | boundary_risk | boundary | Set boundary disposition or route to sibling list before default release. |

## Output Files

- `quizbowl_lit_creator_risk.tsv`
- `quizbowl_lit_duplicate_risk.tsv`
- `quizbowl_lit_boundary_risk.tsv`
- `quizbowl_lit_release_queue.tsv`
- `quizbowl_lit_release_gate_summary.json`
