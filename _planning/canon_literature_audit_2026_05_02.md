---
title: Literature Canon Full Audit
date: 2026-05-02
status: provisional_path_complete_source_review_pending
scope: literature_only_global_lifetime_path
---

# Literature Canon Full Audit

Verdict: the site now has a usable 3,000-item literature checklist, but it is not a locked academic canon yet. The structure is real and the list is followable, but the scholarly status is provisional until source review, Bloom cleanup, chronology repair, and alias-aware dedupe are completed.

## 2026-05-03 Source-Backed Pivot

After workflow review, direct replacement waves are paused. The current path is mechanically valid but not replacement-ready as a locked canon because source debt and inferred taxonomy dominate the dataset. The next phase is to build the `_planning/canon_build/` source universe, candidate universe, evidence ledger, scoring layer, and policy gates. Future content changes should come from source-backed replacement transactions, not packet-by-packet taste corrections.

## Current Verified State

- Public checklist target: 3,000 texts.
- Current public checklist: 3,000 texts.
- Remaining target slots: 0.
- Public scope check: 0 non-text items; all current public items are `textual_humanities`, medium `text`, and engagement target `read`.
- Structural check: 0 duplicate ranks, 0 duplicate IDs, 0 missing titles, 0 missing sort years, 0 future placeholder sort years.
- Source status: 62 entries are accepted or source-backed; 2,938 entries are still `manual_only`.
- Review status: 2,939 entries still have `review_status: needs_sources`.
- Chronology caveat: 257 entries still have approximate or pending date labels, mostly from late Bloom staging.
- Contemporary caveat: 42 entries have `sort_year >= 2020`; these should remain probationary until source-backed reception review.
- Completion-unit bug fixed: story/tale items no longer inherit the epic/saga completion instruction.
- Website trust fix: the public tracker now shows reviewed vs needs-source-review status and exposes a source-status filter.

## Audit Process

The audit used five independent review scopes plus local checks:

- Structural/data integrity: schema, IDs, ranks, dates, duplicates, enum drift, completion-unit logic.
- Global coverage: regional/topic balance, period balance, undercovered traditions, oral/Indigenous handling.
- Bloom integration: seed coverage, full-audit coverage, staged-vs-present Bloom decisions, late-wave quality.
- Boundary decisions: genre, children/YA, graphic narrative, scripture/myth, philosophy/religion leakage, contemporary instability.
- Website UX: text-only checklist usability, progress tracking, source-status visibility, 3,000-item rendering weight.

## Corrections Applied

- Added a mandatory-omissions repair pass after user-facing audit caught absent core works:
  - `The Taming of the Shrew`
  - `Richard III`
  - `Richard II`
  - `Romeo and Juliet`
  - `Much Ado About Nothing`
  - `Henry V`
  - `Julius Caesar`
  - `The Winter's Tale`
  - `Animal Farm`
- Kept the lifetime path at 3,000 by replacing lower-confidence contextual entries, mostly minor early-modern/Bloom-gap placeholders plus one contextual 1940s candidate.
- Added a broader mandatory-title audit pass with alias-aware repairs:
  - Added `Lyrical Ballads`, `The Prophet`, `For Whom the Bell Tolls`, `The Crucible`, `Cat on a Hot Tin Roof`, `On the Road`, and `The Bell Jar`.
  - Made `The Rape of the Lock` explicit by retitling Pope's entry as `The Rape of the Lock and Selected Poems`.
  - Added searchable aliases for collection/variant cases including `Diary of a Madman`, `Rashomon`, `Godan`, `The Aleph`, `Duino Elegies`, `Howl`, `Shakuntala`, and `The Lais of Marie de France`.
  - Updated public/admin search to include aliases so collection-level inclusions are discoverable.
- Added a third broader omissions repair pass:
  - Added `The Trojan Women`, `The Second Shepherds' Play`, `Edward II`, `Jacques the Fatalist`, `Ivanhoe`, `The Last of the Mohicans`, `Walden`, `Uncle Tom's Cabin`, `Incidents in the Life of a Slave Girl`, `The Jungle`, `The Good Earth`, `Of Mice and Men`, `The Old Man and the Sea`, `Notes of a Native Son`, `The Fire Next Time`, and `The French Lieutenant's Woman`.
  - Added aliases for title-form false negatives including `The Women of Trachis`, `The Satyricon`, `The School for Scandal`, `Bartleby, the Scrivener`, and `Benito Cereno`.
- Added a fourth mandatory-omissions repair pass from period-specialist audits:
  - Added premodern spine omissions including `The Eloquent Peasant`, `Homeric Hymns`, `Symposium`, `Mencius`, `Zuo Zhuan`, `Classic of Mountains and Seas`, `Theragatha`, `Natyashastra`, `Psychomachia`, `Dionysiaca`, `The Consolation of Philosophy`, `Bodhicaryavatara`, `Kitab al-Aghani`, `Digenes Akritas`, `Roman de Renart`, `Perceval, the Story of the Grail`, `Tristan`, `Carmina Burana`, `The Travels of Marco Polo`, and `Investiture of the Gods`.
  - Added nineteenth-century global omissions including `Hikayat Abdullah`, `Clotel`, `Wounds of Armenia`, `Our Nig`, `The Storm`, `Les Chants de Maldoror`, `Intibah`, `The Story of an African Farm`, `Against Nature`, and `Iola Leroy`.
  - Replaced lower-confidence late Bloom placeholders while keeping the path capped at 3,000 items.
  - Added 53 alias/search repairs for canonical title variants, collection contents, punctuation variants, and common translated titles.
- Added a fifth omissions repair pass from early-modern, modern, and global/non-Western audits:
  - Added early-modern and eighteenth-century omissions including `The Praise of Folly`, `Laments`, `Nueva coronica y buen gobierno`, `Stories Old and New`, `The Labyrinth of the World and the Paradise of the Heart`, `The Tenth Muse`, `Lucifer`, `Bihari Satsai`, `Life of Archpriest Avvakum`, `Absalom and Achitophel`, `Poems on Various Subjects, Religious and Moral`, `The Marriage of Figaro`, `Poems, Chiefly in the Scottish Dialect`, and `The Interesting Narrative`.
  - Added modern and global omissions including `Catch-22`, `Slaughterhouse-Five`, `A Clockwork Orange`, `Naked Lunch`, `Life: A User's Manual`, `The Gulag Archipelago`, `Kolyma Tales`, `The Dilemma of a Ghost`, `Kinjeketile`, `Anowa`, `Betrayal in the City`, `A River Called Titash`, `The Orphan of Asia`, `The Butcher's Wife`, `Dreaming in Cuban`, and `Jamilia`.
  - Collapsed clear duplicate title rows such as `La Mandragola` / `The Mandrake`, `Jin Ping Mei` / `The Plum in the Golden Vase`, `Chushingura` / `Kanadehon Chushingura`, `Tristram Shandy` full/short titles, `The Nine Cloud Dream` variants, `Kokinshu` variants, `Risalat al-Ghufran` variants, Fuzuli `Layla and Majnun` variants, and `Utendi wa Tambuka` variants.
- Added a sixth rank-range dedupe and omissions repair pass:
  - Added stronger omissions including `Kojiki`, `The Dream of the Rood`, `Old English Elegies: Selected Poems`, `Hitopadesha`, `The Tale of Igor's Campaign`, `Samguk Yusa`, `A Journal of the Plague Year`, `Sense and Sensibility`, `The Three Musketeers`, `The Count of Monte Cristo`, `Aurora Leigh`, `Goblin Market and Other Poems`, `Rajmohan's Wife`, `Andher Nagari`, `The Island of Doctor Moreau`, `The Invisible Man`, `Ethiopia Unbound`, `Pather Panchali`, `Heart of a Dog`, `Lady Chatterley's Lover`, `The Berlin Stories`, `Wise Blood`, `Homo Faber`, `Songs of Mihyar the Damascene`, `Tughlaq`, `Rosencrantz and Guildenstern Are Dead`, `Ragtime`, `Correction`, `Cassandra`, `Like Water for Chocolate`, `Arcadia`, `The Corrections`, `Life of Pi`, `Cloud Atlas`, `Wolf Hall`, `The Sellout`, `Milkman`, and `The Overstory`.
  - Collapsed another 51 duplicate, aggregate-overlap, or contained-volume rows, including duplicate `Baal Cycle`, Lucretius, `Sundiata`, Tamil bhakti, Arabic maqamat, `Romance of the Western Chamber`, `Divan of Hafez`, `Manas`, `Mem and Zin`, `Liaozhai`, `Os Maias`, `Adolphe`, Balzac/Flaubert/Rimbaud title variants, `Chunhyangjeon`, `Takekurabe`, `Sitti Nurbaya`, Pessoa/Gide/Jarry duplicates, series-plus-volume rows, and Giraudoux/Pessoa overlap.
  - Added 92 more alias repairs and four metadata fixes for merged title variants, original titles, translated-title searches, series volume searches, and malformed work titles.
- Added a seventh second-tier omissions cleanup pass:
  - Added early-modern and global premodern omissions including `The Book of the Courtier`, `The Tale of Tales`, `The Enchantments of Love`, `The Mayor of Zalamea`, `Erasmus Montanus`, `The Cherubinic Wanderer`, `A Modest Proposal`, `Narrative of the Captivity and Restoration`, `A True History of the Conquest of New Spain`, `Alaol's Padmavati`, `Adhyatma Ramayanam Kilippattu`, `Molla Ramayana`, `Selected Poems` by Vemana, `Selected Ghazals` by Saib Tabrizi, `Lament of a Royal Concubine`, `Sang Sinxay`, `The Battles of Coxinga`, `Sassi namjeonggi`, and `Jehol Diary`.
  - Added later omissions including `Wieland`, `Roxana`, `Life of Samuel Johnson`, `Rosmersholm`, `The Mayor of Casterbridge`, `Strait Is the Gate`, `Les Enfants Terribles`, `Mensagem`, `Thunderstorm`, and `Finn Family Moomintroll`.
  - Replaced 30 weaker contextual or probationary late entries and added 19 more alias repairs.
- Removed high-confidence non-literary/prose spillover from the public literature path:
  - `Del Romanzo Storico`
  - `Genie du Christianisme`
  - `De l'Amour`
  - `A Defence of Poetry`
  - Ruskin/Newman/Pater prose-theory items
  - generic `Selected prose`, `Prose`, and `Translations` placeholders
- Removed performance-bound Gilbert/Sullivan operetta spillover from the literature-only path.
- Repaired future placeholder dates: no current public item now has `sort_year > 2026`.
- Added audit replacement waves:
  - `wave_043_literature_audit_replacements`
  - `wave_044_literature_audit_backfill`
  - `wave_045_literature_dedupe_replacements`
  - `wave_046_literature_boundary_replacements`
- Improved alias-aware dedupe for known variants:
  - `Frankenstein`
  - `Hard Times`
  - `Oliver Twist`
  - `Waverley`
  - `Erewhon`
  - `Huarochiri Manuscript`
  - `Heimskringla`
  - `Sundiata`
  - `Risalat al-Ghufran / The Epistle of Forgiveness`
  - `Kutadgu Bilig / Wisdom of Royal Glory`
  - `Os Sertoes / Rebellion in the Backlands`
  - `Life and Times of Michael K`
  - `The Changeling`
  - `The Broken Commandment`
  - `The River Ki`
  - `The Sailor Who Fell from Grace with the Sea`
- Updated `scripts/report_bloom_coverage.rb` so it reports both stale imported Bloom matches and recomputed current-path Bloom matches.

## Bloom Status

- Curated Bloom seed layer: 200/200 matched in the current path; 0 missing keep/representative-selection seed entries.
- Full imported Bloom audit: 2,107 entries.
- Full imported Bloom status: 132 reviewed seed-level entries and 1,975 unreviewed raw entries.
- Current path match count from stale imported flag: 274.
- Current path match count recomputed against the current checklist: 712.
- Bloom review batches: 576 decisions.
- Staged Bloom promotions declared: 554.
- Staged Bloom promotions still present in the current path by `source_id`: 510.
- Staged Bloom promotions absent/cut after audit cleanup: 44.

Interpretation: Bloom is represented as an important Western evidence layer, not as an authority to copy wholesale. The curated seed coverage is defensible. The late automated Bloom layer remains provisional because many dates are approximate and some records were mechanically generated from the appendix.

## Remaining Problems

1. Source review debt is the main blocker. A true academic canon needs source-backed inclusion evidence, not just manual candidate status.
2. Period balance remains too late. Current bins are:
   - `<-1000`: 31
   - `-1000..-1`: 111
   - `0..499`: 55
   - `500..999`: 77
   - `1000..1499`: 161
   - `1500..1699`: 159
   - `1700..1799`: 90
   - `1800..1899`: 451
   - `1900..1945`: 512
   - `1946..1989`: 765
   - `1990..2019`: 546
   - `2020+`: 42
3. Region/topic balance remains uneven because the current quick path has topics, not first-class `macro_region`, `original_language`, or `literary_tradition` metadata.
4. Southeast Asia, East Asia beyond the largest Chinese/Japanese/Korean cells, MENA minority languages, Central/Horn Africa, Arctic literatures, and premodern local-language traditions still need systematic source-reviewed strengthening.
5. Generic assignment titles remain common, especially `Selected Poems`. These are acceptable only if each gets a source-backed selection basis, edition, or anthology note.
6. Scripture, oral tradition, testimonio, philosophy-adjacent dialogues, and literary memoir need explicit `included_as_literature` / `boundary_note` metadata.
7. LocalStorage progress tracking is usable but not durable enough for a lifetime project unless exports are backed up regularly or progress is eventually written into site data.

## Definition Of Done For A Locked Canon

- Convert most `manual_only` items to source-backed review states.
- Add explicit `macro_region`, `original_language`, `literary_tradition`, `selection_basis`, and `boundary_note` fields.
- Replace approximate Bloom dates with verified work dates or documented period dates.
- Run alias-aware dedupe after every source-review batch.
- Cap very recent works with a probation rule unless a work has strong source-backed canonical reception.
- Keep the public page honest: reviewed/source-backed status must remain visible.
- Re-run validation, Bloom coverage, duplicate audit, chronology audit, and Jekyll build before calling the canon academically locked.
