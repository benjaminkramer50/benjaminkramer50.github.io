#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")

PACKET_ID = "X070"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x070.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_054_x070_targeted_external_source_rescue.md")

APPLIED_HEADERS = %w[
  applied_id work_id title creator source_id source_item_id evidence_id source_type
  evidence_type evidence_strength reviewer_status source_debt_status_before
  source_debt_status_after action_lane_after resolution_status next_action rationale
].freeze

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

DOWNSTREAM_SCRIPTS = %w[
  scripts/canon_report_source_debt_status.rb
  scripts/canon_generate_scoring_inputs.rb
  scripts/canon_generate_scores.rb
  scripts/canon_generate_cut_candidates.rb
  scripts/canon_generate_replacement_pairings.rb
  scripts/canon_generate_pair_review_queue.rb
  scripts/canon_generate_cut_review_work_orders.rb
  scripts/canon_generate_generic_selection_basis_review.rb
  scripts/canon_generate_cut_side_post_x058_action_queue.rb
  scripts/canon_generate_current_rescue_scope_refresh_x065.rb
  scripts/canon_generate_high_risk_rescue_residue_x063.rb
  scripts/canon_report_source_item_progress.rb
].freeze

TARGET_WORKS = [
  "work_candidate_mandatory_bradstreet_tenth_muse",
  "work_candidate_latcarib_lit_walcott_collected_poems",
  "work_candidate_latcarib_lit_all_fires_fire",
  "work_candidate_latcarib_lit_blow_up",
  "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0835_collected_poems",
  "work_candidate_completion_lit_selected_poems_milosz",
  "work_candidate_global_lit_nazim_hikmet_poems"
].freeze

REGISTRY_ROWS = [
  {
    "source_id" => "x070_britannica_bradstreet_tenth_muse_reference",
    "source_title" => "Britannica: The Tenth Muse Lately Sprung Up in America",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Work-specific Britannica reference entry for Anne Bradstreet's The Tenth Muse",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopaedia Britannica, The Tenth Muse Lately Sprung Up in America, https://www.britannica.com/topic/The-Tenth-Muse-Lately-Sprung-Up-in-America",
    "edition" => "online reference entry",
    "editors_or_authors" => "Encyclopaedia Britannica",
    "publisher" => "Encyclopaedia Britannica",
    "coverage_limits" => "Work-specific reference support only",
    "extraction_method" => "Targeted X070 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Confirms title, creator, and 1650 work identity for the Bradstreet collection."
  },
  {
    "source_id" => "x070_poetry_foundation_bradstreet_tenth_muse_reference",
    "source_title" => "Poetry Foundation: Anne Bradstreet",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Poetry Foundation poet biography with work-specific The Tenth Muse discussion",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Poetry Foundation, Anne Bradstreet, https://www.poetryfoundation.org/poets/anne-bradstreet",
    "edition" => "online poet biography",
    "editors_or_authors" => "Poetry Foundation",
    "publisher" => "Poetry Foundation",
    "coverage_limits" => "Author biography; supports work-specific collection identity and reception",
    "extraction_method" => "Targeted X070 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Confirms The Tenth Muse as Bradstreet's poetry volume first published in London in 1650."
  },
  {
    "source_id" => "x070_macmillan_walcott_collected_poems_reference",
    "source_title" => "Macmillan: Collected Poems, 1948-1984",
    "source_type" => "publisher_reference_series",
    "source_scope" => "Official Macmillan/FSG page for Derek Walcott's Collected Poems, 1948-1984",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Macmillan, Collected Poems, 1948-1984, https://us.macmillan.com/books/9780374520250/collectedpoems19481984/",
    "edition" => "Farrar, Straus and Giroux paperback listing",
    "editors_or_authors" => "Derek Walcott",
    "publisher" => "Macmillan / Farrar, Straus and Giroux",
    "coverage_limits" => "Publisher page; supports collection identity and publication record",
    "extraction_method" => "Targeted X070 public publisher review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Official publisher page identifies the collection and describes its scope."
  },
  {
    "source_id" => "x070_nobel_walcott_bibliography_reference",
    "source_title" => "Nobel Prize: Derek Walcott Bibliography",
    "source_type" => "prize_or_reception_layer",
    "source_scope" => "Nobel Prize bibliography listing Walcott's Collected Poems 1948-1984",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "NobelPrize.org, Derek Walcott Bibliography, https://www.nobelprize.org/prizes/literature/1992/walcott/bibliography/",
    "edition" => "online laureate bibliography",
    "editors_or_authors" => "Nobel Prize Outreach",
    "publisher" => "Nobel Prize Outreach",
    "coverage_limits" => "Reception/bibliographic layer; not a teaching anthology",
    "extraction_method" => "Targeted X070 public Nobel bibliography review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Lists Collected Poems 1948-1984 in Walcott's Nobel bibliography."
  },
  {
    "source_id" => "x070_britannica_all_fires_fire_reference",
    "source_title" => "Britannica: All Fires the Fire, and Other Stories",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Work-specific Britannica reference entry for Cortazar's All Fires the Fire",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopaedia Britannica, All Fires the Fire, and Other Stories, https://www.britannica.com/topic/All-Fires-the-Fire-and-Other-Stories",
    "edition" => "online reference entry",
    "editors_or_authors" => "Encyclopaedia Britannica",
    "publisher" => "Encyclopaedia Britannica",
    "coverage_limits" => "Work-specific reference support only",
    "extraction_method" => "Targeted X070 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Confirms All Fires the Fire, and Other Stories / Todos los fuegos el fuego as short stories by Cortazar."
  },
  {
    "source_id" => "x070_balcells_all_fires_fire_reference",
    "source_title" => "Agencia Literaria Carmen Balcells: Todos los fuegos el fuego",
    "source_type" => "publisher_reference_series",
    "source_scope" => "Author-agency work page for Todos los fuegos el fuego / All Fires the Fire",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Agencia Literaria Carmen Balcells, Todos los fuegos el fuego / All Fires the Fire, https://www.agenciabalcells.com/en/authors/works/julio-cortazar/todos-los-fuegos-el-fuego/",
    "edition" => "online rights/work page",
    "editors_or_authors" => "Agencia Literaria Carmen Balcells",
    "publisher" => "Agencia Literaria Carmen Balcells",
    "coverage_limits" => "Rights/agency work page; supports title, creator, form, year, and contents",
    "extraction_method" => "Targeted X070 public publisher/rights review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Identifies Todos los fuegos el fuego / All Fires the Fire as a 1966 Cortazar short-story collection."
  },
  {
    "source_id" => "x070_encyclopedia_com_blow_up_reference",
    "source_title" => "Encyclopedia.com: Blow-Up and Other Stories",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "World Literature and Its Times entry for Blow-Up and Other Stories",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopedia.com, Blow-Up and Other Stories, https://www.encyclopedia.com/arts/culture-magazines/blow-and-other-stories",
    "edition" => "online reference entry",
    "editors_or_authors" => "Gale / World Literature and Its Times",
    "publisher" => "Encyclopedia.com / Gale",
    "coverage_limits" => "Work-specific reference entry; supports collection identity and reception",
    "extraction_method" => "Targeted X070 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Identifies Blow-Up and Other Stories as a Cortazar short-story collection."
  },
  {
    "source_id" => "x070_penguin_random_house_blow_up_reference",
    "source_title" => "Penguin Random House: Blow-Up",
    "source_type" => "publisher_reference_series",
    "source_scope" => "Official Penguin Random House page for Blow-Up: And Other Stories",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Penguin Random House, Blow-Up by Julio Cortazar, https://www.penguinrandomhouse.com/books/32198/blow-up-by-julio-cortazar/",
    "edition" => "Pantheon paperback listing",
    "editors_or_authors" => "Julio Cortazar",
    "publisher" => "Penguin Random House / Pantheon",
    "coverage_limits" => "Publisher page; supports current English collection title and contents",
    "extraction_method" => "Targeted X070 public publisher review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Official publisher page identifies Blow-Up: And Other Stories and lists the collection details."
  },
  {
    "source_id" => "x070_poetry_foundation_primo_levi_reference",
    "source_title" => "Poetry Foundation: Primo Levi",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Poetry Foundation biography with work-specific Collected Poems: Primo Levi discussion",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Poetry Foundation, Primo Levi, https://www.poetryfoundation.org/poets/primo-levi",
    "edition" => "online poet biography",
    "editors_or_authors" => "Poetry Foundation",
    "publisher" => "Poetry Foundation",
    "coverage_limits" => "Author biography; supports work-specific poetry collection identity",
    "extraction_method" => "Targeted X070 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Identifies Collected Poems: Primo Levi and its translated collection scope."
  },
  {
    "source_id" => "x070_los_angeles_times_primo_levi_collected_poems_review",
    "source_title" => "Los Angeles Times: The Blackness and Radiance of Primo Levi",
    "source_type" => "prize_or_reception_layer",
    "source_scope" => "Los Angeles Times review/reference to Primo Levi's Collected Poems",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Richard Eder, The Blackness and Radiance of Primo Levi, Los Angeles Times, 1988-12-18, https://www.latimes.com/archives/la-xpm-1988-12-18-bk-981-story.html",
    "edition" => "newspaper review",
    "editors_or_authors" => "Richard Eder",
    "publisher" => "Los Angeles Times",
    "coverage_limits" => "Reception/review evidence; supports edition identity, not broad canon rank by itself",
    "extraction_method" => "Targeted X070 public review/reception review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "References Collected Poems translated by Ruth Feldman and Brian Swann and published by Faber and Faber."
  },
  {
    "source_id" => "x070_nobel_milosz_bibliography_reference",
    "source_title" => "Nobel Prize: Czeslaw Milosz Bibliography",
    "source_type" => "prize_or_reception_layer",
    "source_scope" => "Nobel Prize bibliography listing multiple Milosz Selected Poems editions",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "NobelPrize.org, Czeslaw Milosz Bibliography, https://www.nobelprize.org/prizes/literature/1980/milosz/bibliography/",
    "edition" => "online laureate bibliography",
    "editors_or_authors" => "Nobel Prize Outreach",
    "publisher" => "Nobel Prize Outreach",
    "coverage_limits" => "Reception/bibliographic layer; exact selected-poems support",
    "extraction_method" => "Targeted X070 public Nobel bibliography review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Lists Selected Poems editions including 1968, 1973, and Selected Poems 1931-2004."
  },
  {
    "source_id" => "x070_washington_post_milosz_selected_poems_review",
    "source_title" => "Washington Post: Czeslaw Milosz and the Laurels of Literature",
    "source_type" => "prize_or_reception_layer",
    "source_scope" => "Washington Post review discussion of Milosz's Selected Poems",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Czeslaw Milosz And the Laurels Of Literature, Washington Post, 1981-06-14, https://www.washingtonpost.com/archive/entertainment/books/1981/06/14/czeslaw-milosz-and-the-laurels-of-literature/652bcf28-046e-44e3-9c16-1b63f5fe230f/",
    "edition" => "newspaper review",
    "editors_or_authors" => "Washington Post",
    "publisher" => "Washington Post",
    "coverage_limits" => "Reception/review evidence; supports selected-poems identity and English reception",
    "extraction_method" => "Targeted X070 public review/reception review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Discusses Selected Poems as the representative English collection available after the Nobel award."
  },
  {
    "source_id" => "x070_poetry_foundation_hikmet_selected_poems_reference",
    "source_title" => "Poetry Foundation: Nazim Hikmet",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Poetry Foundation biography listing Hikmet's Selected Poems",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Poetry Foundation, Nazim Hikmet, https://www.poetryfoundation.org/poets/nazim-hikmet",
    "edition" => "online poet biography",
    "editors_or_authors" => "Poetry Foundation",
    "publisher" => "Poetry Foundation",
    "coverage_limits" => "Author biography; supports selected-poems translation identity",
    "extraction_method" => "Targeted X070 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Lists Selected Poems (1967; translated by Taner Baybars) among Hikmet's English translations."
  },
  {
    "source_id" => "x070_encyclopedia_com_taner_baybars_hikmet_reference",
    "source_title" => "Encyclopedia.com: Baybars, Taner",
    "source_type" => "reference_encyclopedia",
    "source_scope" => "Reference entry for Taner Baybars listing his translation of Selected Poems of Nazim Hikmet",
    "source_date" => "accessed 2026-05-04",
    "source_citation" => "Encyclopedia.com, Baybars, Taner, https://www.encyclopedia.com/arts/culture-magazines/baybars-taner",
    "edition" => "online reference entry",
    "editors_or_authors" => "Encyclopedia.com",
    "publisher" => "Encyclopedia.com / Gale",
    "coverage_limits" => "Translator bibliography; exact title support but indirect for Hikmet's current selected-poems row",
    "extraction_method" => "Targeted X070 public reference review",
    "packet_ids" => PACKET_ID,
    "extraction_status" => "extracted",
    "notes" => "Lists Baybars as translator of Selected Poems of Nazim Hikmet, London: Cape, 1967."
  }
].freeze

SOURCE_ITEM_ROWS = [
  {
    "source_id" => "x070_britannica_bradstreet_tenth_muse_reference",
    "source_item_id" => "x070_britannica_bradstreet_tenth_muse",
    "raw_title" => "The Tenth Muse Lately Sprung Up in America",
    "raw_creator" => "Anne Bradstreet",
    "raw_date" => "1650",
    "source_rank" => "",
    "source_section" => "The Tenth Muse Lately Sprung Up in America entry",
    "source_url" => "https://www.britannica.com/topic/The-Tenth-Muse-Lately-Sprung-Up-in-America",
    "source_citation" => "Encyclopaedia Britannica, The Tenth Muse Lately Sprung Up in America",
    "matched_work_id" => "work_candidate_mandatory_bradstreet_tenth_muse",
    "match_method" => "x070_exact_work_specific_public_reference",
    "match_confidence" => "0.98",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_complete_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as external complete-work support; does not validate individual anthology poem membership."
  },
  {
    "source_id" => "x070_poetry_foundation_bradstreet_tenth_muse_reference",
    "source_item_id" => "x070_poetry_foundation_bradstreet_tenth_muse",
    "raw_title" => "The Tenth Muse Lately Sprung Up in America",
    "raw_creator" => "Anne Bradstreet",
    "raw_date" => "1650",
    "source_rank" => "",
    "source_section" => "Anne Bradstreet biography",
    "source_url" => "https://www.poetryfoundation.org/poets/anne-bradstreet",
    "source_citation" => "Poetry Foundation, Anne Bradstreet",
    "matched_work_id" => "work_candidate_mandatory_bradstreet_tenth_muse",
    "match_method" => "x070_exact_work_specific_public_reference",
    "match_confidence" => "0.96",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_complete_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as independent external complete-work support; component rows remain blocked unless exact membership is sourced."
  },
  {
    "source_id" => "x070_macmillan_walcott_collected_poems_reference",
    "source_item_id" => "x070_macmillan_walcott_collected_poems_1948_1984",
    "raw_title" => "Collected Poems, 1948-1984",
    "raw_creator" => "Derek Walcott",
    "raw_date" => "1986",
    "source_rank" => "",
    "source_section" => "Collected Poems, 1948-1984 product page",
    "source_url" => "https://us.macmillan.com/books/9780374520250/collectedpoems19481984/",
    "source_citation" => "Macmillan, Collected Poems, 1948-1984",
    "matched_work_id" => "work_candidate_latcarib_lit_walcott_collected_poems",
    "match_method" => "x070_exact_work_specific_publisher_reference",
    "match_confidence" => "0.99",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_publisher_complete_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as external collection support; Longman poem rows remain selection-only at most."
  },
  {
    "source_id" => "x070_nobel_walcott_bibliography_reference",
    "source_item_id" => "x070_nobel_walcott_collected_poems_1948_1984",
    "raw_title" => "Collected Poems 1948-1984",
    "raw_creator" => "Derek Walcott",
    "raw_date" => "1986",
    "source_rank" => "",
    "source_section" => "Derek Walcott bibliography",
    "source_url" => "https://www.nobelprize.org/prizes/literature/1992/walcott/bibliography/",
    "source_citation" => "NobelPrize.org, Derek Walcott Bibliography",
    "matched_work_id" => "work_candidate_latcarib_lit_walcott_collected_poems",
    "match_method" => "x070_exact_work_specific_reception_bibliography",
    "match_confidence" => "0.98",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.35",
    "supports" => "work_specific_reception_bibliography_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as independent Nobel bibliography support for the collection."
  },
  {
    "source_id" => "x070_britannica_all_fires_fire_reference",
    "source_item_id" => "x070_britannica_all_fires_fire",
    "raw_title" => "All Fires the Fire, and Other Stories",
    "raw_creator" => "Julio Cortazar",
    "raw_date" => "1966",
    "source_rank" => "",
    "source_section" => "All Fires the Fire, and Other Stories entry",
    "source_url" => "https://www.britannica.com/topic/All-Fires-the-Fire-and-Other-Stories",
    "source_citation" => "Encyclopaedia Britannica, All Fires the Fire, and Other Stories",
    "matched_work_id" => "work_candidate_latcarib_lit_all_fires_fire",
    "match_method" => "x070_exact_work_specific_public_reference_alias",
    "match_confidence" => "0.97",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as external collection support; poem-level Cortazar source items remain wrong-form support for this incumbent."
  },
  {
    "source_id" => "x070_balcells_all_fires_fire_reference",
    "source_item_id" => "x070_balcells_todos_los_fuegos_el_fuego",
    "raw_title" => "Todos los fuegos el fuego / All Fires the Fire",
    "raw_creator" => "Julio Cortazar",
    "raw_date" => "1966",
    "source_rank" => "",
    "source_section" => "Todos los fuegos el fuego / All Fires the Fire work page",
    "source_url" => "https://www.agenciabalcells.com/en/authors/works/julio-cortazar/todos-los-fuegos-el-fuego/",
    "source_citation" => "Agencia Literaria Carmen Balcells, Todos los fuegos el fuego / All Fires the Fire",
    "matched_work_id" => "work_candidate_latcarib_lit_all_fires_fire",
    "match_method" => "x070_exact_work_specific_publisher_reference_alias",
    "match_confidence" => "0.98",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_publisher_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as independent collection support for the Spanish title and English alias."
  },
  {
    "source_id" => "x070_encyclopedia_com_blow_up_reference",
    "source_item_id" => "x070_encyclopedia_com_blow_up_and_other_stories",
    "raw_title" => "Blow-Up and Other Stories",
    "raw_creator" => "Julio Cortazar",
    "raw_date" => "1968",
    "source_rank" => "",
    "source_section" => "Blow-Up and Other Stories entry",
    "source_url" => "https://www.encyclopedia.com/arts/culture-magazines/blow-and-other-stories",
    "source_citation" => "Encyclopedia.com, Blow-Up and Other Stories",
    "matched_work_id" => "work_candidate_latcarib_lit_blow_up",
    "match_method" => "x070_exact_work_specific_public_reference",
    "match_confidence" => "0.98",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as external collection support; it does not use the wrong-form poem source item."
  },
  {
    "source_id" => "x070_penguin_random_house_blow_up_reference",
    "source_item_id" => "x070_penguin_random_house_blow_up_and_other_stories",
    "raw_title" => "Blow-Up: And Other Stories",
    "raw_creator" => "Julio Cortazar",
    "raw_date" => "1985",
    "source_rank" => "",
    "source_section" => "Blow-Up product page",
    "source_url" => "https://www.penguinrandomhouse.com/books/32198/blow-up-by-julio-cortazar/",
    "source_citation" => "Penguin Random House, Blow-Up by Julio Cortazar",
    "matched_work_id" => "work_candidate_latcarib_lit_blow_up",
    "match_method" => "x070_exact_work_specific_publisher_reference",
    "match_confidence" => "0.96",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_publisher_short_story_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as independent publisher support; publisher page also lists Axolotl in the table of contents."
  },
  {
    "source_id" => "x070_poetry_foundation_primo_levi_reference",
    "source_item_id" => "x070_poetry_foundation_primo_levi_collected_poems",
    "raw_title" => "Collected Poems: Primo Levi",
    "raw_creator" => "Primo Levi",
    "raw_date" => "1988",
    "source_rank" => "",
    "source_section" => "Primo Levi biography",
    "source_url" => "https://www.poetryfoundation.org/poets/primo-levi",
    "source_citation" => "Poetry Foundation, Primo Levi",
    "matched_work_id" => "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0835_collected_poems",
    "match_method" => "x070_exact_work_specific_public_reference",
    "match_confidence" => "0.96",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_poetry_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as external collection support; The Two Flags row remains blocked as a component mismatch."
  },
  {
    "source_id" => "x070_los_angeles_times_primo_levi_collected_poems_review",
    "source_item_id" => "x070_latimes_primo_levi_collected_poems",
    "raw_title" => "Collected Poems",
    "raw_creator" => "Primo Levi",
    "raw_date" => "1988",
    "source_rank" => "",
    "source_section" => "The Blackness and Radiance of Primo Levi",
    "source_url" => "https://www.latimes.com/archives/la-xpm-1988-12-18-bk-981-story.html",
    "source_citation" => "Richard Eder, The Blackness and Radiance of Primo Levi, Los Angeles Times",
    "matched_work_id" => "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0835_collected_poems",
    "match_method" => "x070_exact_work_specific_reception_review",
    "match_confidence" => "0.92",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.35",
    "supports" => "work_specific_reception_poetry_collection_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as independent reception support for Levi's Collected Poems edition."
  },
  {
    "source_id" => "x070_nobel_milosz_bibliography_reference",
    "source_item_id" => "x070_nobel_milosz_selected_poems",
    "raw_title" => "Selected Poems",
    "raw_creator" => "Czeslaw Milosz",
    "raw_date" => "1973",
    "source_rank" => "",
    "source_section" => "Czeslaw Milosz bibliography",
    "source_url" => "https://www.nobelprize.org/prizes/literature/1980/milosz/bibliography/",
    "source_citation" => "NobelPrize.org, Czeslaw Milosz Bibliography",
    "matched_work_id" => "work_candidate_completion_lit_selected_poems_milosz",
    "match_method" => "x070_exact_selected_work_reception_bibliography",
    "match_confidence" => "0.94",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.35",
    "supports" => "work_specific_reception_selected_poems_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as external selected-work support; Child of Europe can remain only selection/component evidence if separately verified."
  },
  {
    "source_id" => "x070_washington_post_milosz_selected_poems_review",
    "source_item_id" => "x070_washington_post_milosz_selected_poems",
    "raw_title" => "Selected Poems",
    "raw_creator" => "Czeslaw Milosz",
    "raw_date" => "1980",
    "source_rank" => "",
    "source_section" => "Czeslaw Milosz and the Laurels of Literature",
    "source_url" => "https://www.washingtonpost.com/archive/entertainment/books/1981/06/14/czeslaw-milosz-and-the-laurels-of-literature/652bcf28-046e-44e3-9c16-1b63f5fe230f/",
    "source_citation" => "Czeslaw Milosz And the Laurels Of Literature, Washington Post",
    "matched_work_id" => "work_candidate_completion_lit_selected_poems_milosz",
    "match_method" => "x070_exact_selected_work_reception_review",
    "match_confidence" => "0.92",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.35",
    "supports" => "work_specific_reception_selected_poems_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as independent review support for the Selected Poems scope."
  },
  {
    "source_id" => "x070_poetry_foundation_hikmet_selected_poems_reference",
    "source_item_id" => "x070_poetry_foundation_hikmet_selected_poems",
    "raw_title" => "Selected Poems",
    "raw_creator" => "Nazim Hikmet",
    "raw_date" => "1967",
    "source_rank" => "",
    "source_section" => "Nazim Hikmet biography",
    "source_url" => "https://www.poetryfoundation.org/poets/nazim-hikmet",
    "source_citation" => "Poetry Foundation, Nazim Hikmet",
    "matched_work_id" => "work_candidate_global_lit_nazim_hikmet_poems",
    "match_method" => "x070_exact_selected_work_public_reference",
    "match_confidence" => "0.94",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.55",
    "supports" => "work_specific_reference_selected_poems_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as external selected-work support; Regarding Art remains blocked as local component evidence."
  },
  {
    "source_id" => "x070_encyclopedia_com_taner_baybars_hikmet_reference",
    "source_item_id" => "x070_encyclopedia_com_hikmet_selected_poems_baybars",
    "raw_title" => "Selected Poems of Nazim Hikmet",
    "raw_creator" => "Nazim Hikmet; Taner Baybars",
    "raw_date" => "1967",
    "source_rank" => "",
    "source_section" => "Baybars, Taner entry",
    "source_url" => "https://www.encyclopedia.com/arts/culture-magazines/baybars-taner",
    "source_citation" => "Encyclopedia.com, Baybars, Taner",
    "matched_work_id" => "work_candidate_global_lit_nazim_hikmet_poems",
    "match_method" => "x070_selected_work_translator_reference",
    "match_confidence" => "0.88",
    "evidence_type" => "inclusion",
    "evidence_weight" => "0.45",
    "supports" => "translator_bibliography_selected_poems_support",
    "match_status" => "matched_current_path",
    "notes" => "X070 accepted as indirect but exact external support for the 1967 Selected Poems; no component-form support is inferred."
  }
].freeze

EVIDENCE_ROWS = SOURCE_ITEM_ROWS.map do |row|
  {
    "evidence_id" => "x070_ev_#{row.fetch("source_item_id").sub(/\Ax070_/, "")}",
    "work_id" => row.fetch("matched_work_id"),
    "source_id" => row.fetch("source_id"),
    "source_item_id" => row.fetch("source_item_id"),
    "evidence_type" => "inclusion",
    "evidence_strength" => row.fetch("evidence_weight").to_f >= 0.55 ? "moderate" : "weak",
    "page_or_section" => row.fetch("source_section"),
    "quote_or_note" => "",
    "packet_id" => PACKET_ID,
    "supports_tier" => "",
    "supports_boundary_policy_id" => "",
    "reviewer_status" => "accepted",
    "notes" => "X070 accepted targeted public source support for current high-risk blocker resolution; not a cut approval or public-canon replacement."
  }
end.freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def tsv_headers(path)
  CSV.open(path, col_sep: "\t", &:readline)
end

def write_tsv(path, headers, rows, sort_key: nil)
  FileUtils.mkdir_p(File.dirname(path))
  rows = rows.sort_by { |row| row.fetch(sort_key).to_s } if sort_key
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def upsert_rows(existing_rows, new_rows, key)
  by_key = existing_rows.each_with_object({}) { |row, memo| memo[row.fetch(key)] = row }
  new_rows.each { |row| by_key[row.fetch(key)] = row }
  by_key.values
end

def count_by(rows, key)
  rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch(key)] += 1 }
end

def refresh_downstream!
  DOWNSTREAM_SCRIPTS.each do |script|
    ok = system("ruby", File.join(ROOT, script))
    raise "Downstream refresh failed at #{script}" unless ok
  end
end

def update_packet_status(row)
  rows = File.exist?(PACKET_STATUS_PATH) ? read_tsv(PACKET_STATUS_PATH) : []
  rows.reject! { |existing| existing.fetch("packet_id") == PACKET_ID }
  rows << row
  write_tsv(PACKET_STATUS_PATH, PACKET_STATUS_HEADERS, rows, sort_key: "packet_id")
end

def update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows)
  return unless File.exist?(MANIFEST_PATH)

  manifest = YAML.load_file(MANIFEST_PATH)
  artifacts = manifest.fetch("artifacts")
  counts = manifest.fetch("current_counts")
  source_item_rows = read_tsv(SOURCE_ITEMS_PATH)
  scoring_input_rows = read_tsv(File.join(TABLE_DIR, "canon_scoring_inputs.tsv"))

  manifest["status"] = "targeted_external_source_rescue_x070_applied"
  artifacts["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_x025_x026_x027_x036_x043_x064_x066_x067_x068_and_x070_source_items"
  artifacts["evidence"] = "e001_ingested_x001_x006_pilot_plus_x017_policy_aware_rows_after_x043_plus_x058_x062_x066_x067_x068_representative_selection_x064_complete_work_support_and_x070_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x070_targeted_external_source_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x070_targeted_external_source_rescue"
  artifacts["scores"] = "regenerated_x070_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x070_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x070_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x070_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x070_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x070_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x070_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x070"] = "generated_x070_from_x069_work_resolution_blockers"
  counts["source_registry_rows"] = read_tsv(SOURCE_REGISTRY_PATH).size
  counts["source_items"] = source_item_rows.size
  counts["evidence_rows"] = read_tsv(EVIDENCE_PATH).size
  counts["source_debt_status_rows"] = source_debt_after.size
  counts["scoring_input_rows"] = scoring_input_rows.size
  counts["scoring_ready_rows"] = scoring_input_rows.count { |row| row.fetch("scoring_readiness") == "ready_for_score_computation" }
  counts["scoring_blocked_rows"] = scoring_input_rows.count { |row| row.fetch("scoring_readiness") == "blocked_from_score_computation" }
  counts["score_rows"] = read_tsv(File.join(TABLE_DIR, "canon_scores.tsv")).size
  counts["replacement_candidate_rows"] = read_tsv(File.join(TABLE_DIR, "canon_replacement_candidates.tsv")).size
  counts["replacement_pair_review_queue_rows"] = read_tsv(File.join(TABLE_DIR, "canon_replacement_pair_review_queue.tsv")).size
  counts["cut_review_work_order_rows"] = read_tsv(File.join(TABLE_DIR, "canon_cut_review_work_orders.tsv")).size
  counts["generic_selection_basis_review_rows"] = read_tsv(File.join(TABLE_DIR, "canon_generic_selection_basis_review.tsv")).size
  counts["cut_side_post_x058_action_queue_rows"] = read_tsv(ACTION_QUEUE_PATH).size
  counts["current_rescue_scope_review_rows"] = read_tsv(SCOPE_REVIEW_PATH).size
  counts["high_risk_rescue_residue_rows"] = read_tsv(HIGH_RISK_RESIDUE_PATH).size
  counts["cut_candidate_rows"] = read_tsv(File.join(TABLE_DIR, "canon_cut_candidates.tsv")).size
  counts["source_items_matched_current_path"] = source_item_rows.count { |row| row.fetch("match_status") == "matched_current_path" }
  counts["source_items_matched_candidate"] = source_item_rows.count { |row| row.fetch("match_status") == "matched_candidate" }
  counts["source_items_represented_by_selection"] = source_item_rows.count { |row| row.fetch("match_status") == "represented_by_selection" }
  counts["source_items_out_of_scope"] = source_item_rows.count { |row| row.fetch("match_status") == "out_of_scope" }
  counts["source_items_unmatched"] = source_item_rows.count { |row| row.fetch("match_status") == "unmatched" }
  counts["x070_external_source_rescue_rows"] = applied_rows.size
  counts["x070_target_works_closed"] = TARGET_WORKS.count do |work_id|
    !source_debt_after.fetch(work_id).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x070"] = high_risk_rows.size

  manifest["targeted_external_source_rescue_x070"] = {
    "status" => "applied_targeted_public_sources_for_x069_blockers",
    "target_work_rows" => TARGET_WORKS.size,
    "source_registry_rows_added_or_updated" => REGISTRY_ROWS.size,
    "source_item_rows_added_or_updated" => SOURCE_ITEM_ROWS.size,
    "evidence_rows_added_or_updated" => EVIDENCE_ROWS.size,
    "target_works_closed_after_refresh" => counts["x070_target_works_closed"],
    "lane_counts_after_refresh" => lane_counts,
    "current_high_risk_residue_rows_after_refresh" => high_risk_rows.size,
    "direct_replacements" => 0
  }

  File.write(MANIFEST_PATH, manifest.to_yaml)
end

def write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)
  FileUtils.mkdir_p(File.dirname(REPORT_PATH))
  closed_target_count = TARGET_WORKS.count do |work_id|
    !source_debt_after.fetch(work_id).fetch("source_debt_status").start_with?("open_")
  end
  work_rows = applied_rows.group_by { |row| row.fetch("work_id") }.sort.map do |work_id, rows|
    [work_id, rows, source_debt_after.fetch(work_id).fetch("source_debt_status")]
  end

  File.open(REPORT_PATH, "w") do |file|
    file.puts "# X070 Targeted External Source Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X070 applies targeted public source support for the seven X069 high-risk work blockers. It deliberately avoids promoting the unsafe local component rows: the new evidence is work-level external support only."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_apply_targeted_external_source_rescue_x070.rb`."
    file.puts "- Added `canon_external_source_rescue_evidence_applied_x070.tsv`."
    file.puts "- Added or updated #{REGISTRY_ROWS.size} source-registry rows, #{SOURCE_ITEM_ROWS.size} source-item rows, and #{EVIDENCE_ROWS.size} accepted evidence rows."
    file.puts "- Refreshed source-debt, scoring, cut-side, current-scope, and high-risk residue tables."
    file.puts
    file.puts "Target closure summary: #{closed_target_count} of #{TARGET_WORKS.size} X069 target works no longer have open source debt after refresh."
    file.puts
    file.puts "Work summary:"
    file.puts
    file.puts "| Work | Evidence rows | Source debt after X070 |"
    file.puts "|---|---:|---|"
    work_rows.each do |work_id, rows, status|
      file.puts "| `#{work_id}` | #{rows.size} | `#{status}` |"
    end
    file.puts
    file.puts "Cut-side lane summary after refresh:"
    file.puts
    file.puts "| Lane | Rows |"
    file.puts "|---|---:|"
    lane_counts.sort.each { |lane, count| file.puts "| `#{lane}` | #{count} |" }
    file.puts
    file.puts "Current high-risk residue after refresh: #{high_risk_rows.size}."
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "X070 clears the seven-work X069 target set by replacing unsafe component-level support with external work-level support. The refreshed current lane now exposes the next unresolved source-rescue cluster; this packet does not approve any cut or public replacement."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

source_debt_before = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }

registry_rows = upsert_rows(read_tsv(SOURCE_REGISTRY_PATH), REGISTRY_ROWS, "source_id")
source_item_rows = upsert_rows(read_tsv(SOURCE_ITEMS_PATH), SOURCE_ITEM_ROWS, "source_item_id")
evidence_rows = upsert_rows(read_tsv(EVIDENCE_PATH), EVIDENCE_ROWS, "evidence_id")

write_tsv(SOURCE_REGISTRY_PATH, tsv_headers(SOURCE_REGISTRY_PATH), registry_rows, sort_key: "source_id")
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_item_rows)
write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_rows)

refresh_downstream!

source_debt_after = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
actions_by_work = read_tsv(ACTION_QUEUE_PATH).to_h { |row| [row.fetch("cut_work_id"), row] }
lane_counts = read_tsv(ACTION_QUEUE_PATH).each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("current_lane")] += 1 }
high_risk_rows = read_tsv(HIGH_RISK_RESIDUE_PATH).select { |row| row.fetch("residue_status") == "current_high_risk_scope_blocker" }
source_type_by_id = REGISTRY_ROWS.to_h { |row| [row.fetch("source_id"), row.fetch("source_type")] }

applied_rows = EVIDENCE_ROWS.map.with_index(1) do |evidence, index|
  source_item = SOURCE_ITEM_ROWS.find { |row| row.fetch("source_item_id") == evidence.fetch("source_item_id") }
  work_id = evidence.fetch("work_id")
  before_status = source_debt_before.fetch(work_id).fetch("source_debt_status")
  after_status = source_debt_after.fetch(work_id).fetch("source_debt_status")
  action_lane = actions_by_work[work_id]&.fetch("current_lane").to_s
  resolution_status =
    if !after_status.start_with?("open_")
      "source_debt_closed_after_external_support"
    elsif after_status != before_status
      "source_debt_partially_improved"
    else
      "source_debt_still_open_after_external_support"
    end

  {
    "applied_id" => "x070_external_source_rescue_#{index.to_s.rjust(4, "0")}",
    "work_id" => work_id,
    "title" => source_item.fetch("raw_title"),
    "creator" => source_item.fetch("raw_creator"),
    "source_id" => evidence.fetch("source_id"),
    "source_item_id" => evidence.fetch("source_item_id"),
    "evidence_id" => evidence.fetch("evidence_id"),
    "source_type" => source_type_by_id.fetch(evidence.fetch("source_id")),
    "evidence_type" => evidence.fetch("evidence_type"),
    "evidence_strength" => evidence.fetch("evidence_strength"),
    "reviewer_status" => evidence.fetch("reviewer_status"),
    "source_debt_status_before" => before_status,
    "source_debt_status_after" => after_status,
    "action_lane_after" => action_lane,
    "resolution_status" => resolution_status,
    "next_action" => action_lane.empty? ? "review_cut_side_scoring_after_refresh" : actions_by_work.fetch(work_id).fetch("next_action"),
    "rationale" => "External work-level source support added; unsafe local high-risk component row was not promoted."
  }
end

write_tsv(APPLIED_PATH, APPLIED_HEADERS, applied_rows)

closed_target_count = TARGET_WORKS.count do |work_id|
  !source_debt_after.fetch(work_id).fetch("source_debt_status").start_with?("open_")
end

update_packet_status(
  {
    "packet_id" => PACKET_ID,
    "packet_family" => "X",
    "scope" => "targeted external source rescue for X069 high-risk blockers",
    "status" => "targeted_external_source_rescue_applied",
    "gate" => "cut_and_replacement_review_still_required",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x070.tsv",
      "scripts/canon_apply_targeted_external_source_rescue_x070.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_054_x070_targeted_external_source_rescue.md"
    ].join(";"),
    "next_action" => "review_cut_side_source_debt_closed_rows_and_continue_external_acquisition_queue",
    "notes" => "#{EVIDENCE_ROWS.size} accepted external evidence rows applied for #{TARGET_WORKS.size} X069 target works; #{closed_target_count} target source debts closed after refresh; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X070 targeted external source evidence rows"
puts "closed target source debts: #{closed_target_count}/#{TARGET_WORKS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
