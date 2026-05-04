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

PACKET_ID = "X077"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x077.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_061_x077_exact_title_external_rescue.md")

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
    work_id: "work_candidate_mandatory_feng_menglong_stories",
    title: "Stories Old and New",
    creator: "Feng Menglong",
    raw_date: "1620",
    form_note: "Ming vernacular story collection",
    rationale: "University of Washington Press and De Gruyter/Brill confirm Stories Old and New as Feng Menglong's 1620 Gujin xiaoshuo/Yushi mingyan collection.",
    sources: [
      ["x077_uw_press_stories_old_and_new", "University of Washington Press: Stories Old and New", "publisher_reference_series", "University of Washington Press, Stories Old and New, https://uwapress.uw.edu/book/9780295995823/stories-old-and-new/", "University of Washington Press book page", "https://uwapress.uw.edu/book/9780295995823/stories-old-and-new/", "x077_uw_press_exact_stories_old_new", "0.55", "publisher_support_for_stories_old_and_new"],
      ["x077_degruyter_stories_old_and_new", "De Gruyter Brill: Stories Old and New", "scholarly_edition_series", "De Gruyter Brill, Stories Old and New, https://www.degruyterbrill.com/document/doi/10.1515/9780295801285/html", "De Gruyter Brill edition page", "https://www.degruyterbrill.com/document/doi/10.1515/9780295801285/html", "x077_degruyter_exact_stories_old_new", "0.35", "scholarly_edition_support_for_stories_old_and_new"]
    ]
  },
  {
    work_id: "work_candidate_scale5_lit_sherlock_holmes",
    title: "The Adventures of Sherlock Holmes",
    creator: "Arthur Conan Doyle",
    raw_date: "1892",
    form_note: "British detective short story collection",
    rationale: "Britannica and Sherlock Holmes reference evidence confirm The Adventures of Sherlock Holmes as Conan Doyle's 1892 collection of twelve Sherlock Holmes tales.",
    sources: [
      ["x077_britannica_adventures_sherlock_holmes", "Britannica: The Adventures of Sherlock Holmes", "reference_encyclopedia", "Encyclopaedia Britannica, The Adventures of Sherlock Holmes by Conan Doyle, https://www.britannica.com/topic/The-Adventures-of-Sherlock-Holmes-by-Conan-Doyle", "Work reference entry", "https://www.britannica.com/topic/The-Adventures-of-Sherlock-Holmes-by-Conan-Doyle", "x077_britannica_exact_adventures_sherlock", "0.55", "reference_support_for_adventures_sherlock_holmes"],
      ["x077_britannica_dr_watson_sherlock_collection", "Britannica: Dr. Watson", "reference_encyclopedia", "Encyclopaedia Britannica, Dr. Watson, https://www.britannica.com/topic/Dr-Watson", "Character reference entry", "https://www.britannica.com/topic/Dr-Watson", "x077_britannica_watson_exact_adventures_sherlock", "0.55", "reference_support_for_adventures_sherlock_holmes"]
    ]
  },
  {
    work_id: "work_candidate_eastasia_lit_taipei_people",
    title: "Taipei People",
    creator: "Pai Hsien-yung",
    raw_date: "1971",
    form_note: "Taiwanese Chinese short story collection",
    rationale: "Columbia University Press and Chinese University Press paratext confirm Taipei People as Pai Hsien-yung's fourteen-story collection and a major modern Chinese/Taiwan literature work.",
    sources: [
      ["x077_cup_taipei_people", "Columbia University Press: Taipei People", "publisher_reference_series", "Columbia University Press, Taipei People, https://cup.columbia.edu/book/taipei-people/9789882370067/", "Columbia University Press book page", "https://cup.columbia.edu/book/taipei-people/9789882370067/", "x077_cup_exact_taipei_people", "0.55", "publisher_support_for_taipei_people"],
      ["x077_cuhk_taipei_people_preface", "Chinese University Press: Taipei People Preface", "language_literary_history", "Chinese University Press, Taipei People Preface, https://cup.cuhk.edu.hk/image/data/preview/9789882370067_Preface.pdf", "Chinese University Press preface", "https://cup.cuhk.edu.hk/image/data/preview/9789882370067_Preface.pdf", "x077_cuhk_preface_exact_taipei_people", "0.55", "publisher_paratext_support_for_taipei_people"]
    ]
  },
  {
    work_id: "work_candidate_globalcon_lit_bloody_chamber",
    title: "The Bloody Chamber",
    creator: "Angela Carter",
    raw_date: "1979",
    form_note: "British feminist Gothic short story collection",
    rationale: "Britannica and Penguin Random House confirm The Bloody Chamber as Carter's celebrated 1979 fairy-tale story collection.",
    sources: [
      ["x077_britannica_angela_carter_bloody_chamber", "Britannica: Angela Carter", "reference_encyclopedia", "Encyclopaedia Britannica, Angela Carter, https://www.britannica.com/biography/Angela-Carter", "Angela Carter biography", "https://www.britannica.com/biography/Angela-Carter", "x077_britannica_exact_bloody_chamber", "0.55", "reference_support_for_bloody_chamber"],
      ["x077_random_house_bloody_chamber", "Random House: The Bloody Chamber", "publisher_reference_series", "Random House Publishing Group, The Bloody Chamber by Angela Carter, https://www.randomhousebooks.com/books/308852", "Penguin Classics Deluxe Edition page", "https://www.randomhousebooks.com/books/308852", "x077_random_house_exact_bloody_chamber", "0.55", "publisher_support_for_bloody_chamber"],
      ["x077_prh_horror_classics_bloody_chamber", "Penguin Random House: Horror Classics You Need To Read", "prize_or_reception_layer", "Penguin Random House, Horror Classics You Need To Read, https://www.penguinrandomhouse.com/the-read-down/horror-classics-you-need-to-read/", "Penguin Random House curated reading list", "https://www.penguinrandomhouse.com/the-read-down/horror-classics-you-need-to-read/", "x077_prh_list_exact_bloody_chamber", "0.35", "publisher_reception_support_for_bloody_chamber"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0827_gogol_s_wife_and_other_stories",
    title: "Gogol's Wife and Other Stories",
    creator: "Tommaso Landolfi",
    raw_date: "1961; English 1963",
    form_note: "Italian short story collection in translation",
    rationale: "Google Books/New Directions and Time review coverage confirm Gogol's Wife and Other Stories as Landolfi's New Directions story collection in English.",
    sources: [
      ["x077_google_books_gogols_wife", "Google Books: Gogol's Wife and Other Stories", "publisher_reference_series", "Google Books, Gogol's Wife and Other Stories by Tommaso Landolfi, https://books.google.com/books/about/Gogol_s_Wife_Other_Stories.html?id=Bjyd5WfLlf0C", "Google Books title record", "https://books.google.com/books/about/Gogol_s_Wife_Other_Stories.html?id=Bjyd5WfLlf0C", "x077_google_books_exact_gogols_wife", "0.55", "publisher_record_support_for_gogols_wife"],
      ["x077_time_gogols_wife_review", "Time: Of Beasts & Men", "prize_or_reception_layer", "Time, Books: Of Beasts & Men, https://content.time.com/time/subscriber/article/0,33009,898142,00.html", "Time review", "https://content.time.com/time/subscriber/article/0,33009,898142,00.html", "x077_time_exact_gogols_wife", "0.35", "reception_support_for_gogols_wife"]
    ]
  },
  {
    work_id: "work_candidate_global_lit_tales_tikongs",
    title: "Tales of the Tikongs",
    creator: "Epeli Hau'ofa",
    raw_date: "1983; UH Press 1994",
    form_note: "Pacific Islander satirical short story collection",
    rationale: "University of Hawaii Press, Google Books, and Los Angeles Times coverage confirm Tales of the Tikongs as Epeli Hau'ofa's Pacific satire collection.",
    sources: [
      ["x077_uhpress_tales_tikongs", "University of Hawaii Press: Tales of the Tikongs", "publisher_reference_series", "University of Hawaii Press, Tales of the Tikongs, https://uhpress.hawaii.edu/title/tales-of-the-tikongs/?attribute_pa_format=paperback", "University of Hawaii Press book page", "https://uhpress.hawaii.edu/title/tales-of-the-tikongs/?attribute_pa_format=paperback", "x077_uhpress_exact_tales_tikongs", "0.55", "publisher_support_for_tales_tikongs"],
      ["x077_google_books_tales_tikongs", "Google Books: Tales of the Tikongs", "publisher_reference_series", "Google Books, Tales of the Tikongs by Epeli Hau'ofa, https://books.google.com/books/about/Tales_of_the_Tikongs.html?id=sUkWYJ6JplwC", "Google Books title record", "https://books.google.com/books/about/Tales_of_the_Tikongs.html?id=sUkWYJ6JplwC", "x077_google_books_exact_tales_tikongs", "0.55", "publisher_record_support_for_tales_tikongs"],
      ["x077_lat_tales_tikongs_review", "Los Angeles Times: Tales of the Tikongs", "prize_or_reception_layer", "Los Angeles Times, Tales of the Tikongs by Epeli Hau'ofa, https://www.latimes.com/archives/la-xpm-1994-09-18-bk-39847-story.html", "Los Angeles Times review", "https://www.latimes.com/archives/la-xpm-1994-09-18-bk-39847-story.html", "x077_lat_exact_tales_tikongs", "0.35", "reception_support_for_tales_tikongs"]
    ]
  },
  {
    work_id: "work_candidate_latcarib_lit_summer_lightning",
    title: "Summer Lightning",
    creator: "Olive Senior",
    raw_date: "1986",
    form_note: "Jamaican short story collection",
    rationale: "Dublin Literary Award author profile, Google Books, and Writers' Trust confirm Summer Lightning as Olive Senior's 1986 Commonwealth Writers' Prize-winning first story collection.",
    sources: [
      ["x077_dublin_literary_olive_senior_summer_lightning", "Dublin Literary Award: Olive Senior", "prize_or_reception_layer", "Dublin Literary Award, Olive Senior, https://dublinliteraryaward.ie/the-library/authors/olive-senior/", "Author profile", "https://dublinliteraryaward.ie/the-library/authors/olive-senior/", "x077_dublin_exact_summer_lightning", "0.55", "prize_reception_support_for_summer_lightning"],
      ["x077_google_books_summer_lightning", "Google Books: Summer Lightning and Other Stories", "publisher_reference_series", "Google Books, Summer Lightning: And Other Stories by Olive Senior, https://books.google.com/books/about/Summer_Lightning.html?id=4cdyAAAAMAAJ", "Google Books title record", "https://books.google.com/books/about/Summer_Lightning.html?id=4cdyAAAAMAAJ", "x077_google_books_exact_summer_lightning", "0.55", "publisher_record_support_for_summer_lightning"],
      ["x077_writers_trust_olive_senior_summer_lightning", "Writers' Trust of Canada: Olive Senior", "prize_or_reception_layer", "Writers' Trust of Canada, Olive Senior, https://www.writerstrust.com/authors/olive-senior", "Author profile", "https://www.writerstrust.com/authors/olive-senior", "x077_writers_trust_exact_summer_lightning", "0.55", "prize_reception_support_for_summer_lightning"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_road_allowance",
    title: "Stories of the Road Allowance People",
    creator: "Maria Campbell",
    raw_date: "1995; revised 2010",
    form_note: "Metis oral story collection",
    rationale: "Gabriel Dumont Institute, GoodMinds, and Google Books confirm Stories of the Road Allowance People as Maria Campbell's Michif oral-story collection.",
    sources: [
      ["x077_gdi_road_allowance", "Gabriel Dumont Institute: Stories of the Road Allowance People", "publisher_reference_series", "Gabriel Dumont Institute, Stories of the Road Allowance People: The Revised Edition, https://gdins.org/product/stories-of-the-road-allowance-people-the-revised-edition/", "Gabriel Dumont Institute book page", "https://gdins.org/product/stories-of-the-road-allowance-people-the-revised-edition/", "x077_gdi_exact_road_allowance", "0.55", "publisher_support_for_road_allowance"],
      ["x077_goodminds_road_allowance", "GoodMinds: Stories of the Road Allowance People", "publisher_reference_series", "GoodMinds, Stories of the Road Allowance People, https://www.goodminds.com/products/9780920915998", "GoodMinds book page", "https://www.goodminds.com/products/9780920915998", "x077_goodminds_exact_road_allowance", "0.55", "publisher_support_for_road_allowance"],
      ["x077_google_books_road_allowance", "Google Books: Stories of the Road Allowance People", "publisher_reference_series", "Google Books, Stories of the Road Allowance People, https://books.google.com/books/about/Stories_of_the_Road_Allowance_People.html?id=_orYAAAAMAAJ", "Google Books title record", "https://books.google.com/books/about/Stories_of_the_Road_Allowance_People.html?id=_orYAAAAMAAJ", "x077_google_books_exact_road_allowance", "0.55", "publisher_record_support_for_road_allowance"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_bloom_gap_031_0015_poems", "Poems", "Alcman", "Generic fragmentary corpus title; needs selected-fragment or corpus-scope policy."],
  ["work_candidate_global_lit_prison_notebooks_poems", "Poems from Prison", "Ho Chi Minh", "Likely title/scope correction to Prison Diary or Poems from the Prison Diary is needed before scoring."],
  ["work_candidate_scale2_lit_sonnets_to_orpheus", "Sonnets to Orpheus", "Rainer Maria Rilke", "Existing source items are Archaic Torso of Apollo only; this does not close source debt for Sonnets to Orpheus."],
  ["work_candidate_me_lit_shmuel_hanagid_poems", "Selected Poems", "Samuel ha-Nagid", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_xin_qiji_ci", "Selected Ci Poems", "Xin Qiji", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_li_qingzhao_ci", "Selected Ci Poems", "Li Qingzhao", "Selected-poems row; needs edition/selection policy."],
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
  source_id.sub(/\Ax077_/, "x077_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax077_/, "x077_ev_")
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
        "extraction_method" => "Targeted X077 exact-title public source review",
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
        "notes" => "X077 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X077 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

  manifest["status"] = "exact_title_external_rescue_x077_applied"
  artifacts["source_items"] = "e001_ingested_through_x077_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x077_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x077_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x077_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x077_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x077_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x077_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x077_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x077_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x077_from_current_x061_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x077_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x077"] = "generated_x077_for_exact_title_external_acquisition_rows"

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
  counts["x077_external_source_rescue_rows"] = applied_rows.size
  counts["x077_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x077"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x077"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x077_target_works_closed"],
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
    file.puts "# X077 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X077 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves selected-poems/stories rows and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X077 |"
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
    "applied_id" => "x077_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x077.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x077.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_061_x077_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X077 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
