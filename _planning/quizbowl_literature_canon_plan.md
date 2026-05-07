# Quizbowl-Derived Literature Canon Plan

Date: 2026-05-04

Status: audited_release_hardening

## Core Idea

Build a literature canon from the raw quizbowl corpus. Do not use Bloom, online lists, anthology tables of contents, syllabi, the existing canon, Loci literature-track labels, or Loci canon-refinement tables as inclusion evidence. The current canon is preserved as-is; this becomes a separate experimental canon and comparison layer.

## Final Product Goal

The main deliverable is a quizbowl-derived literature reading list, not just a raw canon dump. The public product should help someone decide what to read, in what broad order, and how strongly each work recurs in the academic quizbowl literature corpus.

The final literature product should include:

- A clean accepted reading list of literary works.
- A salience score and tier for each work.
- Concise evidence/source context showing why the work appears, without making the page feel like a quizbowl operations tool.
- Filters for tier, source channel, review status, form/genre, era, region/tradition, and eventually unit.
- Reading-list views that can be grouped into units such as ancient epic/scripture-as-literature, classical drama, medieval romance, early modern drama, global novel traditions, modernism, postcolonial literature, contemporary global literature, poetry, short fiction, literary criticism/theory, and oral traditions.
- Audit-only rejected/review queues so opera, social science, philosophy, geography artifacts, author names, characters, and ambiguous title fragments do not pollute the public reading list.

The correct endpoint is a browsable and deeply filterable quizbowl literature syllabus, backed by reproducible evidence.

The inclusion signal is simple in principle:

- A literary work becomes eligible when it appears in at least three distinct raw quizbowl questions.
- Evidence can come from raw answerlines when the raw question prompt asks for a literary work.
- Evidence can also come from repeated title mentions in `archive_parsed_questions.clue_text`.
- Answerlines are not a closed universe. Work titles discovered in clue text can independently enter the candidate pool.
- Mentions are counted by distinct question rows, distinct sets, years, and circuits so repeated packet artifacts do not inflate status.

Observed local corpus baseline:

- Database: `/Users/benjaminkramer/Desktop/Loci/user-data/quizbowl-coach.db`
- Main clue table: `archive_parsed_questions`
- Rows: 2,216,999
- Sets: 2,160
- Year span: 1969-2026
- Tossups: 774,599
- Bonus parts: 1,442,400

## Why This Is Plausible

Quizbowl is not a neutral world canon, but it is a real, measurable cultural-pedagogical canon. It repeatedly encodes what question writers expect educated players to know, and it does so through clues, not just final answerlines. That makes it useful for a different claim:

> This is a quizbowl-salience literature canon: works that recur as objects, references, clues, settings, titles, sources, and interpretive anchors across a large quizbowl corpus.

This is more objective than hand-ranking because every inclusion can be traced to raw quizbowl rows.

## Key Methodological Rule

Use raw quizbowl answerlines and clue text as evidence. The build reads `archive_parsed_questions.answerline` and `archive_parsed_questions.clue_text` for inclusion and scoring. It may read `archive_practice_questions.track_id` only as diagnostic quizbowl-category metadata for audit and rejection sanity checks; it explicitly does not read `archive_canon_refinement_runs` or `archive_canon_answerline_candidates`.

Answerlines count only when the raw prompt asks for a literary work. Clue-text title mentions count independently. Neither channel is allowed to define the whole canon by itself.

## Output Artifacts

Create a parallel build area:

- `_planning/quizbowl_lit_canon/quizbowl_lit_title_candidates.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_mentions.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_clusters.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_canon_scores.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_false_positive_review.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_rejected.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_audit_queue.tsv`
- `_planning/quizbowl_lit_canon/quizbowl_lit_llm_review_queue.jsonl`
- `_planning/quizbowl_lit_canon/quizbowl_lit_adjudications.yml`
- `_planning/quizbowl_lit_canon/quizbowl_lit_method_report.md`
- `_planning/quizbowl_lit_canon/quizbowl_lit_wikidata_candidates.tsv`
- `_data/quizbowl_literature_canon.yml`
- `_data/quizbowl_literature_metadata_overrides.yml`

Do not overwrite `_data/canon_quick_path.yml`.

The public YAML should contain only `accepted_likely_work` rows. Ambiguous `needs_review_*` candidates and rejected rows remain available in TSV/JSONL audit artifacts, but they should not drive the public reading-list UI.

## End-To-End Completion Plan

This project is done in stages. The corpus-derived canon will never be permanently final because new quizbowl packets can be added, but the first production-quality version has concrete stopping criteria.

### Phase Map

| Phase | Name | Status | Exit Gate | Primary Artifacts |
| --- | --- | --- | --- | --- |
| A | Evidence Pipeline | complete enough for iteration | Raw answerlines and clue text produce reproducible accepted/rejected/review outputs without Loci processed canon tables. | build script, method report, public YAML |
| B | Public-List Purity | active, `2934` adjudications loaded; 12-agent audit found the raw-evidence method valid but public-list leakage still needs gated cleanup | Top audit rows, high-salience non-literary leaks, and boundary cases are adjudicated or routed, with no unreviewed `qb_core`/`qb_major` adjacent-domain rows in the default path. | adjudications YAML, rejected TSV, review queue |
| C | Alias And Duplicate Consolidation | active, `526` manual alias rules loaded and `523` applied; `17` ambiguous source titles now have `33` author-aware split targets, with `24` public child rows after routing | High-salience duplicate families, translated titles, subtitles, whole/subwork boundaries, and protected collisions are resolved or explicitly held for review. | cluster TSV, adjudications YAML, split-audit TSV |
| D | Classification And Metadata Layer | active but re-scoped; all public rows have provisional classification fields, but open-ended manual dating is paused until creator and duplicate gates are hardened | Default chronology path uses only rows with audited creator/date. High-salience unresolved rows are resolved by finite gates; low-salience rows remain explicitly `unknown`/`Unplaced`. | enriched public YAML, metadata overlay, Wikidata audit TSV, metadata backlog report |
| E | UI And Reading Experience | active, but default view must shift from all accepted rows to a chronology-ready reading path | The public page looks like a serious chronological literature reading list, with All Accepted and Unplaced as secondary views. | site pages/components/styles |
| F | Literature Release Gate | not started | A stable quizbowl literature canon has passed A-E plus the 12-agent audit gates below. | public site, method report |
| G | Adjacent Quizbowl Reading Lists | planned after F | Religion, mythology, philosophy, and social-science sibling products have their own pipelines and public pages. | separate domain YAMLs and pages |

Current operating phase: Phase D/E release hardening. The top-audit-row count has crossed `2,000` adjudicated rows, the first-`1,000` public-row purity pass removed obvious fragments and non-work rows, and the builder supports manual alias merges plus author-aware split routing so duplicate variants and ambiguous same-title evidence do not collapse into one public row. The public classification/UI layer is intentionally conservative: it uses evidence-derived form, evidence profile, quizbowl context, routing status, and provisional rule-derived era, region/tradition, reading-unit, and confidence fields. The build also supports a reproducible metadata overlay from Wikidata for creator/date enrichment. Unknown metadata is left explicit rather than forced into false precision.

Current metadata checkpoint:

- Threshold: `total_question_count >= 3`.
- Public rows: `4997` (`1030` core, `1455` major, `2512` contextual).
- Creator coverage: `3526 / 4997`.
- Chronology coverage: `2744 / 4997` public rows have non-`Unplaced` chronology (`46` reviewed canon records, `19` title overrides, `2196` Wikidata overlay rows, `483` manual metadata corrections).
- Default-path candidate coverage: `2717 / 4997` rows currently have both creator and chronology.
- Remaining chronology backlog: `2253` public rows marked `Unplaced`.
- High-salience unresolved gates: `6` rows at rank `<=1000`, `304` rows with `total_question_count >= 40`, and `457` `qb_major` rows still need resolution by date, merge, rejection, routing, or explicit boundary disposition.
- Known constraint: Wikidata is metadata support, not inclusion evidence; quizbowl raw answerlines/clues remain the only inclusion signal.
- Known creator-risk constraint: `527` public rows still use `quizbowl_author_answerline` creator inference. These are not release-quality creators unless separately audited or replaced by manual/Wikidata/reviewed metadata.
- Current Wikidata pass: the giant metadata sweep attempted `2310` remaining eligible unplaced rows and initially accepted `815` overlays; four read-only audit chunks then removed or corrected false matches, adjacent-domain spillover, version/edition-level items, creator/date errors, and duplicate/original-language title variants before the full corpus rebuild. A D2 retry over the top `600` still-unplaced rows accepted only `25` additional Wikidata overlays, confirming that the remaining backlog is dominated by title collisions, poems without clean Wikidata dates, composite/oral works, noisy creator answerlines, and parser fragments rather than simple search misses.
- Current D2-D6 backlog artifact: `_planning/quizbowl_lit_canon/quizbowl_lit_metadata_backlog.tsv` ranks all remaining `2253` unplaced public rows by quizbowl salience and buckets them as date-only, creator/date, non-literature context, parser fragment, oral/composite, or creator-audit cases. The cleanup batches lowered the highest unresolved public row from `306` mentions to `69` by dating high-confidence works, merging title variants, and routing ambiguous rows such as `The Book of the Dead`, `The Promised Land`, `Annus Mirabilis`, `The Dark Tower`, `The Rose Garden`, `Oath of the Peach Garden`, `Palm-of-the-Hand`, `Elinor and Marianne`, `Black and Blue`, `Down at the Cross`, `Maggie`, `Battle Royale`, and the `R.U.R.` title family into canonical rows or review.
- Current cleanup note: shorthand duplicate rows `Tom Sawyer`, `Huckleberry Finn`, and `Huck Finn` now merge into the full Mark Twain titles; Shakuntala transliteration/title variants now merge into `The Recognition of Shakuntala`; article/truncation/original-language variants such as `Life & Times`, `Stopping by Woods`, `of Otranto`, `Astrophel and Stella`, `Der Zauberberg`, `is Just to Say`, `Tonight I Can Write`, `Les Fleurs du`, `Oresteia Trilogy`, `La casa de los espíritus`, `Huis Clos`, `20,000 Leagues Under the Sea`, `Outlaws of the Marsh`, `The Art of Poetry`, `La Vita Nuova`, `The Sketch Book`, `Os Lusiadas`, `En attendant Godot`, `The Modern Prometheus`, `La Peste`, `Der Tod in Venedig`, `I Promessi Sposi`, `Die Räuber`, `Der Sandmann`, `Bodas de sangre`, `Le Petit Prince`, `Voyna i mir`, `L'Etranger`, `La Parure`, `Fin de partie`, `Prestupleniye i nakazaniye`, `Fröken Julie`, `La Chute`, `Les Trois Mousquetaires`, `Il nome della rosa`, `Im Westen nichts Neues`, `Dyadya Vanya`, `The Scottish Play`, `The Lotus-Eaters`, `Song Book`, `L’école des femmes`, `Slaughter-House Five`, `El beso de la mujer araña`, `Como agua para chocolate`, `The Golden Lotus`, `Jekyll and Hyde`, `Daffodils`, `Das Glasperlenspiel`, `Chayka`, `La Nausée`, `The Picture of Dorian Grey`, `Master i Margarita`, and `One Flew Over the Cuckoo` now merge into canonical rows; non-work fragments, author/person rows, characters, reference works, embedded fictional works, movements/categories, films, mythology domains, social-science works, history-domain works, and philosophy rows such as `I do`, `Grover's Corners`, `Blanche DuBois`, `The Horror! The Horror`, `30 points`, `Christopher Marlowe`, `John Milton`, `Edith Wharton`, `Harper LEE`, `O. Henry`, `The Murder of Gonzago`, `Dictionary of the English Language`, `The Tragic Sense of Life`, `the Artful Dodger`, `Janie Crawford`, `Harry Haller`, `Katherine Mansfield`, `Finnish mythology`, `Theater of the Absurd`, `Spanish Golden Age`, `Four Great Classical Novels`, `Equal Rights Amendment`, `Zeno of Elea`, `Bringing Up Baby`, `Throne of Blood`, `Shakespeare in Love`, `The Lonely Crowd`, `Little Father Time`, `Inuit Mythology`, `Person from Porlock`, `Valley of Ashes`, `Self-Taught Man`, `Cide Hamete Benengeli`, `The Mad Trist`, `The Royal Nonesuch`, `Shiva of the Knees`, `Washington Irving's`, `Bonus Questions`, and `The Outline of History` are rejected or routed out; author-aware split routing now separates supported child rows for `North and South`, `Bread and Wine`, `The Lost World`, `The Royal Family`, `Diary of a Madman`, `The Island`, `The Mother`, `Book of Songs`, `Bus Stop`, `Hyperion`, `The Kindly Ones`, and `Phaedra`, while unmatched mixed evidence remains held for review.
- Current split-audit artifact: `_planning/quizbowl_lit_canon/quizbowl_lit_split_audit.tsv` reports source/target status, routed counts, creators, dates, and match terms for every author-aware split target. The 12-agent audit also fixed an overbroad `Snow White` split term: the Donald Barthelme child now falls below public threshold, while the fairy-tale child remains public.

### 12-Agent Audit Checkpoint

The May 2026 audit used two waves of six agents to review what was done, what is being done now, and the remaining plan. The consensus is:

- The core evidence method is objective enough for this product: inclusion still comes only from raw answerlines and clue text, not Loci processed canon tables or external canon lists.
- Continuing hundreds of open-ended manual metadata packets is not optimal. It spends too much time on the long tail before fixing release blockers.
- The main blockers are public-release quality gates: bad creator inference from quizbowl answerlines, duplicate/translated/subtitle title families, boundary handling for scripture/myth/philosophy/social science, and a UI default that should not expose all accepted rows as one massive path.
- The correct pivot is finite hardening: fix high-salience unresolved rows, add creator/duplicate/boundary gates, make chronology-ready rows the default public path, and leave low-salience unresolved rows in an explicit Unplaced view.

### Phase Transition Rules

- Do not continue open-ended manual metadata passes until the D6 regression checks, creator-publication gate, and duplicate-family diagnostic are in place.
- Do not use `quizbowl_author_answerline` creators in the default reading path unless the row is separately audited or backed by manual/Wikidata/reviewed metadata.
- Do not make All Accepted the default public experience. The default view is the Chronological Path: accepted rows with reliable creator and chronology metadata.
- Do not fold religion, mythology, philosophy, or social-science works back into the literature list; Phase G creates sibling products after the literature list is stable.
- If a later phase exposes a major upstream problem, return to the earlier phase, fix it, rebuild, and update the method report.

### Phase A: Evidence Pipeline

Status: complete enough for iteration.

Done when:

- Raw answerline and raw clue-text extraction both run from `archive_parsed_questions`.
- The build does not depend on Loci processed canon tables or external canon lists.
- The build can complete reproducibly with `--jobs 4`.
- Public YAML exports only accepted works.
- Rejected/review rows are retained in audit artifacts.

### Phase B: Public-List Purity

Status: active.

Goal: make the visible literature list clean enough that obvious false positives are rare.

Done when:

- The top `2,000` audit queue rows have been adjudicated or routed into durable keep/reject/review rules.
- The first `1,000` public rows have no obvious non-literary entities, people, characters, places, music-only works, science terms, sports terms, newspapers, institutions, or parser fragments.
- No `qb_core` or `qb_major` row with adjacent-domain signals remains in the default path without an explicit boundary disposition.
- The next pending `quizbowl_lit_llm_review_queue.jsonl` batch is no longer dominated by easy rejects or obvious rescues; remaining cases are genuinely ambiguous.
- Spot checks for known traps pass: opera/musical works, social science/philosophy titles, Bible/religion works, art/music titles, character names, author names, title fragments, and duplicate title variants.

### Phase C: Alias And Duplicate Consolidation

Status: partially active.

Goal: avoid having the same work appear under multiple surface forms.

Done when:

- High-salience duplicates are merged or one variant is rejected as a duplicate/title variant.
- Common article variants are handled: `Divine Comedy` / `The Divine Comedy`, `Arabian Nights` / `The Arabian Nights`, `War of the Worlds` / `The War of the Worlds`, etc.
- Transliteration and translated-title variants are captured when the quizbowl evidence clearly identifies the same work.
- Whole-work versus subwork boundaries are explicit: collection, individual poem/story, embedded fictional work, chapter/section, and motif are not silently collapsed.
- A duplicate diagnostic flags accepted blank-creator answerline-only rows with `or`, translated-title, colon-subtitle, or slash separators when one component already exists as an accepted title.

### Phase D: Classification And Metadata Layer

Status: active.

Goal: make the list usable as a reading syllabus rather than a flat ranking, with enough creator/date metadata to support chronological browsing without pretending low-confidence rows are known.

Done when every public row has at least provisional:

- `form`: novel, play, poem, epic, short story, collection, scripture-as-literature, oral/traditional text, memoir/autobiography, essay, literary criticism/theory, mixed/other.
- `unit`: broad reading-list grouping.
- `era`: ancient, classical, late antique, medieval, early modern, long 19th century, modernist, postwar, contemporary, or more specific where useful.
- `region_or_tradition`: Greek, Roman, Sanskrit, Hebrew, Arabic/Persian, Chinese, Japanese, Russian, Latin American, African, Caribbean, Indigenous, etc.
- `confidence`: rule-derived, manually checked, or needs review.

Current implementation:

- `work_form`, `evidence_profile`, `quizbowl_track_profile`, and `routing_status` are generated for every public row.
- `era`, `region_or_tradition`, `reading_unit`, and `classification_confidence` are generated for every public row.
- The front of the list has high-salience title overrides to avoid clue-allusion artifacts; broader rows remain `unknown_era` or `unknown_region` when evidence is too weak.
- A Wikidata metadata overlay enriches high-salience rows with exact-title creator/date matches gated by literary-work descriptions and creator consistency checks.
- Manual metadata corrections can override incomplete overlay rows or fill missing dates/creators when the correction is traceable to a specific work.
- The Wikidata enrichment merge now preserves manual corrections instead of dropping them during overlay deduplication and skips previously reported no-match rows unless explicitly retried.
- `Death and the King's Horseman` is explicitly overridden to 1975 because Wikidata supplied an erroneous 1993 date.
- High-salience manual metadata corrections now cover rows including `The Second Coming`, `The Importance of Being Earnest`, `The Love Song of J. Alfred Prufrock`, `One Thousand and One Nights`, `Journey to the West`, `Romance of the Three Kingdoms`, `The Decameron`, `Book of Genesis`, `Book of Job`, `Tonight I Can Write the Saddest Lines`, `Poetry`, `Barn Burning`, `The Interlopers`, `A Tale of a Tub`, `Suddenly Last Summer`, `The Bear`, `Hands`, `The Temple`, `The British Prison Ship`, `The Panther`, `The Laughing Man`, `The South`, `Nature`, `Patterns`, `The Wild Honey-Suckle`, `The Lusiads`, `The Persians`, `The Toilers of the Sea`, `Eumenides`, `To Lucasta, Going to the Warres`, `Agamemnon`, `Nightfall`, `The Family of Pascual Duarte`, `Phaedra (Racine)`, `Phaedra (Seneca)`, `If This Is a Man`, `Demons`, `Billy Budd`, `Looking Backward`, `The Lotos-Eaters`, `Canzoniere`, `The School for Wives`, `The Revolution Will Not Be Televised`, `Peeling the Onion`, `The Erl-King`, `Tristan and Iseult`, `The Company of Wolves`, `Sonnet 18`, `The Great Stone Face`, `The Plum in the Golden Vase`, `The Strange Case of Dr. Jekyll and Mr. Hyde`, `On the Pulse of Morning`, `One Flew Over the Cuckoo’s Nest`, `A Good Man is Hard to Find`, `Chicago`, `A True Story`, `The Celebrated Jumping Frog of Calaveras County`, `Kaddish`, and `Babi Yar`.
- D3-D5 manual metadata corrections and merges now cover additional high-salience rows including `Two Words`, `Let Us Now Praise Famous Men`, `The Convergence of the Twain`, `Sympathy`, `God's Trombones`, `Our American Cousin`, `Three Tall Women`, `End of the Game`, `The Book of the City of Ladies`, `El Senor Presidente`, `The Author to Her Book`, `Chac Mool`, `Tortilla Flat`, `Book of Lamentations`, `His Excellency General Washington`, `Buried Child`, `Paterson`, `The Bridge`, `I Am a Cat`, `The House of Fame`, `Carmina Burana`, `Birds of America`, `The Flea`, and `The Odyssey: A Modern Sequel`.

Next Phase D work:

- Resolve the finite release gates before touching the long tail: all rank `<=1000` unresolved rows, all rows with `total_question_count >= 40`, all unresolved `qb_major` rows, and any count `20-39` row in a risk bucket.
- Add a creator-publication gate: default UI suppresses or labels `quizbowl_author_answerline` creators unless audited, and backlog reporting separately queues hard-failure creator strings such as places, countries, other titles, or answerline fragments.
- Add duplicate-family diagnostics for translated titles, subtitles, `or` answerlines, slash variants, and protected collisions such as `Invisible Man` / `The Invisible Man`.
- Add explicit boundary fields and audit artifacts: `boundary_domain`, `boundary_disposition`, `sibling_candidate_domain`, `boundary_basis`, `boundary_confidence`, and `boundary_note`.
- Use title overrides only for high-confidence corrections where the source metadata is demonstrably wrong.

### Phase E: UI And Reading Experience

Status: active.

Goal: make the page look like a serious reading-list tool.

Done when:

- The first screen is not a 5,000-row dump.
- The default view is a chronology-ready reading path, currently `2717` rows with both creator and date, not the full accepted set.
- All Accepted and Unplaced are secondary views with clear labels.
- Users can filter by tier, unit, era, region/tradition, form, and evidence channel.
- Works display title, creator, date/period, tier, form/unit, and concise evidence context without exposing raw audit clutter.
- Progress/status controls still work.
- The page is visually quieter, denser, and less AI-generated.

### Phase F: Release Gate

The first stable quizbowl literature canon is done when:

- Phase A is complete.
- Phase B has adjudicated at least the top `2,000` audit rows and passes the first-`1,000` public-row purity check.
- Phase C has handled the top duplicate/alias families.
- Phase D has provisional classification fields for all public rows and release-quality creator/date metadata for every default-path row.
- Phase E has shipped a filterable UI whose default view is the chronology-ready path.
- The release validation passes: no unresolved rank `<=1000` row, no unresolved row with `total_question_count >= 40`, no unresolved `qb_major` row, no unaudited high-risk adjacent-domain row, no obvious duplicate title family, and no unaudited `quizbowl_author_answerline` creator shown as authoritative in the default path.
- A final method report records corpus version, row counts, thresholds, scoring, audit counts, and known limitations.

### Phase G: Adjacent Quizbowl Reading Lists

Status: planned after the first stable literature release.

Goal: reuse the same raw-corpus method to build sibling reading lists for domains that are valuable but should not pollute the literature canon.

Separate products should be created for:

- `religion`: scripture, theology, devotional texts, sermons, religious autobiography, doctrinal works, and religious history when quizbowl treats the text itself as clueable.
- `mythology`: myth cycles, epics, sagas, folklore collections, named source texts, oral traditions, and major mythographic compilations.
- `philosophy`: primary philosophical works, named essays, dialogues, treatises, and high-salience theory texts.
- `social_science`: anthropology, sociology, political theory/science, economics, psychology, linguistics, media theory, and related nonfiction works.

Done when:

- Each sibling list has its own inclusion rules, rejected/review queues, scoring, and public YAML.
- Boundary rules are explicit for works that can belong to more than one list, such as scripture-as-literature, mythic epics, literary theory, political philosophy, psychoanalysis, anthropology, and religious autobiography.
- The literature list can link to these adjacent products without absorbing non-literary works back into its public rows.
- The UI can expose these domains as separate tabs or separate pages with shared evidence display and filters.

After Phase F/G, further work becomes maintenance:

- Audit the next review batch only when the public list or top audit queue shows a material problem.
- Rebuild when the local quizbowl corpus changes.
- Add separate religion, mythology, philosophy, and social-science products without folding them back into literature.

## Data Model

### Title Candidate

One row per possible literary work title:

- `candidate_id`
- `canonical_title`
- `normalized_title`
- `form_hint`: novel, play, poem, epic, story, collection, scripture/literary text, unknown
- `candidate_source`: raw answerline work prompt, clue extraction, answerline-seed clue mention, clue-derived seed clue mention
- `form_counts_json`
- `answerline_form_counts_json`
- `track_counts_json`: diagnostic quizbowl category counts, not inclusion evidence
- `disambiguation_status`: accepted likely work, common/short title, possible person/character, possible combined title, fragment title, rejected non-literary context, section/subwork title, or low evidence
- `total_question_count`
- `answerline_question_count`
- `clue_mention_question_count`
- `distinct_set_count`
- `distinct_year_count`
- `notes`

### Mention Evidence

One row per detected clue mention:

- `work_id`
- `canonical_title`
- `question_id`
- `set_title`
- `year`
- `question_type`
- `match_type`
- `snippet`

### Canon Score

One row per accepted work cluster:

- `work_id`
- `canonical_title`
- `total_question_count`
- `answerline_question_count`
- `clue_mention_question_count`
- `distinct_set_count`
- `distinct_year_count`
- `first_year`
- `last_year`
- `tossup_count`
- `bonus_count`
- `quizbowl_salience_score`
- `tier`
- `review_status`
- `source_counts_json`
- `form_counts_json`
- `answerline_form_counts_json`
- `track_counts_json`
- `literary_signal_count`
- `non_literary_signal_count`
- `examples_json`

## Extraction Strategy

### Pass 1: Raw Candidate Discovery

Extract likely work titles from two raw channels:

- Raw answerline candidates when the clue prompt asks for a novel, play, poem, story, epic, collection, scripture, or related literary form.
- Clue-text title candidates using quizbowl-specific patterns:

- Quoted spans: `"Bartleby, the Scrivener"`, `"The Dead"`, `"The Waste Land"`.
- Explicit form patterns: `novel X`, `play X`, `poem X`, `story X`, `collection X`, `epic X`.
- Authorship patterns: `author of X`, `wrote X`, `in X`, `from X`, `title character of X`.
- Capitalized title spans near literary verbs: wrote, published, translated, adapted, narrates, opens, ends.

This pass should overgenerate. False positives are handled later.

### Pass 2: Candidate Clustering And Alias Merge

Merge likely same-work strings:

- `Moby-Dick` / `Moby Dick`
- `The Brothers Karamazov` / `Brothers Karamazov`
- `One Hundred Years of Solitude` / `100 Years of Solitude`
- Transliterations and translated title variants where quizbowl clues make the relation explicit.

Keep separate:

- Work vs author.
- Work vs character.
- Whole collection vs individual poem/story when both are clueable.
- Generic short titles unless creator/context disambiguates them.

### Pass 3: Evidence Counting

Count accepted evidence from both raw channels:

- raw work-answerline questions
- clue-text title mentions
- exact clue-text mentions for high-confidence answerline-derived and clue-derived title seeds

Primary threshold:

- `total_question_count >= 3`

Secondary guards:

- Exclude obvious answer-leak rows where clue text contains answer markers or parser failure artifacts.
- Deduplicate by distinct raw question IDs.
- Track distinct set and year spread for scoring and UI display.

### Pass 4: Literature-Only Filtering

Keep literary works:

- Novels
- Plays
- Poems
- Short stories
- Epics
- Literary collections
- Major scriptural/mythic/oral texts when clue usage is literary

Reject or route separately:

- Authors as people
- Characters as people
- Countries, cities, schools, movements
- Films, operas, paintings, albums, unless the quizbowl clue is explicitly for a literary source work
- Philosophy/history/theory unless the product later asks for a humanities canon, not literature-only
- Non-literary context-dominated works are routed to review unless the raw answerline channel repeatedly identifies the candidate as a strong literary form such as a novel, play, poem, story, epic, saga, or collection.

### Pass 5: Tiering By Quizbowl Salience

The frequency count gives canon strength, but raw count is not enough. Score should include breadth and persistence:

```text
quizbowl_salience_score =
  log1p(total_question_count)
  + 0.8 * log1p(distinct_set_count)
  + 0.5 * log1p(distinct_year_count)
  + 0.3 * log1p(tossup_count)
  + 0.7 * log1p(answerline_question_count)
  + 0.2 * log1p(clue_mention_question_count)
```

Initial tiers:

- `qb_core`: very high score, broad set/year spread.
- `qb_major`: strong recurring work.
- `qb_contextual`: clears threshold but narrower circuit/time support.
- `qb_candidate`: clears raw threshold but needs review for ambiguity or parser leakage.
- `qb_rejected`: clears raw threshold but is not a literature-canon work, such as opera/music, social science, philosophy/history/theory, or other non-literary context-dominated material. These rows are kept in audit TSVs and excluded from the public YAML.

## Validation

Run reviewer-style checks before trusting the output:

- Random sample of accepted mentions by tier.
- Top false-positive scan for short/generic titles: `Beloved`, `Emma`, `Fathers and Sons`, `The Trial`, `The Stranger`.
- Answer-leak scan: reject clue rows containing `answer:`, `answers:`, `answerline:`, or visible answer blocks.
- Same-set inflation scan: works whose mentions come mostly from one tournament or one packet family.
- Year-span check: distinguish old quizbowl artifacts from persistent canon.
- Processed-Loci contamination check: prove that evidence counts do not use Loci track labels or canon-refinement tables; track labels may appear only as diagnostic category counts.
- Answerline-gating check: prove that clue-derived works can enter even without answerline support.

## Expected Biases

This canon will be rigorous but not universal.

Likely biases:

- Stronger coverage of English-language, European, American, Russian, and classical literatures.
- Stronger coverage of works clueable in pyramidal question style.
- Underrepresentation of literatures rarely written about in quizbowl.
- Overrepresentation of works that produce memorable character/plot clues.
- Contemporary work lag unless recent quizbowl has adopted it.

These are not reasons to reject the project. They are reasons to label it honestly as quizbowl-derived.

## Implementation Phases

### QL1: Feasibility Slice

Target: 2-4 hours.

- Build a prototype extractor on a sample of clue rows.
- Test known works: `Moby-Dick`, `Hamlet`, `Beloved`, `Things Fall Apart`, `The Tale of Genji`, `The Waste Land`.
- Produce a small mention table and inspect false positives.

### QL2: Full Candidate Extraction

Target: 0.5-1 day.

- Run raw answerline and clue-text title extraction over all parsed question rows.
- Store raw candidates and evidence snippets.
- Generate candidate clusters.
- Use `scripts/build_quizbowl_literature_canon.rb --jobs N` for multiprocessing when rebuilding the full corpus. Workers scan disjoint ID ranges and the parent performs the deterministic merge/write step.

### QL3: Review And Filtering

Target: 0.5-1 day.

- Review top candidates and high-risk ambiguous titles.
- Apply literature-only routing.
- Merge obvious aliases.

### QL4: Scoring And Public Data

Target: 0.5 day.

- Compute quizbowl salience scores.
- Assign tiers.
- Export `_data/quizbowl_literature_canon.yml`.

### QL5: UI Integration

Target: 0.5-1 day.

- Add a separate mode or page for the quizbowl-derived canon.
- Show frequency evidence: mentions, sets, years, first/last appearance.
- Let users filter by tier, form, era if available, and review status.
- Keep the current canon and quizbowl canon visually distinct.

### QL6: Reading-List Units And Deep Filters

Target: 1-3 days for a useful first pass; longer for serious manual refinement.

- Add normalized form labels: novel, play, poem, short story, epic, collection, scripture-as-literature, oral/traditional text, essay/memoir only when treated as literature.
- Add broad eras and unit labels, initially rule-based from dates/title traditions and later manually corrected.
- Add region/tradition labels where evidence is strong enough: Greek, Roman, Sanskrit, Classical Chinese, Japanese, Arabic/Persian, European medieval, early modern European, Russian, Latin American, African, South Asian, East Asian, Indigenous, Caribbean, diasporic, etc.
- Create reading-list views by unit and tier, so the page is not only a ranked list.
- Keep ambiguous unit/era assignments in audit fields until adjudicated.

### QL7: Adjudication And LLM-Assisted Review

Target: iterative.

- Store explicit human or LLM-assisted decisions in `_planning/quizbowl_lit_canon/quizbowl_lit_adjudications.yml`.
- Generate deterministic audit queues: accepted-but-suspicious, rejected-but-rescuable, high-salience review, generic/short title, and split/merge/subwork.
- Write the top bounded, not-yet-adjudicated review packets to `quizbowl_lit_llm_review_queue.jsonl` for optional strict JSON adjudication.
- Use LLM calls only on evidence packets, not as a free-form source of canon additions.
- Require structured JSON decisions: accept literary work, reject non-literary, split, merge, alias, or needs human review.
- Rerun the build after adjudication so every public decision is reproducible.

Current adjudication status:

- First 500 queued evidence packets audited into `quizbowl_lit_adjudications.yml`.
- Rebuilt public YAML with adjudicated accepts only; rejected, duplicate, ambiguous, and non-literary domain rows remain in planning artifacts.
- The JSONL queue now advances to the next pending batch instead of repeating adjudicated rows.

## Later Subject Reading Lists

The same quizbowl-derived method can produce additional reading lists after the literature pipeline is stable. These should be separate products, not folded into literature.

Recommended separation:

- **Religion:** scripture, theological works, devotional texts, religious law, major commentarial traditions, mysticism, and religious-philosophical works when quizbowl treats them primarily as religion.
- **Mythology:** myth cycles, epics, sagas, cosmogonies, oral myth traditions, folklore collections, and mythographic sources. This overlaps with literature, but the product goal is different: mythological literacy rather than literary reading order.
- **Philosophy:** primary philosophical works and major dialogues/treatises. Keep separate from social science because quizbowl has a distinct philosophy category and because the reading-list logic is author/work/argument centered.
- **Social Science:** anthropology, sociology, political theory, economics, psychology, linguistics, and related theory. This may become multiple sublists rather than one flat list, because `The Protestant Ethic`, `Deep Play`, `The Interpretation of Cultures`, `The General Theory`, and similar works belong to different learning arcs.

Initial recommendation:

- Build **religion** and **mythology** as separate but cross-linked lists.
- Build **philosophy** as its own list.
- Build **social science** as an umbrella with subdiscipline filters; later split it if the list becomes large enough.

Shared infrastructure:

- Reuse candidate extraction, scoring, evidence snippets, track diagnostics, rejected audit files, and adjudication YAML.
- Change subject-specific keep/reject rules. For example, `The Magic Flute` remains rejected for literature but might still be rejected for mythology/religion unless the task is music; `Deep Play` is rejected for literature but accepted for social science/anthropology.
- Keep a cross-subject entity map so the same title can have different status by subject.

## Decision Point

After QL1, decide whether to continue with:

- **Strict clue-only discovery:** cleaner philosophically, but misses works that quizbowl mostly asks as answerlines.
- **Answerline-only evidence:** faster, but too narrow and not acceptable for this project.
- **Raw answerline plus raw clue-text evidence:** broader and transparent, while keeping source channels separate.

The implemented route is raw answerline plus raw clue-text evidence with transparent labels, because it improves title recall without making answerlines the closed canon universe.
