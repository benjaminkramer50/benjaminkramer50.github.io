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

PACKET_ID = "X076"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x076.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_060_x076_exact_title_external_rescue.md")

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
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0850_kisses_from_another_dream_poems",
    title: "Kisses From Another Dream: Poems",
    creator: "Antonio Porta",
    raw_date: "1987",
    form_note: "Italian poetry collection in translation",
    rationale: "Google Books and the University of Chicago City Lights Pocket Poets exhibit independently confirm Kisses From Another Dream as Antonio Porta's 1987 City Lights Pocket Poets volume.",
    sources: [
      ["x076_google_books_kisses_from_another_dream", "Google Books: Kisses from Another Dream", "publisher_reference_series", "Google Books, Kisses from Another Dream by Antonio Porta, https://books.google.com/books/about/Kisses_from_Another_Dream.html?id=KboeAQAAIAAJ", "Google Books title record", "https://books.google.com/books/about/Kisses_from_Another_Dream.html?id=KboeAQAAIAAJ", "x076_google_books_exact_kisses_from_another_dream", "0.55", "publisher_record_support_for_kisses_from_another_dream"],
      ["x076_uchicago_city_lights_kisses_from_another_dream", "University of Chicago Library: City Lights Pocket Poets Series 1955-2005", "language_literary_history", "University of Chicago Library, City Lights Pocket Poets Series 1955-2005: From the, https://www.lib.uchicago.edu/media/documents/exclpps-City-Lights-Donald-Henneghan-T.pdf", "City Lights Pocket Poets Series catalog entry", "https://www.lib.uchicago.edu/media/documents/exclpps-City-Lights-Donald-Henneghan-T.pdf", "x076_uchicago_exact_kisses_from_another_dream", "0.55", "library_exhibit_support_for_kisses_from_another_dream"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0872_la_pell_de_brau_poems",
    title: "La Pell de Brau: Poems",
    creator: "Salvador Espriu",
    raw_date: "1960",
    form_note: "Catalan poetry collection",
    rationale: "Enciclopedia.cat and the Associacio d'Escriptors en Llengua Catalana confirm La pell de brau as Espriu's 1960 poetry collection.",
    sources: [
      ["x076_enciclopedia_cat_la_pell_de_brau", "Enciclopedia.cat: La pell de brau", "reference_encyclopedia", "Enciclopedia.cat, La pell de brau, https://www.enciclopedia.cat/gran-enciclopedia-catalana/la-pell-de-brau", "Gran Enciclopedia Catalana work entry", "https://www.enciclopedia.cat/gran-enciclopedia-catalana/la-pell-de-brau", "x076_enciclopedia_exact_la_pell_de_brau", "0.55", "reference_support_for_la_pell_de_brau"],
      ["x076_escriptors_cat_la_pell_de_brau", "Associacio d'Escriptors en Llengua Catalana: La pell de brau", "language_literary_history", "Associacio d'Escriptors en Llengua Catalana, La pell de brau, https://www.escriptors.cat/autors/esprius/obra/la-pell-de-brau", "AELC author-work page", "https://www.escriptors.cat/autors/esprius/obra/la-pell-de-brau", "x076_aelc_exact_la_pell_de_brau", "0.55", "language_literary_history_support_for_la_pell_de_brau"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0938_exile_and_other_poems",
    title: "Exile and Other Poems",
    creator: "Saint-John Perse",
    raw_date: "1942; English 1949",
    form_note: "French poetry collection in translation",
    rationale: "NobelPrize.org and Britannica independently identify Exile and Other Poems as a central Saint-John Perse exile-period work.",
    sources: [
      ["x076_nobel_perse_exile_and_other_poems", "NobelPrize.org: Saint-John Perse Facts", "prize_or_reception_layer", "NobelPrize.org, Saint-John Perse Facts, https://www.nobelprize.org/prizes/literature/1960/perse/facts/", "Nobel Prize author facts page", "https://www.nobelprize.org/prizes/literature/1960/perse/facts/", "x076_nobel_exact_exile_and_other_poems", "0.55", "nobel_reference_support_for_exile_and_other_poems"],
      ["x076_britannica_perse_exile_and_other_poems", "Britannica: Saint-John Perse", "reference_encyclopedia", "Encyclopaedia Britannica, Saint-John Perse, https://www.britannica.com/biography/Saint-John-Perse", "Saint-John Perse biography", "https://www.britannica.com/biography/Saint-John-Perse", "x076_britannica_exact_exile_and_other_poems", "0.55", "reference_support_for_exile_and_other_poems"],
      ["x076_nobel_bibliography_perse_exile_and_other_poems", "NobelPrize.org: Saint-John Perse Bibliography", "publisher_reference_series", "NobelPrize.org, Saint-John Perse Bibliography, https://www.nobelprize.org/prizes/literature/1960/perse/bibliography/", "Nobel Prize bibliography page", "https://www.nobelprize.org/prizes/literature/1960/perse/bibliography/", "x076_nobel_bib_exact_exile_and_other_poems", "0.55", "bibliography_support_for_exile_and_other_poems"]
    ]
  },
  {
    work_id: "work_candidate_southasia_lit_angarey",
    title: "Angarey",
    creator: "Sajjad Zaheer, Rashid Jahan, Ahmed Ali, and Mahmuduzzafar",
    raw_date: "1932",
    form_note: "Urdu story and drama collection",
    rationale: "Oxford Academic and a DOAJ-indexed article independently confirm Angarey as the 1932 collection associated with the Progressive Writers' Movement.",
    sources: [
      ["x076_oxford_academic_analysing_angarey", "Oxford Academic: Analysing Angarey", "language_literary_history", "Oxford Academic, Analysing Angarey, https://academic.oup.com/book/25667/chapter/193116520", "Oxford Academic book chapter", "https://academic.oup.com/book/25667/chapter/193116520", "x076_oxford_exact_angarey", "0.55", "scholarly_chapter_support_for_angarey"],
      ["x076_doaj_writers_of_angarey", "DOAJ: The Writers of Angaray and Class Struggle", "language_literary_history", "DOAJ, The Writers of Angaray and Class Struggle, https://doaj.org/article/4a06d06f04e24a71958ad282682a4d86", "DOAJ article record", "https://doaj.org/article/4a06d06f04e24a71958ad282682a4d86", "x076_doaj_exact_angarey", "0.55", "scholarly_article_support_for_angarey"],
      ["x076_tandfonline_angarey_censored_literature", "Taylor & Francis: Colonial Sense and Religious Sensibility", "language_literary_history", "Taylor & Francis Online, Colonial Sense and Religious Sensibility, https://www.tandfonline.com/doi/abs/10.1080/1462317X.2024.2304447", "Political Theology article abstract", "https://www.tandfonline.com/doi/abs/10.1080/1462317X.2024.2304447", "x076_tandf_exact_angarey", "0.55", "scholarly_article_support_for_angarey"]
    ]
  },
  {
    work_id: "work_candidate_euro_under_lit_sanatorium_hourglass",
    title: "Sanatorium Under the Sign of the Hourglass",
    creator: "Bruno Schulz",
    raw_date: "1937",
    form_note: "Polish short fiction collection",
    rationale: "Encyclopedia.com and Penguin Classics/PRH confirm Sanatorium Under the Sign of the Hourglass as Schulz's 1937 second surviving fiction collection.",
    sources: [
      ["x076_encyclopedia_com_sanatorium_hourglass", "Encyclopedia.com: Sanatorium Under the Sign of the Hourglass", "reference_encyclopedia", "Encyclopedia.com, Sanatorium Under the Sign of the Hourglass by Bruno Schulz, 1937, https://www.encyclopedia.com/arts/encyclopedias-almanacs-transcripts-and-maps/sanatorium-under-sign-hourglass-sanatorium-pod-klepsydra-bruno-schulz-1937", "Work reference entry", "https://www.encyclopedia.com/arts/encyclopedias-almanacs-transcripts-and-maps/sanatorium-under-sign-hourglass-sanatorium-pod-klepsydra-bruno-schulz-1937", "x076_encyclopedia_exact_sanatorium_hourglass", "0.55", "reference_support_for_sanatorium_hourglass"],
      ["x076_prh_schulz_complete_fiction_sanatorium", "Penguin Random House: The Street of Crocodiles and Other Stories", "publisher_reference_series", "Penguin Random House, The Street of Crocodiles and Other Stories by Bruno Schulz, https://www.penguinrandomhouse.com/books/293938/the-street-of-crocodiles-and-other-stories-by-bruno-schulz-foreword-by-jonathan-safran-foer-introduction-by-david-a-goldfarb-translated-by-celina-wieniewska/", "Penguin Classics complete fiction page", "https://www.penguinrandomhouse.com/books/293938/the-street-of-crocodiles-and-other-stories-by-bruno-schulz-foreword-by-jonathan-safran-foer-introduction-by-david-a-goldfarb-translated-by-celina-wieniewska/", "x076_prh_exact_sanatorium_hourglass", "0.55", "publisher_support_for_sanatorium_hourglass"],
      ["x076_prh_reading_guide_sanatorium", "Penguin Random House Reading Guide: Bruno Schulz", "language_literary_history", "Penguin Random House, The Street of Crocodiles and Other Stories Reading Guide, https://www.penguinrandomhouse.com/books/293938/the-street-of-crocodiles-and-other-stories-by-bruno-schulz-foreword-by-jonathan-safran-foer-introduction-by-david-a-goldfarb-translated-by-celina-wieniewska/9780143105145/readers-guide", "Penguin Classics reading guide", "https://www.penguinrandomhouse.com/books/293938/the-street-of-crocodiles-and-other-stories-by-bruno-schulz-foreword-by-jonathan-safran-foer-introduction-by-david-a-goldfarb-translated-by-celina-wieniewska/9780143105145/readers-guide", "x076_prh_guide_exact_sanatorium_hourglass", "0.55", "reading_guide_support_for_sanatorium_hourglass"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_pounamu_pounamu",
    title: "Pounamu Pounamu",
    creator: "Witi Ihimaera",
    raw_date: "1972",
    form_note: "New Zealand short story collection",
    rationale: "Britannica, Britannica's New Zealand literature article, and Penguin New Zealand confirm Pounamu Pounamu as Ihimaera's 1972 first story collection and a central modern New Zealand literature work.",
    sources: [
      ["x076_britannica_ihimaera_pounamu", "Britannica: Witi Ihimaera", "reference_encyclopedia", "Encyclopaedia Britannica, Witi Ihimaera, https://www.britannica.com/biography/Witi-Ihimaera", "Witi Ihimaera biography", "https://www.britannica.com/biography/Witi-Ihimaera", "x076_britannica_exact_pounamu", "0.55", "reference_support_for_pounamu_pounamu"],
      ["x076_britannica_nz_lit_pounamu", "Britannica: New Zealand Literature - Modern Maori literature", "language_literary_history", "Encyclopaedia Britannica, New Zealand literature - Modern Maori literature, https://www.britannica.com/art/New-Zealand-literature/Modern-Maori-literature", "New Zealand literature history section", "https://www.britannica.com/art/New-Zealand-literature/Modern-Maori-literature", "x076_britannica_lit_exact_pounamu", "0.55", "literary_history_support_for_pounamu_pounamu"],
      ["x076_penguin_nz_pounamu", "Penguin Books New Zealand: Pounamu Pounamu", "publisher_reference_series", "Penguin Books New Zealand, Pounamu Pounamu by Witi Ihimaera, https://www.penguin.co.nz/books/pounamu-pounamu-9780143010913", "Penguin New Zealand book page", "https://www.penguin.co.nz/books/pounamu-pounamu-9780143010913", "x076_penguin_nz_exact_pounamu", "0.55", "publisher_support_for_pounamu_pounamu"]
    ]
  },
  {
    work_id: "work_candidate_bloom_reviewed_barthelme_stories",
    title: "Sixty Stories",
    creator: "Donald Barthelme",
    raw_date: "1981",
    form_note: "American short story collection",
    rationale: "Britannica, Macmillan/Picador, and Library of America confirm Sixty Stories as Barthelme's major retrospective story collection.",
    sources: [
      ["x076_britannica_barthelme_sixty_stories", "Britannica: Donald Barthelme", "reference_encyclopedia", "Encyclopaedia Britannica, Donald Barthelme, https://www.britannica.com/biography/Donald-Barthelme", "Donald Barthelme biography", "https://www.britannica.com/biography/Donald-Barthelme", "x076_britannica_exact_sixty_stories", "0.55", "reference_support_for_sixty_stories"],
      ["x076_macmillan_sixty_stories", "Macmillan: Sixty Stories", "publisher_reference_series", "Macmillan, Sixty Stories by Donald Barthelme, https://us.macmillan.com/books/9781250420329/sixtystories/", "Picador book page", "https://us.macmillan.com/books/9781250420329/sixtystories/", "x076_macmillan_exact_sixty_stories", "0.55", "publisher_support_for_sixty_stories"],
      ["x076_loa_barthelme_collected_stories", "Library of America: Donald Barthelme Collected Stories", "scholarly_edition_series", "Library of America, Donald Barthelme: Collected Stories, https://www.loa.org/books/656-collected-stories/", "Library of America edition page", "https://www.loa.org/books/656-collected-stories/", "x076_loa_exact_sixty_stories", "0.35", "scholarly_edition_support_for_sixty_stories"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_red_ants",
    title: "Red Ants",
    creator: "Pergentino Jose",
    raw_date: "2012; English 2020",
    form_note: "Sierra Zapotec/Mexican short story collection",
    rationale: "Deep Vellum, Consortium, and reception coverage confirm Red Ants as Pergentino Jose's short story collection and the first literary translation into English from Sierra Zapotec.",
    sources: [
      ["x076_deep_vellum_red_ants", "Deep Vellum: Red Ants", "publisher_reference_series", "Deep Vellum, Red Ants by Pergentino Jose, https://store.deepvellum.org/products/red-ants", "Deep Vellum book page", "https://store.deepvellum.org/products/red-ants", "x076_deep_vellum_exact_red_ants", "0.55", "publisher_support_for_red_ants"],
      ["x076_consortium_red_ants", "Consortium Book Sales: Red Ants", "publisher_reference_series", "Consortium Book Sales & Distribution, Red Ants by Pergentino Jose, https://www.cbsd.com/9781646050192/red-ants/", "Consortium distribution page", "https://www.cbsd.com/9781646050192/red-ants/", "x076_consortium_exact_red_ants", "0.55", "publisher_support_for_red_ants"],
      ["x076_mexico_news_daily_red_ants", "Mexico News Daily: Zapotec author captures modern indigenous life", "prize_or_reception_layer", "Mexico News Daily, Zapotec author captures the troubled duality of modern indigenous life, https://mexiconewsdaily.com/mexico-living/zapotec-authors-captures-duality-of-indigenous-life/", "Reception article", "https://mexiconewsdaily.com/mexico-living/zapotec-authors-captures-duality-of-indigenous-life/", "x076_mexico_news_exact_red_ants", "0.35", "reception_support_for_red_ants"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_bloom_gap_031_0015_poems", "Poems", "Alcman", "Generic fragmentary corpus title; needs selected-fragment or corpus-scope policy."],
  ["work_candidate_global_lit_prison_notebooks_poems", "Poems from Prison", "Ho Chi Minh", "Likely title/scope correction to Prison Diary or Poems from the Prison Diary is needed before scoring."],
  ["work_candidate_me_lit_shmuel_hanagid_poems", "Selected Poems", "Samuel ha-Nagid", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_xin_qiji_ci", "Selected Ci Poems", "Xin Qiji", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_li_qingzhao_ci", "Selected Ci Poems", "Li Qingzhao", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0827_gogol_s_wife_and_other_stories", "Gogol's Wife and Other Stories", "Tommaso Landolfi", "Source support exists but remains mostly publisher/metadata/reception; defer until stricter corroboration or selected-story policy."],
  ["work_candidate_bloom_maupassant_selected_stories", "Boule de Suif and Selected Stories", "Guy de Maupassant", "Selected-stories row; needs edition/selection policy."],
  ["work_candidate_wave003_arnold_dover_beach", "Dover Beach and Selected Poems", "Matthew Arnold", "Selected-poems row; needs edition/selection policy."]
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
  source_id.sub(/\Ax076_/, "x076_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax076_/, "x076_ev_")
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
        "extraction_method" => "Targeted X076 exact-title public source review",
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
        "notes" => "X076 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X076 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

  manifest["status"] = "exact_title_external_rescue_x076_applied"
  artifacts["source_items"] = "e001_ingested_through_x076_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x076_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x076_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x076_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x076_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x076_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x076_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x076_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x076_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x076_from_current_x060_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x076_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x076"] = "generated_x076_for_exact_title_external_acquisition_rows"

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
  counts["x076_external_source_rescue_rows"] = applied_rows.size
  counts["x076_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x076"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x076"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x076_target_works_closed"],
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
    file.puts "# X076 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X076 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves selected-poems/stories rows and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X076 |"
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
    "applied_id" => "x076_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
    "scope" => "exact-title external-source rescue for eight current-path rows",
    "status" => "exact_title_external_source_rescue_applied",
    "gate" => "cut_and_replacement_review_still_required",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x076.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x076.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_060_x076_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X076 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
