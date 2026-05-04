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

PACKET_ID = "X074"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x074.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_058_x074_exact_title_external_rescue.md")

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
    work_id: "work_candidate_scale4_lit_ephrem_hymns_paradise",
    title: "Hymns on Paradise",
    creator: "Ephrem the Syrian",
    raw_date: "4th century; English edition 1990",
    form_note: "Syriac hymn sequence",
    rationale: "Publisher and Cambridge Core review evidence confirm the exact Hymns on Paradise scope.",
    sources: [
      ["x074_svspress_ephrem_hymns_paradise", "SVS Press: Hymns on Paradise: St. Ephrem the Syrian", "publisher_reference_series", "St Vladimir's Seminary Press, Hymns on Paradise: St. Ephrem the Syrian, https://svspress.com/hymns-on-paradise-st-ephrem-the-syrian/", "Hymns on Paradise book page", "https://svspress.com/hymns-on-paradise-st-ephrem-the-syrian/", "x074_svspress_exact_hymns_paradise", "0.35", "publisher_edition_support_for_ephrem_hymns_paradise"],
      ["x074_cambridge_ephrem_hymns_paradise_review", "Cambridge Core: Saint Ephrem. Hymns on Paradise review", "scholarly_edition_series", "Cambridge Core, The Journal of Ecclesiastical History, Saint Ephrem. Hymns on Paradise, https://www.cambridge.org/core/journals/journal-of-ecclesiastical-history/article/abs/saint-ephrem-hymns-on-paradise-introduction-and-translation-by-sebastian-brock-pp-240-crestwood-ny-st-vladimirs-seminary-press-1990-895-088141-076-4/59FC91D3A073C8585664B663B1DB7740", "Journal of Ecclesiastical History review page", "https://www.cambridge.org/core/journals/journal-of-ecclesiastical-history/article/abs/saint-ephrem-hymns-on-paradise-introduction-and-translation-by-sebastian-brock-pp-240-crestwood-ny-st-vladimirs-seminary-press-1990-895-088141-076-4/59FC91D3A073C8585664B663B1DB7740", "x074_cambridge_review_exact_hymns_paradise", "0.35", "scholarly_review_support_for_ephrem_hymns_paradise"]
    ]
  },
  {
    work_id: "work_candidate_southasia_lit_jatakamala",
    title: "Jatakamala",
    creator: "Arya Shura",
    raw_date: "c. 4th century",
    form_note: "Sanskrit Buddhist story collection",
    rationale: "University press editions confirm Arya Shura's Jatakamala as a thirty-four-story Sanskrit Buddhist work.",
    sources: [
      ["x074_nyupress_jatakamala_clay", "NYU Press: Garland of the Buddha's Past Lives", "scholarly_edition_series", "NYU Press, Garland of the Buddha's Past Lives, https://nyupress.org/9781479885831/garland-of-the-buddhas-past-lives-volume-1/", "Clay Sanskrit Library book page", "https://nyupress.org/9781479885831/garland-of-the-buddhas-past-lives-volume-1/", "x074_nyupress_jatakamala_clay_edition", "0.35", "scholarly_edition_support_for_jatakamala"],
      ["x074_uchicago_jatakamala_reference", "University of Chicago Press: Once the Buddha Was a Monkey", "publisher_reference_series", "University of Chicago Press, Once the Buddha Was a Monkey: Arya Sura's Jatakamala, https://press.uchicago.edu/ucp/books/book/chicago/O/bo3618407.html", "Once the Buddha Was a Monkey book page", "https://press.uchicago.edu/ucp/books/book/chicago/O/bo3618407.html", "x074_uchicago_exact_jatakamala_reference", "0.35", "publisher_edition_support_for_jatakamala"]
    ]
  },
  {
    work_id: "work_candidate_bloom_reviewed_in_our_time",
    title: "In Our Time",
    creator: "Ernest Hemingway",
    raw_date: "1925",
    form_note: "short story collection",
    rationale: "Reference, publisher, and Library of America evidence confirm Hemingway's 1925 story collection.",
    sources: [
      ["x074_britannica_hemingway_in_our_time", "Britannica: Ernest Hemingway", "reference_encyclopedia", "Encyclopaedia Britannica, Ernest Hemingway, https://www.britannica.com/biography/Ernest-Hemingway", "Hemingway biography", "https://www.britannica.com/biography/Ernest-Hemingway", "x074_britannica_hemingway_in_our_time_reference", "0.55", "reference_support_for_in_our_time"],
      ["x074_prh_hemingway_in_our_time", "Penguin Random House: In Our Time", "publisher_reference_series", "Penguin Random House, In Our Time by Ernest Hemingway, https://www.penguinrandomhouse.com/books/659748/in-our-time-by-ernest-hemingway/9780593311820/", "In Our Time book page", "https://www.penguinrandomhouse.com/books/659748/in-our-time-by-ernest-hemingway/9780593311820/", "x074_prh_exact_in_our_time_reference", "0.35", "publisher_support_for_in_our_time"],
      ["x074_loa_hemingway_in_our_time", "Library of America: The Sun Also Rises & Other Writings 1918-1926", "authoritative_collection", "Library of America, The Sun Also Rises & Other Writings 1918-1926, https://www.loa.org/books/634-the-sun-also-rises-amp-other-writings-1918-1926/", "Library of America volume page", "https://www.loa.org/books/634-the-sun-also-rises-amp-other-writings-1918-1926/", "x074_loa_in_our_time_authoritative_collection", "0.35", "authoritative_collection_support_for_in_our_time"]
    ]
  },
  {
    work_id: "work_candidate_bloom_oconnor_complete_stories",
    title: "Complete Stories",
    creator: "Flannery O'Connor",
    raw_date: "1971",
    form_note: "short story collection",
    rationale: "Britannica and National Book Foundation evidence confirm O'Connor's posthumous Complete Stories and its 1972 National Book Award.",
    sources: [
      ["x074_britannica_oconnor_complete_stories", "Britannica: Flannery O'Connor", "reference_encyclopedia", "Encyclopaedia Britannica, Flannery O'Connor, https://www.britannica.com/biography/Flannery-OConnor", "Flannery O'Connor biography", "https://www.britannica.com/biography/Flannery-OConnor", "x074_britannica_oconnor_complete_stories_reference", "0.55", "reference_support_for_oconnor_complete_stories"],
      ["x074_nbf_oconnor_complete_stories", "National Book Foundation: The Complete Stories of Flannery O'Connor", "prize_or_reception_layer", "National Book Foundation, The Complete Stories of Flannery O'Connor, https://www.nationalbook.org/books/the-complete-stories-of-flannery-oconnor/", "National Book Award archive page", "https://www.nationalbook.org/books/the-complete-stories-of-flannery-oconnor/", "x074_nbf_oconnor_complete_stories_award_reference", "0.35", "award_reception_support_for_oconnor_complete_stories"]
    ]
  },
  {
    work_id: "work_candidate_completion_lit_gimpel_fool",
    title: "Gimpel the Fool and Other Stories",
    creator: "Isaac Bashevis Singer",
    raw_date: "1957",
    form_note: "short story collection",
    rationale: "Britannica and Encyclopedia.com evidence confirm the title story and 1957 collection scope.",
    sources: [
      ["x074_britannica_gimpel_work_reference", "Britannica: Gimpel the Fool", "reference_encyclopedia", "Encyclopaedia Britannica, Gimpel the Fool, https://www.britannica.com/topic/Gimpel-the-Fool", "Gimpel the Fool work page", "https://www.britannica.com/topic/Gimpel-the-Fool", "x074_britannica_gimpel_collection_reference", "0.55", "reference_support_for_gimpel_collection"],
      ["x074_britannica_yiddish_lit_singer_gimpel", "Britannica: Yiddish literature, Writers in New York", "language_literary_history", "Encyclopaedia Britannica, Yiddish literature: Writers in New York, https://www.britannica.com/art/Yiddish-literature/Writers-in-New-York", "Yiddish literature overview", "https://www.britannica.com/art/Yiddish-literature/Writers-in-New-York", "x074_britannica_yiddish_lit_gimpel_reference", "0.55", "literary_history_support_for_gimpel_collection"],
      ["x074_encyclopedia_com_gimpel_reference", "Encyclopedia.com: Gimpel the Fool", "reference_encyclopedia", "Encyclopedia.com, Gimpel the Fool, https://www.encyclopedia.com/education/news-wires-white-papers-and-books/gimpel-fool", "Gimpel the Fool reference page", "https://www.encyclopedia.com/education/news-wires-white-papers-and-books/gimpel-fool", "x074_encyclopedia_com_gimpel_reference", "0.55", "reference_support_for_gimpel_collection"]
    ]
  },
  {
    work_id: "work_candidate_global_lit_krik_krak",
    title: "Krik? Krak!",
    creator: "Edwidge Danticat",
    raw_date: "1995",
    form_note: "short story collection",
    rationale: "Reference, publisher, and National Book Foundation evidence confirm the Danticat collection and award status.",
    sources: [
      ["x074_britannica_danticat_krik_krak", "Britannica: Edwidge Danticat", "reference_encyclopedia", "Encyclopaedia Britannica, Edwidge Danticat, https://www.britannica.com/biography/Edwidge-Danticat", "Edwidge Danticat biography", "https://www.britannica.com/biography/Edwidge-Danticat", "x074_britannica_danticat_krik_krak_reference", "0.55", "reference_support_for_krik_krak"],
      ["x074_soho_krik_krak", "Soho Press: Krik? Krak!", "publisher_reference_series", "Soho Press, Krik? Krak!, https://sohopress.com/books/krik-krak/", "Krik? Krak! book page", "https://sohopress.com/books/krik-krak/", "x074_soho_exact_krik_krak_reference", "0.35", "publisher_support_for_krik_krak"],
      ["x074_nbf_danticat_krik_krak", "National Book Foundation: Edwidge Danticat", "prize_or_reception_layer", "National Book Foundation, Edwidge Danticat, https://www.nationalbook.org/people/edwidge-danticat/", "Edwidge Danticat NBF page", "https://www.nationalbook.org/people/edwidge-danticat/", "x074_nbf_krik_krak_award_reference", "0.35", "award_reception_support_for_krik_krak"]
    ]
  },
  {
    work_id: "work_candidate_eastasia_lit_cursed_bunny",
    title: "Cursed Bunny",
    creator: "Bora Chung",
    raw_date: "2017; English 2022",
    form_note: "short story collection",
    rationale: "National Book Foundation and Booker evidence confirm the translated collection and its reception.",
    sources: [
      ["x074_nbf_cursed_bunny", "National Book Foundation: Cursed Bunny", "prize_or_reception_layer", "National Book Foundation, Cursed Bunny, https://www.nationalbook.org/books/cursed-bunny/", "Cursed Bunny National Book Award page", "https://www.nationalbook.org/books/cursed-bunny/", "x074_nbf_cursed_bunny_award_reference", "0.35", "award_reception_support_for_cursed_bunny"],
      ["x074_booker_cursed_bunny", "The Booker Prizes: 2022 International Booker shortlist press release", "prize_or_reception_layer", "The Booker Prizes, 2022 International Booker Prize shortlist announced, https://thebookerprizes.com/sites/default/files/2022-04/2022%20International%20Booker%20shortlist%20announced%20-%20FOR%20IMMEDIATE%20RELEASE%20.pdf", "2022 International Booker shortlist press release", "https://thebookerprizes.com/sites/default/files/2022-04/2022%20International%20Booker%20shortlist%20announced%20-%20FOR%20IMMEDIATE%20RELEASE%20.pdf", "x074_booker_cursed_bunny_shortlist_reference", "0.35", "booker_reception_support_for_cursed_bunny"]
    ]
  },
  {
    work_id: "work_candidate_globalcon_lit_her_body",
    title: "Her Body and Other Parties",
    creator: "Carmen Maria Machado",
    raw_date: "2017",
    form_note: "short story collection",
    rationale: "Publisher, National Book Foundation, and NBCC evidence confirm Machado's debut collection and reception.",
    sources: [
      ["x074_graywolf_her_body", "Graywolf Press: Her Body and Other Parties", "publisher_reference_series", "Graywolf Press, Her Body and Other Parties, https://www.graywolfpress.org/books/her-body-and-other-parties", "Her Body and Other Parties book page", "https://www.graywolfpress.org/books/her-body-and-other-parties", "x074_graywolf_exact_her_body_reference", "0.35", "publisher_support_for_her_body"],
      ["x074_nbf_her_body", "National Book Foundation: Her Body and Other Parties", "prize_or_reception_layer", "National Book Foundation, Her Body and Other Parties, https://www.nationalbook.org/books/her-body-and-other-parties/", "National Book Award archive page", "https://www.nationalbook.org/books/her-body-and-other-parties/", "x074_nbf_her_body_award_reference", "0.35", "award_reception_support_for_her_body"],
      ["x074_nbcc_her_body_john_leonard", "National Book Critics Circle: Carmen Maria Machado, John Leonard Award Winner", "prize_or_reception_layer", "National Book Critics Circle, Carmen Maria Machado, John Leonard Award Winner, https://www.bookcritics.org/2018/03/21/carmen-maria-machado-john-leonard-award-winner/", "NBCC John Leonard Award page", "https://www.bookcritics.org/2018/03/21/carmen-maria-machado-john-leonard-award-winner/", "x074_nbcc_her_body_award_reference", "0.35", "award_reception_support_for_her_body"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_bloom_gap_031_0015_poems", "Poems", "Alcman", "Generic fragmentary corpus title; needs selected-fragment or corpus-scope policy."],
  ["work_candidate_me_lit_shmuel_hanagid_poems", "Selected Poems", "Samuel ha-Nagid", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_xin_qiji_ci", "Selected Ci Poems", "Xin Qiji", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_li_qingzhao_ci", "Selected Ci Poems", "Li Qingzhao", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_southasia_lit_angarey", "Angarey", "Sajjad Zaheer, Rashid Jahan, Ahmed Ali, and Mahmuduzzafar", "Exact title, but source set still needs cleaner independent support before acceptance."]
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
  source_id.sub(/\Ax074_/, "x074_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax074_/, "x074_ev_")
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
        "edition" => "online reference or edition page",
        "editors_or_authors" => target.fetch(:creator),
        "publisher" => source_title.split(":").first,
        "coverage_limits" => "Build-layer source-debt support only; no cut or replacement approval.",
        "extraction_method" => "Targeted X074 exact-title public source review",
        "packet_ids" => PACKET_ID,
        "extraction_status" => "extracted",
        "notes" => "Supports #{target.fetch(:form_note)} identity and external reception/source debt closure."
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
        "notes" => "X074 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X074 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

def update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
  return unless File.exist?(MANIFEST_PATH)

  manifest = YAML.load_file(MANIFEST_PATH)
  artifacts = manifest.fetch("artifacts")
  counts = manifest.fetch("current_counts")
  source_item_rows_after = read_tsv(SOURCE_ITEMS_PATH)
  scoring_input_rows = read_tsv(File.join(TABLE_DIR, "canon_scoring_inputs.tsv"))

  manifest["status"] = "exact_title_external_rescue_x074_applied"
  artifacts["source_items"] = "e001_ingested_through_x074_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x074_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x074_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x074_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x074_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x074_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x074_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x074_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x074_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x074_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x074_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x074"] = "generated_x074_for_exact_title_external_acquisition_rows"

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
  counts["x074_external_source_rescue_rows"] = applied_rows.size
  counts["x074_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x074"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x074"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x074_target_works_closed"],
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
    file.puts "# X074 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X074 closes exact-title source-debt blockers for rows with stable, independently verifiable public source support. It defers selected-poems rows and one source-uncertain exact title rather than forcing weak support."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X074 |"
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
    "applied_id" => "x074_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x074.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x074.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_058_x074_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X074 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
