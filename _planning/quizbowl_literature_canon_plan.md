# Quizbowl-Derived Literature Canon Plan

Date: 2026-05-04

Status: implemented_parallel_track

## Core Idea

Build a literature canon from the raw quizbowl corpus. Do not use Bloom, online lists, anthology tables of contents, syllabi, the existing canon, Loci literature-track labels, or Loci canon-refinement tables as inclusion evidence. The current canon is preserved as-is; this becomes a separate experimental canon and comparison layer.

## Final Product Goal

The main deliverable is a quizbowl-derived literature reading list, not just a raw canon dump. The public product should help someone decide what to read, in what broad order, and why each work matters in quizbowl culture.

The final literature product should include:

- A clean accepted reading list of literary works.
- A salience score and tier for each work.
- Evidence links or snippets showing why the work appears.
- Filters for tier, source channel, review status, form/genre, era, region/tradition, and eventually unit.
- Reading-list views that can be grouped into units such as ancient epic/scripture-as-literature, classical drama, medieval romance, early modern drama, global novel traditions, modernism, postcolonial literature, contemporary global literature, poetry, short fiction, literary criticism/theory, and oral traditions.
- Audit-only rejected/review queues so opera, social science, philosophy, geography artifacts, author names, characters, and ambiguous title fragments do not pollute the public reading list.

The correct endpoint is a browsable and deeply filterable quizbowl literature syllabus, backed by reproducible evidence.

The inclusion signal is simple in principle:

- A literary work becomes eligible when it appears in at least four distinct raw quizbowl questions.
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
- `_data/quizbowl_literature_canon.yml`

Do not overwrite `_data/canon_quick_path.yml`.

The public YAML should contain only `accepted_likely_work` rows. Ambiguous `needs_review_*` candidates and rejected rows remain available in TSV/JSONL audit artifacts, but they should not drive the public reading-list UI.

## End-To-End Completion Plan

This project is done in stages. The corpus-derived canon will never be permanently final because new quizbowl packets can be added, but the first production-quality version has concrete stopping criteria.

### Phase Map

| Phase | Name | Status | Exit Gate | Primary Artifacts |
| --- | --- | --- | --- | --- |
| A | Evidence Pipeline | complete enough for iteration | Raw answerlines and clue text produce reproducible accepted/rejected/review outputs without Loci processed canon tables. | build script, method report, public YAML |
| B | Public-List Purity | active, `2,011 / 2,000` top audit and public-purity rows adjudicated; first-`1,000` public-row spot check completed | Top `2,000` audit rows adjudicated, first `1,000` public rows pass spot checks, and the next queue is mostly real boundary cases. | adjudications YAML, rejected TSV, review queue |
| C | Alias And Duplicate Consolidation | active, `159` high-confidence alias rules added; `Invisible Man`/`The Invisible Man` marked distinct | High-salience duplicate families and whole/subwork boundaries are resolved or explicitly routed. | cluster TSV, adjudications YAML |
| D | Classification Layer | not started | Every public row has provisional form, unit, era, region/tradition, and confidence fields. | enriched public YAML |
| E | UI And Reading Experience | not started | The public page is a filterable reading-list tool rather than a flat row dump. | site pages/components/styles |
| F | Literature Release Gate | not started | A stable quizbowl literature canon has passed A-E and has a final method report. | public site, method report |
| G | Adjacent Quizbowl Reading Lists | planned after F | Religion, mythology, philosophy, and social-science sibling products have their own pipelines and public pages. | separate domain YAMLs and pages |

Current operating phase: Phase C. The top-audit-row count has crossed `2,000` adjudicated rows, the first-`1,000` public-row purity pass removed obvious fragments and non-work rows, and the builder now supports manual alias merges so duplicate variants contribute to one canonical row instead of splitting quizbowl strength.

Current Phase C caveat: `Diary of a Madman` is kept as a public row with article variants merged, but its evidence mixes Gogol and Lu Xun translation conventions. It should be revisited in an author-aware split pass rather than treated as fully resolved.

### Phase Transition Rules

- Do not start Phase D classification until Phase B has removed obvious public-list pollution and Phase C has resolved the worst duplicate families.
- Do not redesign the UI in Phase E until the data model has the classification fields users will filter by.
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

### Phase D: Classification Layer

Status: not started.

Goal: make the list usable as a reading syllabus rather than a flat ranking.

Done when every public row has at least provisional:

- `form`: novel, play, poem, epic, short story, collection, scripture-as-literature, oral/traditional text, memoir/autobiography, essay, literary criticism/theory, mixed/other.
- `unit`: broad reading-list grouping.
- `era`: ancient, classical, late antique, medieval, early modern, long 19th century, modernist, postwar, contemporary, or more specific where useful.
- `region_or_tradition`: Greek, Roman, Sanskrit, Hebrew, Arabic/Persian, Chinese, Japanese, Russian, Latin American, African, Caribbean, Indigenous, etc.
- `confidence`: rule-derived, manually checked, or needs review.

### Phase E: UI And Reading Experience

Status: not started.

Goal: make the page look like a serious reading-list tool.

Done when:

- The first screen is not a 5,000-row dump.
- Users can filter by tier, unit, era, region/tradition, form, and evidence channel.
- Works display concise evidence and score context without exposing raw audit clutter.
- Progress/status controls still work.
- The page is visually quieter, denser, and less AI-generated.

### Phase F: Release Gate

The first stable quizbowl literature canon is done when:

- Phase A is complete.
- Phase B has adjudicated at least the top `2,000` audit rows and passes the first-`1,000` public-row purity check.
- Phase C has handled the top duplicate/alias families.
- Phase D has provisional classification fields for all public rows.
- Phase E has shipped a filterable UI.
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

- `total_question_count >= 4`

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
