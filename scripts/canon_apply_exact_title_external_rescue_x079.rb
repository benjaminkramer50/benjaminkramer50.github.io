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

PACKET_ID = "X079"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x079.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_063_x079_exact_title_external_rescue.md")

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
    work_id: "work_candidate_bloom_gap_031_0135_the_poems_of_st_john_of_the_cross",
    title: "The Poems of St. John of the Cross",
    creator: "San Juan de la Cruz (Saint John of the Cross)",
    raw_date: "1979; Chicago 1995",
    form_note: "Spanish mystical poetry collection in bilingual translation",
    rationale: "University of Chicago Press and BiblioVault confirm The Poems of St. John of the Cross as an author-specific complete-poems edition translated by John Frederick Nims.",
    sources: [
      ["x079_uchicago_poems_st_john_cross", "University of Chicago Press: The Poems of St. John of the Cross", "publisher_reference_series", "University of Chicago Press, The Poems of St. John of the Cross, https://press.uchicago.edu/ucp/books/book/chicago/P/bo5948070.html", "University of Chicago Press book page", "https://press.uchicago.edu/ucp/books/book/chicago/P/bo5948070.html", "x079_uchicago_exact_poems_st_john_cross", "0.55", "publisher_support_for_poems_st_john_cross"],
      ["x079_bibliovault_poems_st_john_cross", "BiblioVault: The Poems of St. John of the Cross", "publisher_reference_series", "BiblioVault, The Poems of St. John of the Cross, https://www.bibliovault.org/BV.book.epl?ISBN=9780226401102", "BiblioVault title record", "https://www.bibliovault.org/BV.book.epl?ISBN=9780226401102", "x079_bibliovault_exact_poems_st_john_cross", "0.55", "publisher_record_support_for_poems_st_john_cross"]
    ]
  },
  {
    work_id: "work_candidate_bloom_gap_031_0134_the_unknown_light_the_poems_of_fray_luis_de_leon",
    title: "The Unknown Light: The Poems of Fray Luis de Leon",
    creator: "Fray Luis de Leon",
    raw_date: "1979",
    form_note: "Spanish Renaissance poetry collection in bilingual translation",
    rationale: "Google Books and the Academy of American Poets confirm The Unknown Light: The Poems of Fray Luis de Leon as Willis Barnstone's 1979 State University of New York Press translation.",
    sources: [
      ["x079_google_books_unknown_light", "Google Books: The Unknown Light", "publisher_reference_series", "Google Books, The Unknown Light: The Poems of Fray Luis de Leon, https://books.google.com/books/about/The_Unknown_Light.html?id=U0NRAQAAIAAJ", "Google Books title record", "https://books.google.com/books/about/The_Unknown_Light.html?id=U0NRAQAAIAAJ", "x079_google_books_exact_unknown_light", "0.55", "publisher_record_support_for_unknown_light"],
      ["x079_poets_barnstone_unknown_light", "Academy of American Poets: Willis Barnstone", "language_literary_history", "Academy of American Poets, About Willis Barnstone, https://poets.org/poet/willis-barnstone", "Author bibliography", "https://poets.org/poet/willis-barnstone", "x079_poets_exact_unknown_light", "0.55", "literary_history_support_for_unknown_light"]
    ]
  },
  {
    work_id: "work_candidate_bloom_reviewed_she_wolf_stories",
    title: "The She-Wolf and Other Stories",
    creator: "Giovanni Verga",
    raw_date: "1973; California paperback 1982",
    form_note: "Italian short story collection in English translation",
    rationale: "University of California Press and Google Books confirm The She-Wolf and Other Stories as a Verga short-fiction collection translated and introduced by Giovanni Cecchetti.",
    sources: [
      ["x079_ucpress_she_wolf_stories", "University of California Press: The She-Wolf and Other Stories", "publisher_reference_series", "University of California Press, The She-Wolf and Other Stories, https://www.ucpress.edu/books/the-she-wolf-and-other-stories/paper", "University of California Press book page", "https://www.ucpress.edu/books/the-she-wolf-and-other-stories/paper", "x079_ucpress_exact_she_wolf_stories", "0.55", "publisher_support_for_she_wolf_stories"],
      ["x079_google_books_she_wolf_stories", "Google Books: The She-Wolf and Other Stories", "publisher_reference_series", "Google Books, The She-Wolf and Other Stories, https://books.google.com/books/about/The_She_Wolf_and_Other_Stories.html?id=GmzfEAAAQBAJ", "Google Books title record", "https://books.google.com/books/about/The_She_Wolf_and_Other_Stories.html?id=GmzfEAAAQBAJ", "x079_google_books_exact_she_wolf_stories", "0.55", "publisher_record_support_for_she_wolf_stories"]
    ]
  },
  {
    work_id: "work_candidate_bloom_chesnutt_short_fiction",
    title: "The Short Fiction",
    creator: "Charles W. Chesnutt",
    raw_date: "1974; 1981 paperback",
    form_note: "African American short fiction collection",
    rationale: "A CLA Journal review on JSTOR and a Washington State University Chesnutt bibliography confirm The Short Fiction of Charles W. Chesnutt as a Howard University Press collection edited by Sylvia Lyons Render.",
    sources: [
      ["x079_jstor_chesnutt_short_fiction_review", "JSTOR: The Short Fiction of Charles W. Chesnutt review", "language_literary_history", "JSTOR, The Short Fiction of Charles W. Chesnutt review, https://www.jstor.org/stable/44329143", "CLA Journal review", "https://www.jstor.org/stable/44329143", "x079_jstor_exact_chesnutt_short_fiction", "0.55", "scholarly_review_support_for_chesnutt_short_fiction"],
      ["x079_wsu_chesnutt_bibliography", "Washington State University: Charles W. Chesnutt Selected Bibliography", "language_literary_history", "Donna Campbell, Charles W. Chesnutt: Selected Bibliography, Washington State University, https://public.archive.wsu.edu/campbelld/public_html/amlit/chesbib.htm", "Selected bibliography", "https://public.archive.wsu.edu/campbelld/public_html/amlit/chesbib.htm", "x079_wsu_bibliography_exact_chesnutt_short_fiction", "0.55", "literary_bibliography_support_for_chesnutt_short_fiction"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0857_a_longing_for_the_light_selected_poems",
    title: "A Longing for the Light: Selected Poems",
    creator: "Vicente Aleixandre",
    raw_date: "1985; second edition 2007",
    form_note: "Spanish poetry selection in English translation",
    rationale: "Copper Canyon Press and EBSCO confirm A Longing for the Light: Selected Poems of Vicente Aleixandre as a selected-poems edition edited and translated by Lewis Hyde.",
    sources: [
      ["x079_copper_aleixandre_longing_light", "Copper Canyon Press: A Longing for the Light", "publisher_reference_series", "Copper Canyon Press, A Longing for the Light: Selected Poems of Vicente Aleixandre, https://www.coppercanyonpress.org/books/a-longing-for-the-light-selected-poems-of-vicente-aleixandre/", "Copper Canyon Press book page", "https://www.coppercanyonpress.org/books/a-longing-for-the-light-selected-poems-of-vicente-aleixandre/", "x079_copper_exact_aleixandre_longing_light", "0.55", "publisher_support_for_aleixandre_longing_light"],
      ["x079_ebsco_aleixandre_longing_light", "EBSCO Research Starters: A Longing for the Light", "language_literary_history", "EBSCO, A Longing for the Light by Vicente Aleixandre, https://www.ebsco.com/research-starters/literature-and-writing/longing-light-vicente-aleixandre", "Literature research-starter entry", "https://www.ebsco.com/research-starters/literature-and-writing/longing-light-vicente-aleixandre", "x079_ebsco_exact_aleixandre_longing_light", "0.55", "literary_history_support_for_aleixandre_longing_light"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0864_selected_poems_of_luis_cernuda",
    title: "Selected Poems of Luis Cernuda",
    creator: "Luis Cernuda",
    raw_date: "1977; Sheep Meadow 1999",
    form_note: "Spanish poetry selection in English translation",
    rationale: "The Academy of American Poets and Google Books confirm Selected Poems of Luis Cernuda as Reginald Gibbons's University of California Press selected-poems edition.",
    sources: [
      ["x079_poets_cernuda_selected_poems", "Academy of American Poets: Luis Cernuda", "language_literary_history", "Academy of American Poets, About Luis Cernuda, https://poets.org/poet/luis-cernuda", "Author bibliography", "https://poets.org/poet/luis-cernuda", "x079_poets_exact_cernuda_selected_poems", "0.55", "literary_history_support_for_cernuda_selected_poems"],
      ["x079_google_books_cernuda_selected_poems", "Google Books: Selected Poems of Luis Cernuda", "publisher_reference_series", "Google Books, Selected Poems of Luis Cernuda, https://books.google.com/books/about/Selected_Poems_of_Luis_Cernuda.html?id=XagtAQAAIAAJ", "Google Books title record", "https://books.google.com/books/about/Selected_Poems_of_Luis_Cernuda.html?id=XagtAQAAIAAJ", "x079_google_books_exact_cernuda_selected_poems", "0.55", "publisher_record_support_for_cernuda_selected_poems"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0863_the_owl_s_insomnia_poems",
    title: "The Owl's Insomnia: Poems",
    creator: "Rafael Alberti",
    raw_date: "1973; reprint 1982",
    form_note: "Spanish poetry selection in bilingual translation",
    rationale: "Google Books and Poetry Foundation confirm The Owl's Insomnia: Poems as Mark Strand's Atheneum selection and translation of Rafael Alberti.",
    sources: [
      ["x079_google_books_owl_insomnia", "Google Books: The Owl's Insomnia", "publisher_reference_series", "Google Books, The Owl's Insomnia, https://books.google.com/books/about/The_Owl_s_Insomnia.html?id=V3sNAAAAIAAJ", "Google Books title record", "https://books.google.com/books/about/The_Owl_s_Insomnia.html?id=V3sNAAAAIAAJ", "x079_google_books_exact_owl_insomnia", "0.55", "publisher_record_support_for_owl_insomnia"],
      ["x079_poetry_foundation_owl_insomnia", "Poetry Foundation: August 1974 Poetry issue", "prize_or_reception_layer", "Poetry Foundation, August 1974 Poetry issue, https://www.poetryfoundation.org/poetrymagazine/issue/71056/august-1974", "Poetry magazine issue record", "https://www.poetryfoundation.org/poetrymagazine/issue/71056/august-1974", "x079_poetry_foundation_exact_owl_insomnia", "0.55", "reception_support_for_owl_insomnia"]
    ]
  },
  {
    work_id: "work_candidate_bloom_reviewed_cheever_stories",
    title: "The Stories of John Cheever",
    creator: "John Cheever",
    raw_date: "1978",
    form_note: "American short story collection",
    rationale: "Penguin Random House and the Pulitzer Prizes confirm The Stories of John Cheever as the 1978 Knopf collection that won the Pulitzer Prize for Fiction.",
    sources: [
      ["x079_prh_cheever_stories", "Penguin Random House: The Stories of John Cheever", "publisher_reference_series", "Penguin Random House, The Stories of John Cheever, https://www.penguinrandomhouse.com/books/26648/the-stories-of-john-cheever-pulitzer-prize-winner-by-john-cheever/", "Vintage book page", "https://www.penguinrandomhouse.com/books/26648/the-stories-of-john-cheever-pulitzer-prize-winner-by-john-cheever/", "x079_prh_exact_cheever_stories", "0.55", "publisher_support_for_cheever_stories"],
      ["x079_pulitzer_cheever_stories", "Pulitzer Prizes: John Cheever", "prize_or_reception_layer", "The Pulitzer Prizes, John Cheever, https://www.pulitzer.org/winners/john-cheever", "Pulitzer winner page", "https://www.pulitzer.org/winners/john-cheever", "x079_pulitzer_exact_cheever_stories", "0.55", "prize_support_for_cheever_stories"]
    ]
  },
  {
    work_id: "work_candidate_latcarib_lit_taker_stories",
    title: "The Taker and Other Stories",
    creator: "Rubem Fonseca",
    raw_date: "1979 Portuguese source work; English selection 2008",
    form_note: "Brazilian short story collection in English translation",
    rationale: "Open Letter Books and Publishers Weekly confirm The Taker and Other Stories as Fonseca's first English-language story collection; chronology still needs review because the current row date appears to follow the Portuguese source-work date rather than the English collection date.",
    sources: [
      ["x079_openletter_taker_stories", "Open Letter Books: The Taker and Other Stories", "publisher_reference_series", "Open Letter Books, The Taker and Other Stories, https://www.openletterbooks.org/products/the-taker-and-other-stories", "Open Letter Books page", "https://www.openletterbooks.org/products/the-taker-and-other-stories", "x079_openletter_exact_taker_stories", "0.55", "publisher_support_for_taker_stories"],
      ["x079_pw_taker_stories", "Publishers Weekly: The Taker and Other Stories", "prize_or_reception_layer", "Publishers Weekly, The Taker and Other Stories by Rubem Fonseca, https://www.publishersweekly.com/9781934824023", "Publishers Weekly review", "https://www.publishersweekly.com/9781934824023", "x079_pw_exact_taker_stories", "0.55", "review_support_for_taker_stories"]
    ]
  },
  {
    work_id: "work_candidate_eastasia_lit_refugees",
    title: "The Refugees",
    creator: "Viet Thanh Nguyen",
    raw_date: "2017",
    form_note: "Vietnamese American short story collection",
    rationale: "Grove Atlantic and the National Book Foundation confirm The Refugees as Viet Thanh Nguyen's short story collection.",
    sources: [
      ["x079_grove_refugees_nguyen", "Grove Atlantic: The Refugees", "publisher_reference_series", "Grove Atlantic, The Refugees, https://groveatlantic.com/book/the-refugees/", "Grove Atlantic book page", "https://groveatlantic.com/book/the-refugees/", "x079_grove_exact_refugees_nguyen", "0.55", "publisher_support_for_refugees_nguyen"],
      ["x079_nbf_refugees_nguyen", "National Book Foundation: Viet Thanh Nguyen", "prize_or_reception_layer", "National Book Foundation, Viet Thanh Nguyen, https://www.nationalbook.org/people/viet-thanh-nguyen/", "Author profile", "https://www.nationalbook.org/people/viet-thanh-nguyen/", "x079_nbf_exact_refugees_nguyen", "0.55", "reception_support_for_refugees_nguyen"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_southasia_lit_tukaram_abhangas", "Selected Abhangas", "Tukaram", "Existing source items are individual abhangas; this needs selected-collection policy or exact edition support."],
  ["work_candidate_scale2_lit_sonnets_to_orpheus", "Sonnets to Orpheus", "Rainer Maria Rilke", "Existing source items are Archaic Torso of Apollo only; this does not close source debt for Sonnets to Orpheus."],
  ["work_candidate_indig_lit_akabal_poems", "Selected Poems", "Humberto Ak'abal", "Existing source items are representative poems; this needs selected-poems policy before evidence generation."],
  ["work_candidate_scale_lit_archilochus_poems", "Selected Poems", "Archilochus", "Generic ancient lyric selection; needs edition/selection policy."],
  ["work_candidate_bloom_gap_031_0015_poems", "Poems", "Alcman", "Generic fragmentary corpus title; needs selected-fragment or corpus-scope policy."],
  ["work_candidate_eastasia_lit_yuefu_songs", "Selected Yuefu Songs", "Han and post-Han poetic tradition", "Generic anthology selection; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_xin_qiji_ci", "Selected Ci Poems", "Xin Qiji", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_li_qingzhao_ci", "Selected Ci Poems", "Li Qingzhao", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_global_lit_prison_notebooks_poems", "Poems from Prison", "Ho Chi Minh", "Likely title/scope correction to Prison Diary or Poems from the Prison Diary is needed before scoring."],
  ["work_candidate_bloom_maupassant_selected_stories", "Boule de Suif and Selected Stories", "Guy de Maupassant", "Selected-stories row; needs edition/selection policy."],
  ["work_candidate_completion_lit_peretz_stories", "Selected Stories", "I. L. Peretz", "Generic selected-stories row; needs edition/selection policy."],
  ["work_candidate_global_lit_manto_selected_stories", "Selected Stories", "Saadat Hasan Manto", "Generic selected-stories row; needs edition/selection policy."],
  ["work_candidate_latcarib_lit_silvina_ocampo_stories", "Selected Stories", "Silvina Ocampo", "Generic selected-stories row; needs edition/selection policy."],
  ["work_candidate_bloom_reviewed_welty_stories", "Selected Stories", "Eudora Welty", "Generic selected-stories row; needs edition/selection policy."],
  ["work_candidate_southasia_lit_pudhumaipithan_stories", "Selected Stories", "Pudhumaipithan", "Generic selected-stories row; needs edition/selection policy."]
].freeze

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

def source_item_id(source_id)
  source_id.sub(/\Ax079_/, "x079_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax079_/, "x079_ev_")
end

def registry_rows
  TARGETS.flat_map do |target|
    target.fetch(:sources).map do |source|
      source_id, source_title, source_type, citation, = source
      {
        "source_id" => source_id,
        "source_title" => source_title,
        "source_type" => source_type,
        "source_scope" => "External exact-title support for #{target.fetch(:title)} by #{target.fetch(:creator)}",
        "source_date" => "accessed 2026-05-04",
        "source_citation" => citation,
        "edition" => "online reference, review, prize, or edition page",
        "editors_or_authors" => target.fetch(:creator),
        "publisher" => source_title.split(":").first,
        "coverage_limits" => "Build-layer source-debt support only; no cut or replacement approval.",
        "extraction_method" => "Targeted X079 exact-title public source review",
        "packet_ids" => PACKET_ID,
        "extraction_status" => "extracted",
        "notes" => "Supports #{target.fetch(:form_note)} identity and external source debt closure."
      }
    end
  end
end

def source_item_rows
  TARGETS.flat_map do |target|
    target.fetch(:sources).map do |source|
      source_id, _source_title, _source_type, citation, section, url, method, weight, supports = source
      {
        "source_id" => source_id,
        "source_item_id" => source_item_id(source_id),
        "raw_title" => target.fetch(:title),
        "raw_creator" => target.fetch(:creator),
        "raw_date" => target.fetch(:raw_date),
        "source_rank" => "",
        "source_section" => section,
        "source_url" => url,
        "source_citation" => citation,
        "matched_work_id" => target.fetch(:work_id),
        "match_method" => method,
        "match_confidence" => "0.96",
        "evidence_type" => "inclusion",
        "evidence_weight" => weight,
        "supports" => supports,
        "match_status" => "matched_current_path",
        "notes" => "X079 accepted external exact-title support; no cut or replacement approved."
      }
    end
  end
end

def evidence_rows(items)
  items.map do |item|
    weight = item.fetch("evidence_weight").to_f
    {
      "evidence_id" => evidence_id(item.fetch("source_id")),
      "work_id" => item.fetch("matched_work_id"),
      "source_id" => item.fetch("source_id"),
      "source_item_id" => item.fetch("source_item_id"),
      "evidence_type" => "inclusion",
      "evidence_strength" => weight >= 0.55 ? "moderate" : "weak",
      "page_or_section" => item.fetch("source_section"),
      "quote_or_note" => "",
      "packet_id" => PACKET_ID,
      "supports_tier" => "",
      "supports_boundary_policy_id" => "",
      "reviewer_status" => "accepted",
      "notes" => "X079 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
    }
  end
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

def refresh_count(counts, key, path)
  counts[key] = read_tsv(path).size
end

def update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
  return unless File.exist?(MANIFEST_PATH)

  manifest = YAML.load_file(MANIFEST_PATH)
  artifacts = manifest.fetch("artifacts")
  counts = manifest.fetch("current_counts")
  source_item_rows_after = read_tsv(SOURCE_ITEMS_PATH)
  scoring_input_rows = read_tsv(File.join(TABLE_DIR, "canon_scoring_inputs.tsv"))

  manifest["status"] = "exact_title_external_rescue_x079_applied"
  artifacts["source_items"] = "e001_ingested_through_x079_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x079_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x079_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x079_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x079_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x079_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x079_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x079_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x079_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x079_from_current_x063_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x079_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x079"] = "generated_x079_for_exact_title_external_acquisition_rows"

  refresh_count(counts, "source_registry_rows", SOURCE_REGISTRY_PATH)
  counts["source_items"] = source_item_rows_after.size
  refresh_count(counts, "evidence_rows", EVIDENCE_PATH)
  counts["source_debt_status_rows"] = source_debt_after.size
  counts["scoring_input_rows"] = scoring_input_rows.size
  counts["scoring_ready_rows"] = scoring_input_rows.count { |row| row.fetch("scoring_readiness") == "ready_for_score_computation" }
  counts["scoring_blocked_rows"] = scoring_input_rows.count { |row| row.fetch("scoring_readiness") == "blocked_from_score_computation" }
  refresh_count(counts, "score_rows", File.join(TABLE_DIR, "canon_scores.tsv"))
  refresh_count(counts, "replacement_candidate_rows", File.join(TABLE_DIR, "canon_replacement_candidates.tsv"))
  refresh_count(counts, "replacement_pair_review_queue_rows", File.join(TABLE_DIR, "canon_replacement_pair_review_queue.tsv"))
  refresh_count(counts, "cut_review_work_order_rows", File.join(TABLE_DIR, "canon_cut_review_work_orders.tsv"))
  refresh_count(counts, "generic_selection_basis_review_rows", File.join(TABLE_DIR, "canon_generic_selection_basis_review.tsv"))
  refresh_count(counts, "cut_side_post_x058_action_queue_rows", ACTION_QUEUE_PATH)
  refresh_count(counts, "current_rescue_scope_review_rows", SCOPE_REVIEW_PATH)
  refresh_count(counts, "high_risk_rescue_residue_rows", HIGH_RISK_RESIDUE_PATH)
  refresh_count(counts, "cut_candidate_rows", File.join(TABLE_DIR, "canon_cut_candidates.tsv"))
  counts["source_items_matched_current_path"] = source_item_rows_after.count { |row| row.fetch("match_status") == "matched_current_path" }
  counts["source_items_matched_candidate"] = source_item_rows_after.count { |row| row.fetch("match_status") == "matched_candidate" }
  counts["source_items_represented_by_selection"] = source_item_rows_after.count { |row| row.fetch("match_status") == "represented_by_selection" }
  counts["source_items_out_of_scope"] = source_item_rows_after.count { |row| row.fetch("match_status") == "out_of_scope" }
  counts["source_items_unmatched"] = source_item_rows_after.count { |row| row.fetch("match_status") == "unmatched" }
  counts["x079_external_source_rescue_rows"] = applied_rows.size
  counts["x079_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x079"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x079"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x079_target_works_closed"],
    "lane_counts_after_refresh" => lane_counts,
    "current_high_risk_residue_rows_after_refresh" => high_risk_rows.size,
    "deferred_selection_or_uncertain_rows" => DEFERRED_NOTES.size,
    "direct_replacements" => 0
  }

  File.write(MANIFEST_PATH, manifest.to_yaml)
end

def write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)
  by_work = applied_rows.group_by { |row| row.fetch("work_id") }
  FileUtils.mkdir_p(File.dirname(REPORT_PATH))

  File.open(REPORT_PATH, "w") do |file|
    file.puts "# X079 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X079 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves generic selected-poems/stories rows, component-only rows, and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X079 |"
    file.puts "|---|---|---:|---|"
    TARGETS.each do |target|
      status = source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status")
      file.puts "| `#{target.fetch(:title)}` | #{target.fetch(:creator)} | #{by_work.fetch(target.fetch(:work_id), []).size} | `#{status}` |"
    end
    file.puts
    file.puts "## Deferred Rows"
    file.puts
    file.puts "| Work | Creator | Reason |"
    file.puts "|---|---|---|"
    DEFERRED_NOTES.each { |_id, title, creator, reason| file.puts "| `#{title}` | #{creator} | #{reason} |" }
    file.puts
    file.puts "Cut-side lane summary after refresh:"
    file.puts
    file.puts "| Lane | Rows |"
    file.puts "|---|---:|"
    lane_counts.sort.each { |lane, count| file.puts "| `#{lane}` | #{count} |" }
    file.puts
    file.puts "Current high-risk residue after refresh: #{high_risk_rows.size}."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

source_debt_before = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
new_registry_rows = registry_rows
new_source_items = source_item_rows
new_evidence_rows = evidence_rows(new_source_items)

write_tsv(SOURCE_REGISTRY_PATH, tsv_headers(SOURCE_REGISTRY_PATH), upsert_rows(read_tsv(SOURCE_REGISTRY_PATH), new_registry_rows, "source_id"), sort_key: "source_id")
write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), upsert_rows(read_tsv(SOURCE_ITEMS_PATH), new_source_items, "source_item_id"))
write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), upsert_rows(read_tsv(EVIDENCE_PATH), new_evidence_rows, "evidence_id"))

refresh_downstream!

source_debt_after = read_tsv(SOURCE_DEBT_PATH).to_h { |row| [row.fetch("work_id"), row] }
actions_by_work = read_tsv(ACTION_QUEUE_PATH).to_h { |row| [row.fetch("cut_work_id"), row] }
lane_counts = read_tsv(ACTION_QUEUE_PATH).each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("current_lane")] += 1 }
high_risk_rows = read_tsv(HIGH_RISK_RESIDUE_PATH).select { |row| row.fetch("residue_status") == "current_high_risk_scope_blocker" }
target_by_work = TARGETS.to_h { |target| [target.fetch(:work_id), target] }
source_type_by_id = new_registry_rows.to_h { |row| [row.fetch("source_id"), row.fetch("source_type")] }

applied_rows = new_evidence_rows.map.with_index(1) do |evidence, index|
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
    "applied_id" => "x079_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
    "scope" => "exact-title external-source rescue for current-path rows",
    "status" => "exact_title_external_source_rescue_applied",
    "gate" => "cut_and_replacement_review_still_required",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x079.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x079.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_063_x079_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X079 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
