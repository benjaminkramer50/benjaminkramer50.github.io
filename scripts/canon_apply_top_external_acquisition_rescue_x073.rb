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

PACKET_ID = "X073"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x073.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_057_x073_top_external_acquisition_rescue.md")

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

TARGETS = [
  {
    work_id: "work_candidate_bloom_pindar_odes",
    title: "Odes",
    creator: "Pindar",
    raw_date: "5th century BCE",
    rationale: "External reference support confirms Pindar's extant victory odes as the current-path reading scope.",
    sources: [
      {
        source_id: "x073_britannica_pindar_reference",
        source_title: "Britannica: Pindar",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica author entry for Pindar with work-specific discussion of the surviving odes",
        source_citation: "Encyclopaedia Britannica, Pindar, https://www.britannica.com/biography/Pindar",
        edition: "online reference entry",
        editors_or_authors: "Donald Ernest Wilson Wormell / Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Author reference with work-specific discussion of Pindar's extant epinician odes",
        source_section: "Pindar biography and professional career",
        source_url: "https://www.britannica.com/biography/Pindar",
        match_method: "x073_author_reference_surviving_odes_scope",
        evidence_weight: "0.55",
        supports: "reference_support_for_pindar_odes_scope",
        notes: "Confirms Pindar's status as master of choral odes and discusses the surviving Olympic, Pythian, Isthmian, and Nemean odes."
      },
      {
        source_id: "x073_poetry_foundation_pindar_reference",
        source_title: "Poetry Foundation: Pindar",
        source_type: "reference_encyclopedia",
        source_scope: "Poetry Foundation poet profile for Pindar with complete-ode survival and reading-scope context",
        source_citation: "Poetry Foundation, Pindar, https://www.poetryfoundation.org/poets/pindar",
        edition: "online poet reference page",
        editors_or_authors: "Poetry Foundation",
        publisher: "Poetry Foundation",
        coverage_limits: "Poet reference page; supports the survival and standard reading frame for the odes",
        source_section: "Pindar profile",
        source_url: "https://www.poetryfoundation.org/poets/pindar",
        match_method: "x073_poetry_foundation_pindar_odes_reference",
        evidence_weight: "0.55",
        supports: "poet_reference_support_for_pindar_odes",
        notes: "Identifies the 45 surviving victory odes and links the title Pindar: The Complete Odes."
      },
      {
        source_id: "x073_ucpress_pindar_odes_reference",
        source_title: "University of California Press: The Odes",
        source_type: "publisher_reference_series",
        source_scope: "University press page for Andrew M. Miller's translation of Pindar's Odes",
        source_citation: "University of California Press, The Odes, https://www.ucpress.edu/books/the-odes/epub-pdf",
        edition: "publisher edition page",
        editors_or_authors: "Pindar; translated by Andrew M. Miller",
        publisher: "University of California Press",
        coverage_limits: "Edition/reception support for the current titled scope",
        source_section: "The Odes book page",
        source_url: "https://www.ucpress.edu/books/the-odes/epub-pdf",
        match_method: "x073_publisher_edition_odes_scope",
        evidence_weight: "0.35",
        supports: "edition_support_for_pindar_odes",
        notes: "University press edition presents the surviving victory odes under the title The Odes."
      }
    ]
  },
  {
    work_id: "work_candidate_bloom_reviewed_callimachus_hymns",
    title: "Hymns and Epigrams",
    creator: "Callimachus",
    raw_date: "3rd century BCE",
    rationale: "External reference and Loeb edition support the exact current title scope.",
    sources: [
      {
        source_id: "x073_britannica_callimachus_hymns_epigrams_reference",
        source_title: "Britannica: Callimachus",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica author entry discussing Callimachus's surviving hymns and epigrams",
        source_citation: "Encyclopaedia Britannica, Callimachus, https://www.britannica.com/biography/Callimachus-Greek-poet-and-scholar",
        edition: "online reference entry",
        editors_or_authors: "Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Author reference with work-specific surviving-work discussion",
        source_section: "Callimachus biography",
        source_url: "https://www.britannica.com/biography/Callimachus-Greek-poet-and-scholar",
        match_method: "x073_reference_surviving_hymns_epigrams_scope",
        evidence_weight: "0.55",
        supports: "reference_support_for_callimachus_hymns_epigrams",
        notes: "Confirms that only six hymns, about 60 epigrams, and fragments survive; discusses Hymns and Epigrams as literary works."
      },
      {
        source_id: "x073_britannica_callimachus_hymns_work_reference",
        source_title: "Britannica: Hymns by Callimachus",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica work page for Callimachus's Hymns with Epigrams context",
        source_citation: "Encyclopaedia Britannica, Hymns, https://www.britannica.com/topic/Hymns-by-Callimachus",
        edition: "online work reference entry",
        editors_or_authors: "Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Work-specific reference support for the Hymns; also notes the Epigrams",
        source_section: "Hymns work page",
        source_url: "https://www.britannica.com/topic/Hymns-by-Callimachus",
        match_method: "x073_work_reference_hymns_epigrams_scope",
        evidence_weight: "0.55",
        supports: "work_reference_support_for_callimachus_hymns_epigrams",
        notes: "Discusses the Hymns and states that the Epigrams treat personal themes with artistry."
      },
      {
        source_id: "x073_loeb_callimachus_hymns_epigrams_reference",
        source_title: "Loeb Classical Library: Hecale. Hymns. Epigrams",
        source_type: "scholarly_edition_series",
        source_scope: "Loeb Classical Library / Harvard University Press edition of Callimachus, Hecale, Hymns, and Epigrams",
        source_citation: "Loeb Classical Library, Hecale. Hymns. Epigrams, Harvard University Press, https://mitpressbookstore.mit.edu/book/9780674997332",
        edition: "Loeb Classical Library edition page",
        editors_or_authors: "Callimachus; edited and translated by Dee L. Clayman",
        publisher: "Harvard University Press / Loeb Classical Library",
        coverage_limits: "Authoritative edition support for the exact title scope",
        source_section: "Hecale. Hymns. Epigrams book page",
        source_url: "https://mitpressbookstore.mit.edu/book/9780674997332",
        match_method: "x073_loeb_exact_hymns_epigrams_edition",
        evidence_weight: "0.35",
        supports: "scholarly_edition_support_for_callimachus_hymns_epigrams",
        notes: "Loeb volume II contains Hecale, Hymns, and Epigrams."
      }
    ]
  },
  {
    work_id: "work_candidate_bloom_martial_epigrams",
    title: "Epigrams",
    creator: "Martial",
    raw_date: "late 1st century CE",
    rationale: "External reference support confirms the twelve-book Epigrams as Martial's canonical reading scope.",
    sources: [
      {
        source_id: "x073_britannica_martial_epigrams_reference",
        source_title: "Britannica: Martial",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica author entry for Martial with publication history of the Epigrams",
        source_citation: "Encyclopaedia Britannica, Martial, https://www.britannica.com/biography/Martial-Roman-poet",
        edition: "online reference entry",
        editors_or_authors: "Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Author reference with work-specific publication and reception discussion",
        source_section: "Martial biography: Poetry",
        source_url: "https://www.britannica.com/biography/Martial-Roman-poet",
        match_method: "x073_reference_martial_epigrams_scope",
        evidence_weight: "0.55",
        supports: "reference_support_for_martial_epigrams",
        notes: "Confirms the twelve books of Epigrams and Martial's role in the epigram tradition."
      },
      {
        source_id: "x073_poetry_foundation_martial_reference",
        source_title: "Poetry Foundation: Martial",
        source_type: "reference_encyclopedia",
        source_scope: "Poetry Foundation poet profile for Martial's epigrams",
        source_citation: "Poetry Foundation, Martial, https://www.poetryfoundation.org/poets/martial",
        edition: "online poet reference page",
        editors_or_authors: "Poetry Foundation",
        publisher: "Poetry Foundation",
        coverage_limits: "Poet reference page; supports work identity and reception of the epigrams",
        source_section: "Martial profile",
        source_url: "https://www.poetryfoundation.org/poets/martial",
        match_method: "x073_poetry_foundation_martial_epigrams_reference",
        evidence_weight: "0.55",
        supports: "poet_reference_support_for_martial_epigrams",
        notes: "Identifies Martial as best known for his epigrams and gives the surviving epigram count."
      },
      {
        source_id: "x073_penguin_martial_epigrams_reference",
        source_title: "Penguin Random House: Epigrams by Martial",
        source_type: "publisher_reference_series",
        source_scope: "Publisher reference page for a Modern Library edition of Martial's Epigrams",
        source_citation: "Penguin Random House, Epigrams by Martial, https://www.penguinrandomhouse.com/books/108194/epigrams-by-martial/",
        edition: "publisher edition page",
        editors_or_authors: "Martial; translated by James Michie; introduction by Shadi Bartsch",
        publisher: "Modern Library / Penguin Random House",
        coverage_limits: "Edition/reception support for the current titled scope",
        source_section: "Epigrams book page",
        source_url: "https://www.penguinrandomhouse.com/books/108194/epigrams-by-martial/",
        match_method: "x073_publisher_edition_martial_epigrams",
        evidence_weight: "0.35",
        supports: "edition_support_for_martial_epigrams",
        notes: "Publisher page presents Epigrams as a book by Martial with modern scholarly framing."
      }
    ]
  },
  {
    work_id: "work_candidate_eastasia_lit_han_shan_poems",
    title: "Cold Mountain Poems",
    creator: "Hanshan",
    raw_date: "Tang period",
    rationale: "External publisher and reception support confirm the Cold Mountain / Han-shan poem corpus as the current selection scope.",
    sources: [
      {
        source_id: "x073_columbia_cold_mountain_reference",
        source_title: "Columbia University Press: Cold Mountain",
        source_type: "publisher_reference_series",
        source_scope: "Columbia University Press page for Burton Watson's Cold Mountain: One Hundred Poems by the T'ang Poet Han-shan",
        source_citation: "Columbia University Press, Cold Mountain, https://cup.columbia.edu/book/cold-mountain/9780231034500/",
        edition: "publisher edition page",
        editors_or_authors: "Han-shan; translated by Burton Watson",
        publisher: "Columbia University Press",
        coverage_limits: "Edition/reception support for the current selected corpus; not a complete original collection witness",
        source_section: "Cold Mountain book page",
        source_url: "https://cup.columbia.edu/book/cold-mountain/9780231034500/",
        match_method: "x073_publisher_edition_cold_mountain_poems",
        evidence_weight: "0.35",
        supports: "publisher_support_for_hanshan_cold_mountain_selection",
        notes: "Identifies the book as One Hundred Poems by the T'ang Poet Han-shan and describes the collection's Buddhist and Zen-literary significance."
      },
      {
        source_id: "x073_poetry_foundation_cold_mountain_review",
        source_title: "Poetry Foundation / Poetry Magazine: Cold Mountain: 100 Poems by Han-Shan",
        source_type: "prize_or_reception_layer",
        source_scope: "Poetry Magazine review listing of Burton Watson's Cold Mountain: 100 Poems by Han-Shan",
        source_citation: "Poetry Foundation, Poetry Magazine, Cold Mountain: 100 Poems by Han-Shan, https://www.poetryfoundation.org/poetrymagazine/articles/62308/cold-mountain-100-poems-by-han-shan-ed-and-tr-by-burton-watson",
        edition: "Poetry Magazine review listing",
        editors_or_authors: "Achilles Fang / Poetry Magazine",
        publisher: "Poetry Foundation",
        coverage_limits: "Reception/listing support for the selected translated corpus",
        source_section: "Poetry Magazine, December 1965",
        source_url: "https://www.poetryfoundation.org/poetrymagazine/articles/62308/cold-mountain-100-poems-by-han-shan-ed-and-tr-by-burton-watson",
        match_method: "x073_poetry_magazine_cold_mountain_review",
        evidence_weight: "0.35",
        supports: "reception_support_for_hanshan_cold_mountain_selection",
        notes: "Poetry Magazine listing confirms the Burton Watson Cold Mountain: 100 Poems by Han-Shan selection."
      }
    ]
  },
  {
    work_id: "work_candidate_completion_lit_count_lucanor",
    title: "Count Lucanor",
    creator: "Don Juan Manuel",
    raw_date: "1335",
    rationale: "External reference and academy-edition support confirm the titled medieval Spanish prose collection.",
    sources: [
      {
        source_id: "x073_britannica_count_lucanor_reference",
        source_title: "Britannica: Count Lucanor",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica work page for Count Lucanor / The Fifty Pleasant Stories of Patronio",
        source_citation: "Encyclopaedia Britannica, Count Lucanor, https://www.britannica.com/topic/Count-Lucanor-or-The-Fifty-Pleasant-Stories-of-Patronio",
        edition: "online work reference entry",
        editors_or_authors: "Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Work-specific reference support",
        source_section: "Count Lucanor work page",
        source_url: "https://www.britannica.com/topic/Count-Lucanor-or-The-Fifty-Pleasant-Stories-of-Patronio",
        match_method: "x073_britannica_count_lucanor_work_reference",
        evidence_weight: "0.55",
        supports: "work_reference_support_for_count_lucanor",
        notes: "Identifies Don Juan Manuel's Count Lucanor as a collection of exempla and discusses its place in Spanish prose fiction."
      },
      {
        source_id: "x073_rae_count_lucanor_reference",
        source_title: "Real Academia Espanola: El conde Lucanor",
        source_type: "scholarly_edition_series",
        source_scope: "RAE Biblioteca Clasica page for El conde Lucanor",
        source_citation: "Real Academia Espanola, El conde Lucanor, https://www.rae.es/obras-academicas/bcrae/el-conde-lucanor",
        edition: "RAE BCRAE critical edition page",
        editors_or_authors: "Don Juan Manuel; edition and study by Guillermo Seres",
        publisher: "Real Academia Espanola / Espasa",
        coverage_limits: "National-academy critical-edition support; edition and regional/tradition canon signal",
        source_section: "El conde Lucanor BCRAE page",
        source_url: "https://www.rae.es/obras-academicas/bcrae/el-conde-lucanor",
        match_method: "x073_rae_count_lucanor_academy_edition",
        evidence_weight: "0.55",
        supports: "academy_edition_support_for_count_lucanor",
        notes: "RAE presents El conde Lucanor in its Biblioteca Clasica with discussion of the 1335 composition."
      }
    ]
  },
  {
    work_id: "work_candidate_bloom_cervantes_exemplary_stories",
    title: "Exemplary Stories",
    creator: "Miguel de Cervantes",
    raw_date: "1613",
    rationale: "External reference and institutional edition support confirm Cervantes's 1613 Novelas ejemplares / Exemplary Stories.",
    sources: [
      {
        source_id: "x073_britannica_exemplary_stories_reference",
        source_title: "Britannica: Exemplary Stories",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica work page for Cervantes's Exemplary Stories / Novelas ejemplares",
        source_citation: "Encyclopaedia Britannica, Exemplary Stories, https://www.britannica.com/topic/Exemplary-Stories",
        edition: "online work reference entry",
        editors_or_authors: "Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Work-specific reference support",
        source_section: "Exemplary Stories work page",
        source_url: "https://www.britannica.com/topic/Exemplary-Stories",
        match_method: "x073_britannica_exemplary_stories_work_reference",
        evidence_weight: "0.55",
        supports: "work_reference_support_for_exemplary_stories",
        notes: "Identifies Exemplary Stories as Cervantes's Novelas ejemplares and gives the 1613 publication context."
      },
      {
        source_id: "x073_britannica_cervantes_biography_exemplary_stories",
        source_title: "Britannica: Miguel de Cervantes",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica biography identifying Novelas exemplares / Exemplary Stories",
        source_citation: "Encyclopaedia Britannica, Miguel de Cervantes, https://www.britannica.com/biography/Miguel-de-Cervantes",
        edition: "online biography",
        editors_or_authors: "Edward C. Riley / Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Author reference support for title, date, and form",
        source_section: "Miguel de Cervantes biography",
        source_url: "https://www.britannica.com/biography/Miguel-de-Cervantes",
        match_method: "x073_britannica_cervantes_biography_work_reference",
        evidence_weight: "0.55",
        supports: "biography_reference_support_for_exemplary_stories",
        notes: "Identifies Cervantes as a notable short-story writer and gives Novelas exemplares (1613; Exemplary Stories)."
      },
      {
        source_id: "x073_rae_novelas_ejemplares_reference",
        source_title: "Real Academia Espanola: Novelas ejemplares",
        source_type: "scholarly_edition_series",
        source_scope: "RAE page for its critical edition of Novelas ejemplares",
        source_citation: "Real Academia Espanola, Novelas ejemplares, https://www.rae.es/obras-academicas/bcrae/novelas-ejemplares",
        edition: "RAE BCRAE critical edition page",
        editors_or_authors: "Miguel de Cervantes; studies by Jorge Garcia Lopez",
        publisher: "Real Academia Espanola / Espasa",
        coverage_limits: "National-academy critical-edition support; edition and regional/tradition canon signal",
        source_section: "Novelas ejemplares BCRAE page",
        source_url: "https://www.rae.es/obras-academicas/bcrae/novelas-ejemplares",
        match_method: "x073_rae_novelas_ejemplares_academy_edition",
        evidence_weight: "0.55",
        supports: "academy_edition_support_for_exemplary_stories",
        notes: "RAE page identifies the 1613 Novelas ejemplares and its critical-study apparatus."
      }
    ]
  },
  {
    work_id: "work_candidate_mandatory_burns_poems_chiefly",
    title: "Poems, Chiefly in the Scottish Dialect",
    creator: "Robert Burns",
    raw_date: "1786",
    rationale: "External reference and poetry-history support confirm Burns's 1786 Kilmarnock volume as the exact work scope.",
    sources: [
      {
        source_id: "x073_britannica_burns_poems_chiefly_work_reference",
        source_title: "Britannica: Poems, Chiefly in the Scottish Dialect",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica work page for Poems, Chiefly in the Scottish Dialect",
        source_citation: "Encyclopaedia Britannica, Poems, Chiefly in the Scottish Dialect, https://www.britannica.com/topic/Poems-Chiefly-in-the-Scottish-Dialect",
        edition: "online work reference entry",
        editors_or_authors: "Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Work-specific reference support",
        source_section: "Poems, Chiefly in the Scottish Dialect work page",
        source_url: "https://www.britannica.com/topic/Poems-Chiefly-in-the-Scottish-Dialect",
        match_method: "x073_britannica_burns_work_reference",
        evidence_weight: "0.55",
        supports: "work_reference_support_for_burns_kilmarnock_volume",
        notes: "Confirms the work title, 1786 publication, and immediate reception."
      },
      {
        source_id: "x073_britannica_burns_biography_reference",
        source_title: "Britannica: Robert Burns",
        source_type: "reference_encyclopedia",
        source_scope: "Britannica biography identifying Burns's first major verse volume",
        source_citation: "Encyclopaedia Britannica, Robert Burns, https://www.britannica.com/biography/Robert-Burns",
        edition: "online biography",
        editors_or_authors: "Encyclopaedia Britannica",
        publisher: "Encyclopaedia Britannica",
        coverage_limits: "Author reference support for publication identity and date",
        source_section: "Robert Burns biography: Development as a poet",
        source_url: "https://www.britannica.com/biography/Robert-Burns",
        match_method: "x073_britannica_burns_biography_work_reference",
        evidence_weight: "0.55",
        supports: "biography_reference_support_for_burns_kilmarnock_volume",
        notes: "Identifies Poems, Chiefly in the Scottish Dialect as Burns's first major volume of verse."
      },
      {
        source_id: "x073_poetry_foundation_burns_reference",
        source_title: "Poetry Foundation: Robert Burns",
        source_type: "reference_encyclopedia",
        source_scope: "Poetry Foundation poet profile discussing Poems, Chiefly in the Scottish Dialect",
        source_citation: "Poetry Foundation, Robert Burns, https://www.poetryfoundation.org/poets/robert-burns",
        edition: "online poet reference page",
        editors_or_authors: "Poetry Foundation",
        publisher: "Poetry Foundation",
        coverage_limits: "Poet reference page; supports title, 1786 Kilmarnock publication, and reception",
        source_section: "Robert Burns profile",
        source_url: "https://www.poetryfoundation.org/poets/robert-burns",
        match_method: "x073_poetry_foundation_burns_work_reference",
        evidence_weight: "0.55",
        supports: "poet_reference_support_for_burns_kilmarnock_volume",
        notes: "Discusses the first formal publication of Burns's work, printed in Kilmarnock in 1786."
      }
    ]
  }
].freeze

SKIPPED_QUEUE_NOTES = [
  {
    work_id: "work_candidate_bloom_gap_031_0015_poems",
    title: "Poems",
    creator: "Alcman",
    reason: "Generic fragmentary corpus title; needs selected-fragment or corpus-scope policy before source rescue."
  },
  {
    work_id: "work_candidate_me_lit_shmuel_hanagid_poems",
    title: "Selected Poems",
    creator: "Samuel ha-Nagid",
    reason: "Selected-poems row; needs edition/selection policy rather than generic work-level source closure."
  },
  {
    work_id: "work_candidate_eastasia_lit_xin_qiji_ci",
    title: "Selected Ci Poems",
    creator: "Xin Qiji",
    reason: "Selected-poems row; defer to selection-policy packet."
  },
  {
    work_id: "work_candidate_eastasia_lit_li_qingzhao_ci",
    title: "Selected Ci Poems",
    creator: "Li Qingzhao",
    reason: "Selected-poems row; defer to selection-policy packet."
  }
].freeze

def registry_rows
  TARGETS.flat_map do |target|
    target.fetch(:sources).map do |source|
      {
        "source_id" => source.fetch(:source_id),
        "source_title" => source.fetch(:source_title),
        "source_type" => source.fetch(:source_type),
        "source_scope" => source.fetch(:source_scope),
        "source_date" => "accessed 2026-05-04",
        "source_citation" => source.fetch(:source_citation),
        "edition" => source.fetch(:edition),
        "editors_or_authors" => source.fetch(:editors_or_authors),
        "publisher" => source.fetch(:publisher),
        "coverage_limits" => source.fetch(:coverage_limits),
        "extraction_method" => "Targeted X073 public source acquisition review",
        "packet_ids" => PACKET_ID,
        "extraction_status" => "extracted",
        "notes" => source.fetch(:notes)
      }
    end
  end
end

def source_item_rows
  TARGETS.flat_map do |target|
    target.fetch(:sources).map do |source|
      source_item_id = source.fetch(:source_id).sub(/\Ax073_/, "x073_item_")
      {
        "source_id" => source.fetch(:source_id),
        "source_item_id" => source_item_id,
        "raw_title" => target.fetch(:title),
        "raw_creator" => target.fetch(:creator),
        "raw_date" => target.fetch(:raw_date),
        "source_rank" => "",
        "source_section" => source.fetch(:source_section),
        "source_url" => source.fetch(:source_url),
        "source_citation" => source.fetch(:source_citation),
        "matched_work_id" => target.fetch(:work_id),
        "match_method" => source.fetch(:match_method),
        "match_confidence" => source.fetch(:source_type) == "prize_or_reception_layer" ? "0.90" : "0.96",
        "evidence_type" => "inclusion",
        "evidence_weight" => source.fetch(:evidence_weight),
        "supports" => source.fetch(:supports),
        "match_status" => "matched_current_path",
        "notes" => "X073 accepted external source support; this is not a cut approval or public-canon replacement."
      }
    end
  end
end

def evidence_rows(source_items)
  source_by_item = TARGETS.each_with_object({}) do |target, memo|
    target.fetch(:sources).each do |source|
      source_item_id = source.fetch(:source_id).sub(/\Ax073_/, "x073_item_")
      memo[source_item_id] = source
    end
  end

  source_items.map do |source_item|
    source = source_by_item.fetch(source_item.fetch("source_item_id"))
    {
      "evidence_id" => source_item.fetch("source_item_id").sub(/\Ax073_item_/, "x073_ev_"),
      "work_id" => source_item.fetch("matched_work_id"),
      "source_id" => source_item.fetch("source_id"),
      "source_item_id" => source_item.fetch("source_item_id"),
      "evidence_type" => "inclusion",
      "evidence_strength" => source.fetch(:evidence_weight).to_f >= 0.55 ? "moderate" : "weak",
      "page_or_section" => source_item.fetch("source_section"),
      "quote_or_note" => "",
      "packet_id" => PACKET_ID,
      "supports_tier" => "",
      "supports_boundary_policy_id" => "",
      "reviewer_status" => "accepted",
      "notes" => "X073 accepted targeted public source support for a current-path exact-title or selected-corpus row; no cut or replacement approved."
    }
  end
end

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
  source_item_rows_after = read_tsv(SOURCE_ITEMS_PATH)
  scoring_input_rows = read_tsv(File.join(TABLE_DIR, "canon_scoring_inputs.tsv"))

  manifest["status"] = "top_external_acquisition_rescue_x073_applied"
  artifacts["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_x025_x026_x027_x036_x043_x064_x066_x067_x068_x070_x071_x072_and_x073_source_items"
  artifacts["evidence"] = "e001_ingested_x001_x006_pilot_plus_x017_policy_aware_rows_after_x043_plus_x058_x062_x066_x067_x068_representative_selection_x064_complete_work_support_x070_x071_x072_external_support_and_x073_top_queue_support"
  artifacts["source_debt_status"] = "refreshed_after_x073_top_external_acquisition_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x073_top_external_acquisition_rescue"
  artifacts["scores"] = "regenerated_x073_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x073_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x073_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x073_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x073_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x073_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x073_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x073"] = "generated_x073_for_top_external_acquisition_rows"

  counts["source_registry_rows"] = read_tsv(SOURCE_REGISTRY_PATH).size
  counts["source_items"] = source_item_rows_after.size
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
  counts["source_items_matched_current_path"] = source_item_rows_after.count { |row| row.fetch("match_status") == "matched_current_path" }
  counts["source_items_matched_candidate"] = source_item_rows_after.count { |row| row.fetch("match_status") == "matched_candidate" }
  counts["source_items_represented_by_selection"] = source_item_rows_after.count { |row| row.fetch("match_status") == "represented_by_selection" }
  counts["source_items_out_of_scope"] = source_item_rows_after.count { |row| row.fetch("match_status") == "out_of_scope" }
  counts["source_items_unmatched"] = source_item_rows_after.count { |row| row.fetch("match_status") == "unmatched" }
  counts["x073_external_source_rescue_rows"] = applied_rows.size
  counts["x073_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x073"] = high_risk_rows.size

  manifest["top_external_acquisition_rescue_x073"] = {
    "status" => "applied_public_sources_for_top_external_acquisition_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => registry_rows.size,
    "source_item_rows_added_or_updated" => source_item_rows.size,
    "evidence_rows_added_or_updated" => evidence_rows(source_item_rows).size,
    "target_source_debt_closed_after_refresh" => counts["x073_target_works_closed"],
    "lane_counts_after_refresh" => lane_counts,
    "current_high_risk_residue_rows_after_refresh" => high_risk_rows.size,
    "deferred_selected_or_fragmentary_rows" => SKIPPED_QUEUE_NOTES.size,
    "direct_replacements" => 0
  }

  File.write(MANIFEST_PATH, manifest.to_yaml)
end

def write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)
  FileUtils.mkdir_p(File.dirname(REPORT_PATH))
  by_work = applied_rows.group_by { |row| row.fetch("work_id") }

  File.open(REPORT_PATH, "w") do |file|
    file.puts "# X073 Top External Acquisition Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X073 closes source-debt blockers for seven high-priority current-path rows whose titles have stable external support. It deliberately skips generic fragmentary and selected-poems rows that need a separate selection-scope policy."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_apply_top_external_acquisition_rescue_x073.rb`."
    file.puts "- Added `canon_external_source_rescue_evidence_applied_x073.tsv`."
    file.puts "- Added or updated #{registry_rows.size} source-registry rows, #{source_item_rows.size} source-item rows, and #{evidence_rows(source_item_rows).size} accepted evidence rows."
    file.puts "- Refreshed source-debt, scoring, cut-side, current-scope, and high-risk residue tables."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X073 |"
    file.puts "|---|---|---:|---|"
    TARGETS.each do |target|
      status = source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status")
      evidence_count = by_work.fetch(target.fetch(:work_id), []).size
      file.puts "| `#{target.fetch(:title)}` | #{target.fetch(:creator)} | #{evidence_count} | `#{status}` |"
    end
    file.puts
    file.puts "## Deferred Rows"
    file.puts
    file.puts "| Work | Creator | Reason |"
    file.puts "|---|---|---|"
    SKIPPED_QUEUE_NOTES.each do |note|
      file.puts "| `#{note.fetch(:title)}` | #{note.fetch(:creator)} | #{note.fetch(:reason)} |"
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
    file.puts "These rows are no longer source-debt blockers if they reached `closed_by_independent_external_support`. Generic-title, duplicate-cluster, selection-basis, chronology, and boundary checks still apply before any cut or replacement can advance."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

source_debt_before = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
new_registry_rows = registry_rows
new_source_item_rows = source_item_rows
new_evidence_rows = evidence_rows(new_source_item_rows)

registry_after = upsert_rows(read_tsv(SOURCE_REGISTRY_PATH), new_registry_rows, "source_id")
source_items_after = upsert_rows(read_tsv(SOURCE_ITEMS_PATH), new_source_item_rows, "source_item_id")
evidence_after = upsert_rows(read_tsv(EVIDENCE_PATH), new_evidence_rows, "evidence_id")

write_tsv(SOURCE_REGISTRY_PATH, tsv_headers(SOURCE_REGISTRY_PATH), registry_after, sort_key: "source_id")
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_items_after)
write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_after)

refresh_downstream!

source_debt_after = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
actions_by_work = read_tsv(ACTION_QUEUE_PATH).to_h { |row| [row.fetch("cut_work_id"), row] }
lane_counts = read_tsv(ACTION_QUEUE_PATH).each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("current_lane")] += 1 }
high_risk_rows = read_tsv(HIGH_RISK_RESIDUE_PATH).select { |row| row.fetch("residue_status") == "current_high_risk_scope_blocker" }
target_by_work = TARGETS.to_h { |target| [target.fetch(:work_id), target] }
source_type_by_id = new_registry_rows.to_h { |row| [row.fetch("source_id"), row.fetch("source_type")] }

applied_rows = new_evidence_rows.map.with_index(1) do |evidence, index|
  source_item = new_source_item_rows.find { |row| row.fetch("source_item_id") == evidence.fetch("source_item_id") }
  work_id = evidence.fetch("work_id")
  target = target_by_work.fetch(work_id)
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
    "applied_id" => "x073_external_source_rescue_#{index.to_s.rjust(4, "0")}",
    "work_id" => work_id,
    "title" => target.fetch(:title),
    "creator" => target.fetch(:creator),
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
    "rationale" => target.fetch(:rationale)
  }
end

write_tsv(APPLIED_PATH, APPLIED_HEADERS, applied_rows)

closed_count = TARGETS.count { |target| !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_") }

update_packet_status(
  {
    "packet_id" => PACKET_ID,
    "packet_family" => "X",
    "scope" => "top external-source acquisition rescue for seven current-path rows",
    "status" => "top_external_source_rescue_applied",
    "gate" => "cut_and_replacement_review_still_required",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x073.tsv",
      "scripts/canon_apply_top_external_acquisition_rescue_x073.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_057_x073_top_external_acquisition_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X073 external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
