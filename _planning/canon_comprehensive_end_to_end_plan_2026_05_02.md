---
title: Comprehensive End-to-End Literature Canon Audit Plan
date: 2026-05-02
status: source_backed_pivot_in_progress
scope: literature_only_global_lifetime_path
target: 3000 public works
---

# Comprehensive End-to-End Literature Canon Audit Plan

This document is the forward plan for making the 3,000-item literature canon defensible. It is also the packet registry that execution logs point back to. Waves 001-005 have been run and integrated as provisional sentinel repairs; detailed outputs live under `_planning/canon_audit_outputs/`.

## 2026-05-03 Workflow Pivot

The workflow is being changed before Wave 006. The first five waves improved obvious omissions, but they did not solve the actual scholarly blocker: most rows remain source-debt rows and the list still relies on inferred categories rather than first-class evidence, taxonomy, and boundary metadata.

Direct content replacement is paused. F031-F034 and all later B/C/D/F packets may still run, but their default role is evidence harvesting and gap discovery, not immediate add/cut integration. Integration resumes only after the source universe, candidate universe, evidence ledger, scoring layer, and boundary policies exist enough to compare current rows and omissions on the same evidence scale.

Execution update: E001-E012 are registered in the source universe. Only E001 currently has source-item and evidence rows because it is local accepted-record evidence. E002/E003 remain blocked by missing Bloom artifacts, and E004-E012 now need source-item extraction before they can support scoring or replacement transactions.

Source-item extraction is tracked separately in `_planning/canon_build/source_item_extraction_plan.md`. The first active extraction batch is X001-X006: classical open metadata, Library of America, medieval public corpora, English/British anthology TOCs, university/reference lists, and African American anthology layers.

The new source of truth is four-layered:

1. Source universe: source registry, source items, source scope, and citation/provenance metadata.
2. Candidate universe: one canonical work cluster per literary work, with aliases, relations, creators, dates, traditions, forms, and review state.
3. Scoring and adjudication: derived evidence scores, coverage targets, duplicate decisions, boundary decisions, and human review decisions.
4. Published paths: generated 3,000-item path data for the public site.

`_data/canon_quick_path.yml` is therefore a provisional published path and incumbent snapshot, not the final master scholarly dataset.

## Immediate Freeze Rules

- No new work may be added as `manual_only`.
- No further replacement wave may merge unless both the added row and displaced row have evidence records or an explicit waiver.
- Bloom, a syllabus, a prize list, or any single source layer cannot be sole support for a locked inclusion.
- Wave 006 is recast as harvest-only unless the user explicitly authorizes an exception after source evidence is present.
- A replacement batch must not increase source debt, unwaived duplicate debt, unwaived chronology debt, or generic-title debt.
- UI/category redesign waits until first-class taxonomy fields exist; presentation filters must not imply precision from keyword-inferred buckets.

## Core Correction

The previous workflow was inadequate because it mixed useful structural checks with spot-checking. Spot-checking can catch visible omissions, but it cannot establish comprehensive coverage. The Washington Irving omission is evidence that the current list must be audited systematically against a defined evidence corpus, period by period, language by language, tradition by tradition, and form by form.

The goal is not to make an impossible claim that no work anywhere in world literature is missing. The goal is to make a reproducible claim: every defined audit packet below was checked against the actual YAML list, omissions were triaged by explicit criteria, replacements were documented, and the final 3,000-item path passed structural, source, duplicate, chronology, and coverage validation.

## Non-Negotiables

- The user should not manually find gaps. User-observed gaps are bug reports, not the audit method.
- Every audit packet must inspect the actual current `_data/canon_quick_path.yml`, not a remembered or assumed list.
- Every proposed addition must name what it displaces unless the target count is intentionally changed.
- Every deletion must state why the removed work is lower priority, duplicate, boundary-leaky, overrepresented, or weaker than the replacement.
- No packet can simply say "looks good." It must output checked sources, checked sentinel authors/titles, omissions found, omissions rejected, and unresolved uncertainty.
- The public site must stay honest: provisional status, source-review status, and broad categories must remain visible until the audit is complete.
- The final standard is "source-backed and exhaustively audited against the registered packet list," not "AI-generated plausible canon."

## Definition Of Done

The canon can be described as locked only when all of the following are true:

- All audit packets in this document are marked complete or explicitly waived with rationale.
- The current path has exactly 3,000 items unless the user approves changing the count.
- Duplicate IDs: 0.
- Duplicate ranks: 0.
- Missing titles: 0.
- Missing creators except genuinely anonymous/traditional works: reviewed.
- Missing or placeholder sort years: 0, except documented oral/traditional cases.
- Future dates beyond current year: 0 unless the work is an ongoing series with a documented reason.
- Every item has a first-pass classification: `macro_region`, `tradition`, `original_language_or_language_family`, `period_bucket`, `form_bucket`, `canon_level`, `selection_basis`, `source_status`, and `review_status`.
- All `manual_only` items have either been source-backed or explicitly kept as provisional.
- Every generic `Selected Poems`, `Selected Stories`, or "Selected..." record has a selection basis.
- Every scripture, oral tradition, myth, religious text, philosophical dialogue, memoir, testimonio, children's/YA work, graphic narrative, and genre work has an explicit boundary rationale for inclusion as literature.
- All high-priority omissions identified by packets have been resolved: added, rejected with rationale, or deferred with a documented source/evidence gap.
- Jekyll build passes.
- A local audit report can be regenerated from scripts rather than manually assembled.

## Evidence Standard

Each candidate title or author must be evaluated using multiple evidence classes, not just one list.

Evidence classes:

- Major world-literature anthologies and teaching canons.
- Region-specific literary histories.
- Language-specific literary histories.
- University survey syllabi and reading lists, used as secondary evidence, not sole authority.
- Major translation series and scholarly editions.
- Prize/reception evidence for modern and contemporary works.
- Existing accepted site records and prior curated entries.
- Bloom and other Western canon lists only as one layer, never as sole authority.
- Specialist sources for oral, Indigenous, manuscript, and performance traditions.

Evidence tiers:

- Tier A, essential: repeated strong evidence across source types or unavoidable status in a major tradition.
- Tier B, major: strong source support or high importance to a tradition, form, movement, or historical moment.
- Tier C, contextual: useful for coverage, genealogy, or representativeness but lower priority if slots are tight.
- Tier D, probationary: recent or contested works that may be valuable but need reception review.
- Tier X, cut: duplicate, boundary leak, low-source support, overrepresented relative to stronger omissions, or unsuitable for literature-only scope.

## Data And Tooling To Build Before Auditing

The first real execution step was to create a local audit harness. That first pass exists. The next real execution step is to build a source-backed canon build layer before more content replacement begins.

Required build-layer artifacts under `_planning/canon_build/`:

- `schemas/canon_source.schema.yml`: source registry and source-item schema.
- `schemas/canon_work.schema.yml`: candidate-work schema.
- `schemas/canon_evidence.schema.yml`: evidence, scoring, and review-decision schema.
- `tables/canon_source_registry.tsv`: one row per source layer with scope and limitations.
- `tables/canon_source_items.tsv`: extracted works from source layers.
- `tables/canon_work_candidates.tsv`: one candidate work cluster per literary work.
- `tables/canon_creators.tsv`: normalized creator authority rows.
- `tables/canon_work_creators.tsv`: work-to-creator join rows.
- `tables/canon_aliases.tsv`: aliases, original titles, translated titles, contained titles, and transliteration variants.
- `tables/canon_relations.tsv`: duplicate, contained-work, series, selection, and supersession relations.
- `tables/canon_evidence.tsv`: work-level source evidence.
- `tables/canon_review_decisions.yml`: human decisions and waivers.
- `tables/canon_scores.tsv`: derived scores and penalties.
- `tables/canon_coverage_targets.yml`: period, region, language/tradition, form, and boundary targets.
- `tables/canon_path_selection.tsv`: selected works for the generated 3,000-item path.
- `tables/canon_replacement_candidates.tsv`: proposed add/cut transactions with evidence.
- `manifests/canon_build_manifest.yml`: build provenance, gates, and artifact status.

Required source-backed build scripts or script modes:

- Validate schemas and required columns.
- Import source registry and source item rows.
- Normalize titles, original titles, translated titles, and creator labels.
- Build alias and relation indexes.
- Match source items to candidate works.
- Resolve duplicates and collection-contained cases.
- Score current items and omissions together.
- Optimize a capped 3,000-item path under coverage and evidence constraints.
- Generate `_data/canon_quick_path.yml` from selected path rows.
- Extend the existing audit harness so it can validate derived tables, not only the published path YAML.

The existing harness outputs remain required until the generated-path workflow replaces them:

Required generated artifacts:

- `canon_inventory.tsv`: one row per item with normalized title, aliases, creators, year, rank, topic, group, unit type, tier, source status, review status.
- `canon_inventory_by_period.tsv`: counts by period bucket.
- `canon_inventory_by_region.tsv`: counts by macro region and subtradition.
- `canon_inventory_by_language.tsv`: counts by original language or language family once inferred/added.
- `canon_inventory_by_form.tsv`: counts by form bucket and unit type.
- `canon_duplicate_candidates.tsv`: normalized title/creator duplicate candidates, including aliases.
- `canon_generic_titles.tsv`: generic records needing selection basis.
- `canon_boundary_cases.tsv`: scripture, myth, oral, philosophy-adjacent, memoir/testimonio, YA, graphic, and genre cases.
- `canon_source_debt.tsv`: source-status and review-status debt.
- `canon_omission_queue.yml`: candidate additions from audit packets, with evidence and proposed displacement.
- `canon_replacement_log.yml`: every add/cut/change with rationale.
- `canon_validation_report.md`: structural validation, coverage counts, unresolved flags, and build result.

Required scripts or script modes:

- Parse YAML and emit normalized inventory.
- Normalize titles with punctuation, articles, transliteration variants, and common subtitles.
- Normalize creators and traditional/anonymous creator labels.
- Match aliases to titles and collection contents.
- Detect likely duplicates by title, alias, creator, and year.
- Produce coverage matrices.
- Produce a packet-specific excerpt for an audit agent.
- Validate proposed edits before they are merged.
- Re-rank after additions/cuts if needed.

## Agent Workflow

Agents are useful, but not as six broad domain audits. The correct pattern is many narrow packets, run iteratively.

Coordinator role:

- Maintains the canonical current YAML.
- Generates packet-specific inventories.
- Assigns packets in waves of at most six agents.
- Requires structured output from each agent.
- Reviews packet output before applying changes.
- Integrates additions/cuts locally.
- Runs validation after each integration batch.
- Updates the audit plan with packet status.

Packet-agent contract:

Each agent receives:

- The packet name and scope.
- The current inventory excerpt relevant to that packet.
- The full normalized title/creator index or enough search summaries to avoid false omissions.
- Required evidence classes for that packet.
- Output schema.

Each agent returns:

- `packet_id`.
- `scope_checked`.
- `sources_or_reference_layers_consulted`.
- `current_coverage_summary`.
- `high_confidence_missing`.
- `medium_confidence_missing`.
- `false_positive_missing_because_already_present_as`.
- `duplicates_or_overlaps`.
- `weak_items_to_cut_or_demote`.
- `boundary_cases`.
- `required_alias_repairs`.
- `recommended_edits`.
- `uncertainties`.

No agent is allowed to directly edit the source list unless assigned an integration packet. Most agents should report, not edit.

Wave rhythm:

1. Generate audit inventory.
2. Assign up to six narrow packets.
3. Wait for all six.
4. Review and merge their findings into `canon_omission_queue.yml`.
5. Apply only high-confidence edits or create a deferred queue.
6. Validate.
7. Commit.
8. Repeat with the next six packets.

## Replacement Rules

When adding a title to a capped 3,000-item path:

- First search for exact title, translated title, original title, common aliases, and collection-level inclusion.
- If absent, classify omission severity: essential, major, contextual, probationary.
- Identify replacement candidates from the same overrepresented neighborhood where possible.
- Prefer cutting:
  - Duplicate variants.
  - Mechanical Bloom appendix leftovers with weak evidence.
  - Generic "Selected..." records with no selection basis.
  - Overrepresented single-author rows where a collected/selected entry already exists.
  - Very recent probationary works without strong reception.
  - Boundary-leaky works that are more history/theory/theology/philosophy than literature.
- Avoid cutting:
  - Underrepresented region/language/tradition anchors.
  - Women, Indigenous, African, Asian, diasporic, and minority-language anchors unless genuinely duplicated or weaker than a replacement in the same underrepresented cell.
  - Oral and manuscript traditions just because they are harder to source.

## Packet Registry

Every packet below should eventually be audited. Packets are intentionally small. Many can be run by agents; some are local validation packets.

### A. Control And Infrastructure Packets

- A001: YAML schema and required fields.
- A002: Rank uniqueness, rank continuity, and hidden/non-lifetime leakage.
- A003: ID uniqueness and stable ID naming.
- A004: Title normalization and article stripping.
- A005: Creator normalization and traditional-author labels.
- A006: Alias coverage for translated titles and alternate spellings.
- A007: Collection-contained title matching.
- A008: Series versus volume duplicate policy.
- A009: Generic `Selected Poems` audit.
- A010: Generic `Selected Stories` audit.
- A011: Generic anthology and selection-basis audit.
- A012: Placeholder date and approximate chronology audit.
- A013: Future-date and ongoing-series audit.
- A014: Source-status debt audit.
- A015: Review-status debt audit.
- A016: Tier drift audit: core, major, contextual.
- A017: Completion-unit audit by form.
- A018: Public UI category audit.
- A019: Admin progress preservation audit.
- A020: Search discoverability audit.
- A021: Duplicate candidate audit by title only.
- A022: Duplicate candidate audit by title plus creator.
- A023: Duplicate candidate audit by alias.
- A024: Duplicate candidate audit by translated/original title.
- A025: Boundary-note missingness audit.
- A026: Region/language metadata missingness audit.
- A027: Count cap and replacement-log audit.
- A028: Reproducible build and generated-file hygiene.
- A029: Rank chronology inversion audit.
- A030: Date-label and sort-year consistency audit.
- A031: Replacement-induced chronology drift audit.

### B. Period Coverage Packets

- B001: Pre-2500 BCE ritual, myth, and early text traditions.
- B002: 2500-1500 BCE ancient Near Eastern and Egyptian literature.
- B003: 1500-1000 BCE Vedic, ancient Israelite, Mesopotamian, and eastern Mediterranean traditions.
- B004: 1000-500 BCE archaic Greek, Hebrew Bible, early Chinese, Iranian, and South Asian traditions.
- B005: 500-300 BCE classical Greek, early Buddhist/Jain, Chinese philosophical-literary, and Sanskrit epic strata.
- B006: 300-1 BCE Hellenistic, Roman Republican, Hebrew/Aramaic, Sanskrit, Tamil, Chinese, and Buddhist traditions.
- B007: 1-300 CE Roman imperial, early Christian, Syriac, Sanskrit, Prakrit, Tamil, and Chinese traditions.
- B008: 300-600 CE late antique Latin/Greek/Syriac, Sanskrit court literature, Tamil post-Sangam, Chinese Six Dynasties.
- B009: 600-900 CE Arabic beginnings, Tang, early Japanese, Old English, Sanskrit drama/poetry, Tamil bhakti.
- B010: 900-1100 CE Heian, Persian, Arabic adab, Old English, Chinese Song, Hebrew Andalusi, South Asian vernacular beginnings.
- B011: 1100-1300 CE Persianate, Arabic, European romance, Icelandic saga, Japanese medieval, Turkic, South Asian vernaculars.
- B012: 1300-1500 CE Dante/Petrarch/Boccaccio aftermath, Chinese vernacular, Persian/Turkic, Noh, Middle English, Iberian, African oral/manuscript.
- B013: 1500-1600 Renaissance, Reformation, Ming, Mughal/Indic, colonial Americas, Ottoman, Iberian, Elizabethan.
- B014: 1600-1700 Baroque, classical French, Mughal/Indic, Edo, Korean, Chinese late Ming/Qing, colonial American, Latin American.
- B015: 1700-1750 early eighteenth-century novel, satire, drama, Chinese/Japanese/Korean, South Asian, Arabic/Persian/Ottoman.
- B016: 1750-1800 Enlightenment, sentimental novel, Gothic, modern vernacular emergence, slavery/Black Atlantic.
- B017: 1800-1830 Romanticism and early national literatures.
- B018: 1830-1850 early Victorian, Russian, French, Latin American, US, colonial and anticolonial writing.
- B019: 1850-1870 realism, slavery/emancipation, nationalism, print expansion, global vernacular novels.
- B020: 1870-1890 naturalism, aestheticism, late realism, Ibsen/modern drama, early genre fiction.
- B021: 1890-1900 fin de siecle, modernismo, decadence, early modernism, colonial modernities.
- B022: 1900-1914 prewar modernism and global realism.
- B023: 1914-1918 World War I literature.
- B024: 1919-1929 high modernism, Harlem Renaissance, anticolonial literatures, global avant-garde.
- B025: 1930-1939 Depression, fascism, socialist realism, late colonial literature, modern genre consolidation.
- B026: 1939-1945 World War II, Holocaust, occupation, exile, prison, resistance literature.
- B027: 1946-1959 postwar reconstruction, partition, decolonization, Cold War beginnings.
- B028: 1960-1969 independence-era African/Asian/Caribbean/Latin American writing and postmodernism.
- B029: 1970-1979 second-wave feminism, postcolonial consolidation, testimonial writing, speculative expansion.
- B030: 1980-1989 late Cold War, migration, Indigenous renaissance, graphic narrative, global postmodernism.
- B031: 1990-1999 post-Cold War, diaspora, memory, globalization, postcolonial second generation.
- B032: 2000-2009 twenty-first century emergence, war-on-terror, migration, climate and globalization.
- B033: 2010-2019 contemporary global reception, translation boom, Indigenous resurgence, feminist/queer expansion.
- B034: 2020-present probationary contemporary works and reception threshold.

### C. Macro-Region And Tradition Packets

- C001: Ancient Egypt.
- C002: Sumerian literature.
- C003: Akkadian and Babylonian literature.
- C004: Ugaritic, Hittite, Hurrian, and Anatolian traditions.
- C005: Hebrew Bible and Tanakh as literature.
- C006: Second Temple, Apocrypha, and Jewish apocalyptic literature.
- C007: Rabbinic and medieval Hebrew literature.
- C008: Syriac, Aramaic, and early Christian eastern traditions.
- C009: Zoroastrian and ancient Iranian texts.
- C010: Classical Arabic poetry.
- C011: Qur'an and Arabic sacred-literary boundary.
- C012: Abbasid adab and prose.
- C013: Maqama and Arabic narrative forms.
- C014: Arabic popular epic and oral-written cycles.
- C015: Andalusi Arabic and Hebrew literature.
- C016: Persian epic and romance.
- C017: Persian lyric and Sufi poetry.
- C018: Persian prose, travel, and didactic literature.
- C019: Ottoman Turkish literature.
- C020: Turkic and Central Asian oral/manuscript traditions.
- C021: Kurdish literature.
- C022: Armenian literature.
- C023: Georgian literature.
- C024: Modern Arabic literature by region.
- C025: Modern Iranian literature.
- C026: Modern Turkish literature.
- C027: Hebrew and Israeli literature.
- C028: Yiddish literature.
- C029: North African Arabic, Amazigh, and Francophone literature.
- C030: Greek archaic epic and hymn.
- C031: Greek lyric.
- C032: Greek tragedy.
- C033: Greek comedy and satyr drama.
- C034: Greek historiography and prose as literature.
- C035: Greek philosophy-adjacent literary texts.
- C036: Hellenistic Greek literature.
- C037: Roman Republican poetry and comedy.
- C038: Augustan Latin literature.
- C039: Roman imperial satire, epic, novel, and epigram.
- C040: Late antique Latin and Greek.
- C041: Byzantine Greek.
- C042: Medieval Latin.
- C043: Old English.
- C044: Middle English.
- C045: Old Norse and Icelandic saga.
- C046: Medieval Irish.
- C047: Medieval Welsh.
- C048: Old French and Arthurian romance.
- C049: Occitan troubadour lyric.
- C050: Middle High German.
- C051: Medieval Iberian and Catalan.
- C052: Italian medieval and Renaissance.
- C053: French Renaissance.
- C054: Spanish Golden Age.
- C055: Portuguese Renaissance and early modern.
- C056: English Renaissance poetry and prose.
- C057: Shakespeare completeness and selection policy.
- C058: English Renaissance and Jacobean drama beyond Shakespeare.
- C059: French classicism and seventeenth-century drama.
- C060: English Restoration and eighteenth-century literature.
- C061: European Enlightenment prose, satire, and drama.
- C062: German classicism and Romanticism.
- C063: British Romanticism.
- C064: French Romanticism.
- C065: Russian Golden Age.
- C066: Victorian British novel and poetry.
- C067: French realism, naturalism, and symbolism.
- C068: Spanish and Portuguese nineteenth-century literature.
- C069: Italian nineteenth-century literature.
- C070: Scandinavian nineteenth-century literature.
- C071: Dutch and Flemish literature.
- C072: Polish literature.
- C073: Czech and Slovak literature.
- C074: Hungarian literature.
- C075: Romanian literature.
- C076: Balkan literatures.
- C077: Baltic literatures.
- C078: Ukrainian literature.
- C079: Russian modernism and Soviet literature.
- C080: European modernism.
- C081: Holocaust, prison, exile, and witness literature in Europe.
- C082: Postwar continental European fiction.
- C083: Contemporary European literature.
- C084: Vedic and early Sanskrit traditions.
- C085: Sanskrit epics and Puranic literature.
- C086: Classical Sanskrit drama.
- C087: Classical Sanskrit poetry and kavya.
- C088: Sanskrit narrative collections and fable traditions.
- C089: Pali Buddhist canon and narrative.
- C090: Jain Prakrit and Jain narrative/philosophical literature.
- C091: Tamil Sangam literature.
- C092: Tamil bhakti and medieval Tamil.
- C093: Telugu literature.
- C094: Kannada literature.
- C095: Malayalam literature.
- C096: Bengali literature.
- C097: Hindi literature.
- C098: Urdu literature.
- C099: Punjabi literature.
- C100: Marathi literature.
- C101: Odia literature.
- C102: Assamese literature.
- C103: Nepali literature.
- C104: Sinhala literature.
- C105: South Asian Persianate and Indo-Persian literature.
- C106: South Asian Dalit literature.
- C107: South Asian Partition literature.
- C108: South Asian diasporic literature.
- C109: Classical Chinese poetry.
- C110: Classical Chinese prose, philosophy, and historiography as literature.
- C111: Chinese mythographic and anomaly literature.
- C112: Tang poetry.
- C113: Song ci and prose.
- C114: Yuan drama.
- C115: Ming-Qing vernacular novels.
- C116: Qing fiction and strange tales.
- C117: Modern Chinese literature.
- C118: Taiwanese literature.
- C119: Hong Kong and Sinophone diaspora.
- C120: Tibetan literature.
- C121: Mongolian literature.
- C122: Japanese mythic and court literature.
- C123: Heian diaries, tales, and poetry.
- C124: Medieval Japanese war tales and setsuwa.
- C125: Noh, haikai, and Edo literature.
- C126: Meiji and Taisho Japanese literature.
- C127: Modern and postwar Japanese literature.
- C128: Contemporary Japanese literature.
- C129: Korean classical and Joseon literature.
- C130: Korean pansori and vernacular fiction.
- C131: Modern Korean literature.
- C132: Contemporary Korean literature.
- C133: Vietnamese literature.
- C134: Thai literature.
- C135: Khmer literature.
- C136: Burmese literature.
- C137: Malay and Indonesian literature.
- C138: Filipino literature.
- C139: Lao literature.
- C140: Javanese and other Indonesian manuscript traditions.
- C141: Indigenous Australian literature.
- C142: Maori literature.
- C143: Pacific Islander literature.
- C144: Arctic and Inuit literature.
- C145: Hawaiian and Polynesian chant/tradition.
- C146: Ancient and medieval African manuscript traditions.
- C147: Ethiopic and Ge'ez literature.
- C148: Swahili literature.
- C149: Yoruba oral and written literature.
- C150: Hausa literature.
- C151: Somali literature.
- C152: West African oral epic traditions.
- C153: Mande/Sunjata tradition.
- C154: Central African oral traditions.
- C155: East African literature.
- C156: Horn of Africa literature.
- C157: South African literature.
- C158: Southern African literature.
- C159: Lusophone African literature.
- C160: Francophone West and Central African literature.
- C161: Anglophone West African literature.
- C162: Caribbean African-diasporic literature.
- C163: Black Atlantic slave narratives and abolition literature.
- C164: African American literature to 1900.
- C165: African American literature 1900-1945.
- C166: African American literature 1945-present.
- C167: Native American and First Nations oral/public traditions.
- C168: Native American literature to 1900.
- C169: Native American renaissance and contemporary literature.
- C170: Mesoamerican manuscript and oral traditions.
- C171: Maya literature.
- C172: Nahuatl literature.
- C173: Quechua and Andean literature.
- C174: Mapuche literature.
- C175: Other Indigenous American literatures.
- C176: Colonial Spanish American literature.
- C177: Brazilian colonial and imperial literature.
- C178: Latin American nineteenth-century literature.
- C179: Modernismo and Latin American poetry.
- C180: Latin American Boom and post-Boom.
- C181: Contemporary Latin American literature.
- C182: Caribbean Anglophone literature.
- C183: Caribbean Francophone and Creole literature.
- C184: Caribbean Hispanophone literature.
- C185: US early national literature.
- C186: US nineteenth-century canon.
- C187: US modernism.
- C188: US postwar fiction and poetry.
- C189: US contemporary literature.
- C190: Canadian literature.
- C191: Mexican literature.
- C192: Central American literature.
- C193: Cuban and Cuban American literature.
- C194: Dominican and Dominican American literature.
- C195: Chicano/a/x and borderlands literature.
- C196: Diasporic, migration, and refugee literature cross-audit.

### D. Form And Genre Packets

- D001: Epic.
- D002: Oral epic.
- D003: Mythic cycles.
- D004: Sacred texts as literature.
- D005: Wisdom literature.
- D006: Lyric poetry.
- D007: Devotional poetry.
- D008: Court poetry.
- D009: Modern poetry.
- D010: Drama: tragedy.
- D011: Drama: comedy.
- D012: Drama: classical and early modern.
- D013: Drama: modern global.
- D014: Novel origins and early novel.
- D015: Realist novel.
- D016: Naturalist novel.
- D017: Modernist novel.
- D018: Postmodern novel.
- D019: Postcolonial novel.
- D020: Short story and tale cycles.
- D021: Fable, fairy tale, and beast tradition.
- D022: Romance and chivalric narrative.
- D023: Gothic, horror, and weird.
- D024: Science fiction.
- D025: Fantasy.
- D026: Crime and detective fiction.
- D027: Children's literature.
- D028: Young adult literature.
- D029: Graphic narrative and comics.
- D030: Testimonio.
- D031: Slave narrative.
- D032: Prison, camp, and witness writing.
- D033: Memoir and autobiography.
- D034: Diary and travel writing.
- D035: Essay and literary prose.
- D036: Philosophical dialogue as literature.
- D037: Satire.
- D038: Pastoral.
- D039: War literature.
- D040: Climate/ecological literature.
- D041: Feminist literature.
- D042: Queer literature.
- D043: Diasporic literature.
- D044: Translation anthology and selection policy.
- D045: Series treatment policy.
- D046: Anthology versus individual-work treatment.

### E. Source-Crosswalk Packets

These packets compare the current YAML against major reference layers. Each source-crosswalk packet must report present, absent, represented-by-selection, duplicate, and rejected/out-of-scope entries.

- E001: Existing accepted `_canon` records crosswalk.
- E002: Bloom curated seed layer.
- E003: Bloom full appendix cleanup layer.
- E004: Norton Anthology of World Literature crosswalk.
- E005: Longman Anthology of World Literature crosswalk.
- E006: Bedford or comparable world literature anthology crosswalk.
- E007: Columbia/Princeton/Oxford world literature reading-list layer.
- E008: Major Greek/Roman classics source layer.
- E009: Major medieval European anthology layer.
- E010: Major English literature anthology layer.
- E011: Major American literature anthology layer.
- E012: Major African American literature anthology layer.
- E013: Major Latin American literature source layer.
- E014: Major African literature anthology layer.
- E015: Major South Asian literature source layer.
- E016: Major Chinese literature anthology layer.
- E017: Major Japanese literature anthology layer.
- E018: Major Korean literature source layer.
- E019: Major Arabic literature source layer.
- E020: Major Persian literature source layer.
- E021: Major Indigenous literatures source layer.
- E022: Major oral epic and folklore source layer.
- E023: Major science fiction/fantasy/horror source layer.
- E024: Major children's and YA literature source layer.
- E025: Major graphic narrative source layer.
- E026: Nobel/Booker/International Booker/Neustadt/Cervantes/Camoes/major prize sanity layer.
- E027: Translation-series layer: Penguin/Oxford/Loeb/NYRB/Classics-style availability.
- E028: University syllabus sampled layer by period.
- E029: University syllabus sampled layer by region.
- E030: Specialist minority-language source layer.

### F. Sentinel Author And Title Packets

These are not automatic inclusion lists. They are "must check" sentinels because an omission here would likely indicate a process failure.

- F001: Early US: Washington Irving, James Fenimore Cooper, Catharine Maria Sedgwick, Charles Brockden Brown, Susanna Rowson.
- F002: US transcendentalism: Emerson, Thoreau, Fuller, Margaret Fuller boundary decision.
- F003: US nineteenth-century fiction: Poe, Hawthorne, Melville, Stowe, Douglass, Jacobs, Twain, Chesnutt, Crane, Chopin.
- F004: US poetry to 1900: Whitman, Dickinson, Longfellow, Poe, Bryant, Whittier, Dunbar.
- F005: US realism/naturalism: Henry James, Howells, Wharton, Cather, Dreiser, Norris, London, Sinclair.
- F006: US modernism: Eliot, Pound, Stein, Hemingway, Fitzgerald, Faulkner, Dos Passos, Cummings, Stevens, Williams, Moore, Toomer.
- F007: Harlem Renaissance: Hughes, Hurston, Cullen, McKay, Larsen, Toomer, Brown.
- F008: US postwar fiction: Ellison, Baldwin, O'Connor, Bellow, Roth, Pynchon, Morrison, DeLillo, McCarthy, Robinson, Doctorow.
- F009: British medieval/Renaissance: Chaucer, Langland, Pearl poet, Malory, Spenser, Marlowe, Shakespeare, Jonson, Webster, Middleton, Ford.
- F010: British seventeenth/eighteenth: Donne, Herbert, Milton, Marvell, Dryden, Behn, Swift, Pope, Defoe, Richardson, Fielding, Sterne, Johnson.
- F011: British Romantic: Blake, Wordsworth, Coleridge, Byron, Shelley, Keats, Austen, Scott, Mary Shelley, De Quincey.
- F012: British Victorian: Dickens, Eliot, Bronte sisters, Gaskell, Thackeray, Hardy, Tennyson, Browning, Barrett Browning, Rossetti, Hopkins, Wilde.
- F013: British/Irish modern: Joyce, Woolf, Yeats, Lawrence, Conrad, Forster, Mansfield, Beckett, Eliot, Auden, Bowen.
- F014: French medieval/early modern: Chretien, Marie de France, Rabelais, Montaigne, Corneille, Racine, Moliere, La Fontaine, Lafayette.
- F015: French eighteenth/nineteenth: Voltaire, Rousseau, Diderot, Laclos, Stendhal, Balzac, Hugo, Flaubert, Baudelaire, Zola, Maupassant, Rimbaud, Mallarme, Verlaine.
- F016: French twentieth: Proust, Gide, Valery, Breton, Celine, Sartre, Camus, Duras, Robbe-Grillet, Genet, Ernaux.
- F017: Spanish/Iberian: Cervantes, Lope, Calderon, Tirso, Quevedo, Gongora, Becquer, Galdos, Unamuno, Lorca, Machado, Cela, Matute, Marias.
- F018: Portuguese/Lusophone: Camoes, Eca, Pessoa, Saramago, Lobo Antunes, Agualusa, Couto, Chiziane, Evaristo.
- F019: Italian: Dante, Petrarch, Boccaccio, Ariosto, Tasso, Goldoni, Leopardi, Manzoni, Verga, Pirandello, Svevo, Montale, Calvino, Morante, Eco, Ferrante.
- F020: German-language: Goethe, Schiller, Holderlin, Heine, Kleist, Hoffmann, Buchner, Fontane, Rilke, Kafka, Mann, Brecht, Hesse, Celan, Grass, Bernhard, Jelinek, Sebald.
- F021: Russian: Pushkin, Lermontov, Gogol, Turgenev, Dostoevsky, Tolstoy, Chekhov, Leskov, Goncharov, Bely, Bulgakov, Pasternak, Akhmatova, Mandelstam, Tsvetaeva, Solzhenitsyn.
- F022: Scandinavian: Ibsen, Strindberg, Hamsun, Lagerlof, Andersen, Laxness, Vesaas, Jansson, Fosse, Knausgaard.
- F023: Greek/Roman: Homer, Hesiod, Sappho, Pindar, Aeschylus, Sophocles, Euripides, Aristophanes, Herodotus, Thucydides, Plato, Aristotle, Virgil, Horace, Ovid, Lucretius, Apuleius.
- F024: Sanskrit/South Asian classical: Valmiki, Vyasa, Kalidasa, Bhasa, Bharavi, Magha, Sudraka, Banabhatta, Jayadeva, Bhartrihari.
- F025: South Asian modern: Tagore, Premchand, Bankim, Sarat Chandra, Manto, Ghalib, Iqbal, Faiz, Mahasweta Devi, Narayan, Rushdie, Roy, Mistry, Ghosh, Adichie? check diaspora classification.
- F026: Chinese: Confucius, Laozi, Zhuangzi, Qu Yuan, Sima Qian, Tao Yuanming, Li Bai, Du Fu, Wang Wei, Bai Juyi, Su Shi, Cao Xueqin, Pu Songling, Lu Xun, Lao She, Eileen Chang, Mo Yan, Yu Hua, Can Xue.
- F027: Japanese: Murasaki, Sei Shonagon, Basho, Chikamatsu, Saikaku, Bakin, Soseki, Ogai, Akutagawa, Kawabata, Tanizaki, Mishima, Oe, Abe Kobo, Murakami, Ogawa, Tawada.
- F028: Korean: Samguk traditions, pansori works, Yi Kwang-su, Hwang Sun-won, Pak Kyong-ni, Yi Mun-yol, Han Kang, Hwang Sok-yong, Park Wan-suh.
- F029: Arabic/Persian/Turkic: Imru al-Qays, al-Mutanabbi, al-Jahiz, al-Hariri, Nizami, Attar, Rumi, Saadi, Hafez, Ferdowsi, Khayyam, Mahfouz, Darwish, Kanafani, Pamuk.
- F030: African: Tutuola, Achebe, Soyinka, Ngugi, Head, Gordimer, Coetzee, Mahfouz, Salih, Farah, Sembene, Conde, Couto, Dangarembga, Gurnah, Adichie, Okri, Mabanckou.
- F031: Latin American: Sor Juana, Sarmiento, Dario, Marti, Machado de Assis, Borges, Asturias, Rulfo, Neruda, Paz, Garcia Marquez, Cortazar, Fuentes, Vargas Llosa, Lispector, Allende, Bolano.
- F032: Caribbean: Walcott, Naipaul, Lamming, Rhys, Kincaid, Chamoiseau, Conde, Danticat, James, Brathwaite, Lovelace.
- F033: Indigenous Americas: Popol Vuh, Rabinal Achi, Cantares Mexicanos, Huarochiri, Silko, Momaday, Erdrich, Vizenor, Alexie, Harjo, Ortiz, King, Orange, Long Soldier.
- F034: Oceania/Arctic: Kumulipo, Wendt, Grace, Ihimaera, Hulme, Wright, Kim Scott, Alexis Wright, Tagaq, Avia, Nappaaluk.

### G. Boundary And Policy Packets

- G001: What counts as literature versus philosophy.
- G002: What counts as literature versus theology.
- G003: What counts as literature versus history.
- G004: What counts as literature versus political theory.
- G005: What counts as literature versus anthropology/ethnography.
- G006: Sacred text selection policy.
- G007: Oral tradition representation policy.
- G008: Public versus restricted ceremonial material policy.
- G009: Indigenous source and cultural sensitivity policy.
- G010: Anthology excerpt policy.
- G011: Complete work versus selected reading policy.
- G012: Series inclusion policy.
- G013: Children's and YA canon policy.
- G014: Genre fiction inclusion policy.
- G015: Graphic narrative policy.
- G016: Very contemporary work probation policy.
- G017: Nobel/prize overfitting policy.
- G018: Western overrepresentation correction policy.
- G019: Translation availability versus canonical importance policy.
- G020: Author overrepresentation policy.
- G021: Single-work versus selected-author-entry policy.
- G022: Pseudonymous and traditional authorship policy.
- G023: Dates for oral/manuscript traditions policy.
- G024: Colonization, race, gender, and empire coverage policy.
- G025: Source-backed exclusion policy.

### H. Integration Packets

- H001: First integration wave from high-confidence omissions.
- H002: Rank repair after first integration.
- H003: Alias repair after first integration.
- H004: Duplicate repair after first integration.
- H005: Source-status update after first integration.
- H006: Public UI category regeneration.
- H007: Second integration wave from source-crosswalk packets.
- H008: Rank repair after second integration.
- H009: Duplicate repair after second integration.
- H010: Replacement-log review.
- H011: User-facing summary draft.
- H012: Final validation report.
- H013: Chronology repair after replacement batches.
- H014: Duplicate candidate closeout after replacement batches.

## Execution Order

The packet registry is large by design. The execution order should be staged so errors are caught early.

Phase S0: Freeze current baseline and claims.

- Treat commit `64600ddb264839d57a173438490f36eeed4c31b3` as the Wave 005 incumbent baseline unless superseded by a later committed baseline.
- Keep the public claim provisional: "3,000-work literature path under source audit," not "complete global canon."
- Do not change canon content except to fix structural invalidity.

Phase S1: Source and candidate universe scaffolding.

- Build `_planning/canon_build/` schemas, tables, manifest, and gates.
- Freeze source classes and extraction rules.
- Make path membership separate from work identity.

Phase S2: Source-crosswalk ingestion.

- Run E001-E030 in waves of six.
- Each E packet outputs structured source items: present, absent, represented-by-selection, duplicate/variant, out-of-scope, rejected, unresolved.
- Convert source debt only when evidence records support the change.
- Do not use E packets as immediate replacement engines.

Phase S3: Normalize, dedupe, and first-class taxonomy.

- Build aliases, relations, and duplicate decisions.
- Add or derive candidate-level `macro_region`, `subregion`, `original_language`, `literary_tradition`, `period_bucket`, `form_bucket`, `selection_basis`, `included_as_literature`, and `boundary_policy_id`.
- Close or explicitly waive generic-title, duplicate, and major chronology debt before large integration resumes.

Phase S4: Score and coverage matrix.

- Score every current item and every source-backed omission with the same rubric.
- Build period x region x language/tradition x form x source-class coverage matrices.
- Create replacement candidates from score deltas and coverage constraints, not from ad hoc preference.

Phase S5: Boundary and policy adjudication.

- Run G001-G025 before large replacement batches.
- Lock policies for scripture, oral tradition, Indigenous/public material, philosophy/theology/history leakage, memoir/testimonio, children/YA, genre fiction, graphic narrative, anthology selections, and series.
- Boundary-sensitive rows must carry an inclusion rationale before being treated as locked.

Phase S6: Period, region, and form sweeps as validation.

- Run B001-B034 and C001-C196 in waves of six.
- Run D001-D046 as form-validation packets.
- Use these packets to challenge the scored universe, find source blind spots, and identify weak coverage cells.
- Do not integrate directly unless gates in S2-S5 are satisfied.

Phase S7: Source-backed integration.

- Apply add/cut transactions only from `canon_replacement_candidates.tsv`.
- Every addition names a displacement and every displacement has a source-reviewed rationale.
- Each integration batch regenerates validation outputs, replacement log, omission queue, source debt report, duplicate report, chronology report, and build status.

Phase S8: Public UI and generated path.

- Generate `_data/canon_quick_path.yml` from selected path rows once build-layer tables are stable.
- Update UI filters to use first-class period, region, language/tradition, form, tier, source status, and review status fields.
- Keep source/review status visible until locked-canon thresholds are actually met.

Phase S9: Final adversarial review.

- Assign agents to attack the finished list by trying to find missing essentials, duplicates, weak overrepresented clusters, and unjustified boundary decisions.
- Any found omission opens a new packet rather than an ad hoc fix.

## Output Required After Each Agent Wave

After each wave of up to six packets, the coordinator should produce:

- Packets completed.
- High-confidence additions proposed.
- High-confidence cuts proposed.
- Alias repairs proposed.
- Source-status repairs proposed.
- Items deferred and why.
- Validation status.
- Next six packets.

## Immediate Next Steps

1. Commit the source-backed pivot plan and tracker update.
2. Add `_planning/canon_build/` schemas, empty tables, and manifest.
3. Recast F031-F034 as harvest-only if run before source scoring.
4. Start E001-E006 as structured source-crosswalk ingestion, not replacement integration.
5. Populate source and candidate rows from E packet outputs.
6. Build scoring, coverage, duplicate, chronology, and boundary gates before the next content-replacement batch.

## Current Known Red Flags To Seed The Queue

These are not the full audit. They are initial red flags discovered from the current list and prior user feedback:

- Washington Irving was absent until manually added. This proves the prior process missed core early US coverage.
- Emerson appears absent from quick search and needs a boundary decision: essays may belong in the literature path if Montaigne, Pascal, Johnson, Baldwin, and similar prose are included.
- The first-pass harness still reports duplicate candidate keys. These are not all true duplicates, but they must be resolved or explicitly waived under A021-A024 and H014.
- The first-pass harness still reports placeholder/approximate date rows, and replacement batches can create rank chronology inversions. These must be resolved or explicitly waived under A012, A029-A031, and H013.
- The current list still has many `manual_only` and `needs_sources` records.
- The path is heavily weighted toward 1900-present and especially 1946-present.
- Many `Selected Poems` records need selection bases.
- "Genre / Cross-Regional" is a UI bucket, not a scholarly tradition; underlying metadata needs real region/language fields.
- Some automatic form categorization is presentation-only and must not substitute for scholarly classification.
