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

PACKET_ID = "X081"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x081.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_065_x081_exact_title_external_rescue.md")

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
    work_id: "work_candidate_completion_lit_women_algiers_apartment",
    title: "Women of Algiers in Their Apartment",
    creator: "Assia Djebar",
    raw_date: "1980 French original; English translation 1992",
    form_note: "Algerian Francophone story collection",
    rationale: "University of Virginia Press and Publishers Weekly both support Women of Algiers in Their Apartment as Djebar's six-story-and-postface collection in English translation; the existing local source items are only excerpts/components and are not sufficient by themselves.",
    sources: [
      ["x081_uva_women_algiers", "UVA Press: Women of Algiers in Their Apartment", "publisher_reference_series", "University of Virginia Press, Women of Algiers in Their Apartment, https://www.upress.virginia.edu/title/3196/", "University of Virginia Press book page", "https://www.upress.virginia.edu/title/3196/", "x081_uva_exact_women_algiers", "0.55", "publisher_support_for_women_algiers"],
      ["x081_pw_women_algiers", "Publishers Weekly: Women of Algiers in Their Apartment", "prize_or_reception_layer", "Publishers Weekly, Women of Algiers in Their Apartment, https://www.publishersweekly.com/9780813914022", "Publishers Weekly review", "https://www.publishersweekly.com/9780813914022", "x081_pw_exact_women_algiers", "0.55", "review_support_for_women_algiers"]
    ]
  },
  {
    work_id: "work_candidate_wave004_bunin_dark_avenues",
    title: "Dark Avenues",
    creator: "Ivan Bunin",
    raw_date: "1943 partial collection; 1946 fuller edition",
    form_note: "Russian emigre short story collection",
    rationale: "Bloomsbury/Alma and Britannica independently identify Dark Avenues as Bunin's late short-story collection and a major twentieth-century Russian emigre work.",
    sources: [
      ["x081_bloomsbury_bunin_dark_avenues", "Bloomsbury: Dark Avenues", "publisher_reference_series", "Bloomsbury, Dark Avenues by Ivan Bunin, https://www.bloomsbury.com/uk/dark-avenues-9781847494740/", "Bloomsbury/Alma Classics book page", "https://www.bloomsbury.com/uk/dark-avenues-9781847494740/", "x081_bloomsbury_exact_bunin_dark_avenues", "0.55", "publisher_support_for_bunin_dark_avenues"],
      ["x081_britannica_bunin_dark_avenues", "Britannica: Ivan Bunin", "reference_encyclopedia", "Britannica, Ivan Bunin, https://www.britannica.com/biography/Ivan-Bunin", "Britannica author biography", "https://www.britannica.com/biography/Ivan-Bunin", "x081_britannica_exact_bunin_dark_avenues", "0.55", "reference_support_for_bunin_dark_avenues"]
    ]
  },
  {
    work_id: "work_candidate_wave004_miguel_hernandez_el_rayo_que_no_cesa",
    title: "El rayo que no cesa",
    creator: "Miguel Hernandez",
    raw_date: "1936",
    form_note: "Spanish poetry collection",
    rationale: "Biblioteca Virtual Miguel de Cervantes gives the text record and Britannica identifies El rayo que no cesa as Hernandez's best work, mostly a collection of sonnets.",
    sources: [
      ["x081_cervantes_el_rayo", "Biblioteca Virtual Miguel de Cervantes: El rayo que no cesa", "language_literary_history", "Biblioteca Virtual Miguel de Cervantes, El rayo que no cesa, https://www.cervantesvirtual.com/obra-visor/el-rayo-que-no-cesa-1057848/html/71430300-911c-4f9c-ad06-e1cb831439dc_2.html", "Biblioteca Virtual Miguel de Cervantes text record", "https://www.cervantesvirtual.com/obra-visor/el-rayo-que-no-cesa-1057848/html/71430300-911c-4f9c-ad06-e1cb831439dc_2.html", "x081_cervantes_exact_el_rayo", "0.55", "library_reference_support_for_el_rayo"],
      ["x081_britannica_hernandez_el_rayo", "Britannica: Miguel Hernandez", "reference_encyclopedia", "Britannica, Miguel Hernandez, https://www.britannica.com/biography/Miguel-Hernandez", "Britannica author biography", "https://www.britannica.com/biography/Miguel-Hernandez", "x081_britannica_exact_hernandez_el_rayo", "0.55", "reference_support_for_el_rayo"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_coyote_stories_mourning_dove",
    title: "Coyote Stories",
    creator: "Mourning Dove",
    raw_date: "1933; Bison Books edition 1990",
    form_note: "Native American/Okanagan story collection",
    rationale: "University of Nebraska Press and Encyclopedia.com both support Coyote Stories as Mourning Dove's collected Coyote narratives, with Nebraska giving the Bison Books scholarly reprint context and Encyclopedia.com confirming the 1933 work in the author bibliography.",
    sources: [
      ["x081_nebraska_coyote_stories", "University of Nebraska Press: Coyote Stories", "publisher_reference_series", "University of Nebraska Press, Coyote Stories by Mourning Dove, https://www.nebraskapress.unl.edu/bison-books/9780803281691/coyote-stories/", "University of Nebraska Press book page", "https://www.nebraskapress.unl.edu/bison-books/9780803281691/coyote-stories/", "x081_nebraska_exact_coyote_stories", "0.55", "publisher_support_for_coyote_stories"],
      ["x081_encyclopedia_mourning_dove_coyote", "Encyclopedia.com: Mourning Dove", "reference_encyclopedia", "Encyclopedia.com, Mourning Dove (c. 1888-1936), https://www.encyclopedia.com/women/encyclopedias-almanacs-transcripts-and-maps/mourning-dove-c-1888-1936", "Reference biography", "https://www.encyclopedia.com/women/encyclopedias-almanacs-transcripts-and-maps/mourning-dove-c-1888-1936", "x081_encyclopedia_exact_mourning_dove_coyote", "0.55", "reference_support_for_coyote_stories"]
    ]
  },
  {
    work_id: "work_candidate_euro_under_lit_winters_tales",
    title: "Winter's Tales",
    creator: "Karen Blixen",
    raw_date: "1942",
    form_note: "Danish short story collection published in English as Isak Dinesen",
    rationale: "Penguin Random House and Britannica both identify Winter's Tales as Isak Dinesen/Karen Blixen's 1942 short-story collection; the creator alias should remain visible in later display cleanup.",
    sources: [
      ["x081_prh_winters_tales", "Penguin Random House: Winter's Tales", "publisher_reference_series", "Penguin Random House, Winter's Tales by Isak Dinesen, https://www.penguinrandomhouse.com/books/41100/winters-tales-by-isak-dinesen/", "Penguin Random House book page", "https://www.penguinrandomhouse.com/books/41100/winters-tales-by-isak-dinesen/", "x081_prh_exact_winters_tales", "0.55", "publisher_support_for_winters_tales"],
      ["x081_britannica_winters_tales", "Britannica: Winter's Tales", "reference_encyclopedia", "Britannica, Winter's Tales, https://www.britannica.com/topic/Winters-Tales", "Britannica work entry", "https://www.britannica.com/topic/Winters-Tales", "x081_britannica_exact_winters_tales", "0.55", "reference_support_for_winters_tales"]
    ]
  },
  {
    work_id: "work_candidate_africa_lit_cape_town_wicomb",
    title: "You Can't Get Lost in Cape Town",
    creator: "Zoe Wicomb",
    raw_date: "1987",
    form_note: "South African linked story collection",
    rationale: "Feminist Press and EBSCO both support You Can't Get Lost in Cape Town as Wicomb's apartheid-era linked-story collection; this closes source debt but leaves no public replacement decision implied.",
    sources: [
      ["x081_feminist_press_wicomb_cape_town", "Feminist Press: You Can't Get Lost in Cape Town", "publisher_reference_series", "Feminist Press, You Can't Get Lost in Cape Town, https://www.feministpress.org/books-n-z/you-cant-get-lost-in-cape-town", "Feminist Press book page", "https://www.feministpress.org/books-n-z/you-cant-get-lost-in-cape-town", "x081_feminist_press_exact_wicomb_cape_town", "0.55", "publisher_support_for_wicomb_cape_town"],
      ["x081_ebsco_wicomb_cape_town", "EBSCO: You Can't Get Lost in Cape Town", "language_literary_history", "EBSCO Research Starters, You Can't Get Lost in Cape Town by Zoe Wicomb, https://www.ebsco.com/research-starters/literature-and-writing/you-cant-get-lost-cape-town-zoe-wicomb", "EBSCO literature research-starter entry", "https://www.ebsco.com/research-starters/literature-and-writing/you-cant-get-lost-cape-town-zoe-wicomb", "x081_ebsco_exact_wicomb_cape_town", "0.55", "literary_history_support_for_wicomb_cape_town"]
    ]
  },
  {
    work_id: "work_candidate_bloom_poe_tales",
    title: "Tales",
    creator: "Edgar Allan Poe",
    raw_date: "1845",
    form_note: "American short story collection",
    rationale: "The Edgar Allan Poe Society and Google Books both support the exact 1845 Wiley and Putnam Tales volume; the display title is generic, so later title-scope policy should retain the 1845 edition context.",
    sources: [
      ["x081_poe_society_tales_1845", "Edgar Allan Poe Society: Tales (1845)", "language_literary_history", "Edgar Allan Poe Society of Baltimore, Tales (1845), https://www.eapoe.org/works/editions/tales.htm", "Poe Society bibliographic edition page", "https://www.eapoe.org/works/editions/tales.htm", "x081_poe_society_exact_tales_1845", "0.55", "bibliographic_support_for_poe_tales_1845"],
      ["x081_google_books_poe_tales_1845", "Google Books: Tales (1845)", "publisher_reference_series", "Google Books, Tales by Edgar Allan Poe, Wiley and Putnam, 1845, https://books.google.com/books/about/Tales.html?id=nQ0EAAAAQAAJ", "Google Books 1845 title record", "https://books.google.com/books/about/Tales.html?id=nQ0EAAAAQAAJ", "x081_google_books_exact_poe_tales_1845", "0.55", "publisher_record_support_for_poe_tales_1845"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_southasia_lit_tukaram_abhangas", "Selected Abhangas", "Tukaram", "Existing local source items are individual abhangas; do not close until a selected-collection/edition policy is explicit."],
  ["work_candidate_bloom_mallarme_poetry_prose", "A Throw of the Dice and Selected Poems", "Stephane Mallarme", "Existing local source item is an unrelated component poem; needs exact edition/title-scope policy."],
  ["work_candidate_bloom_gap_031_0015_poems", "Poems", "Alcman", "Generic fragmentary-corpus title; needs corpus/selection policy."],
  ["work_candidate_eastasia_lit_yuefu_songs", "Selected Yuefu Songs", "Han and post-Han poetic tradition", "Generic anthology row; needs edition/selection policy."],
  ["work_candidate_me_lit_baba_taher_quatrains", "Quatrains", "Baba Taher", "Generic lyric corpus row; needs edition/selection policy."],
  ["work_candidate_me_lit_shmuel_hanagid_poems", "Selected Poems", "Samuel ha-Nagid", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_xin_qiji_ci", "Selected Ci Poems", "Xin Qiji", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_li_qingzhao_ci", "Selected Ci Poems", "Li Qingzhao", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_me_lit_navai_ghazals", "Selected Ghazals", "Ali-Shir Nava'i", "Generic selected-ghazals row; needs edition/selection policy."],
  ["work_candidate_global_lit_hwang_jini_sijo", "Selected Sijo", "Hwang Jini", "Generic selected-sijo row; needs edition/selection policy."],
  ["work_candidate_bloom_marvell_poems", "Poems", "Andrew Marvell", "Generic poems row; needs complete-poems versus selected-poems scope policy."],
  ["work_candidate_mandatory_saib_tabrizi_ghazals", "Selected Ghazals", "Saib Tabrizi", "Generic selected-ghazals row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_buson_haiku", "Selected Haiku", "Yosa Buson", "Generic selected-haiku row; needs edition/selection policy."],
  ["work_candidate_southasia_lit_bulleh_shah_kafis", "Selected Kafis", "Bulleh Shah", "Generic selected-kafis row; needs edition/selection policy."],
  ["work_candidate_bloom_late_032_literature_bloom_democratic_age_reviewed_0364_odes", "\"Odes\"", "Ugo Foscolo", "Generic quoted title; needs exact work/title-scope policy before evidence."],
  ["work_candidate_bloom_late_032_literature_bloom_democratic_age_reviewed_0423_selected_poems", "Fetes galantes and Romances sans paroles", "Paul Verlaine", "Combined-title row; needs title/edition policy."],
  ["work_candidate_wave003_arnold_dover_beach", "Dover Beach and Selected Poems", "Matthew Arnold", "Single poem plus selected-poems row; needs selection policy."],
  ["work_candidate_eastasia_lit_issa_haiku", "Selected Haiku", "Kobayashi Issa", "Generic selected-haiku row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_shiki_haiku", "Selected Haiku", "Masaoka Shiki", "Generic selected-haiku row; needs edition/selection policy."],
  ["work_candidate_bloom_tennyson_poems", "In Memoriam A.H.H. and Selected Poems", "Alfred Tennyson", "Single work plus selected-poems row; needs selection/title policy."],
  ["work_candidate_bloom_maupassant_selected_stories", "Boule de Suif and Selected Stories", "Guy de Maupassant", "Title evidence more often supports Boule de Suif and Other Stories; needs title/edition policy."],
  ["work_candidate_global_lit_prison_notebooks_poems", "Poems from Prison", "Ho Chi Minh", "Likely title/scope correction to Prison Diary or Poems from the Prison Diary."],
  ["work_candidate_africa_lit_ingrid_jonker_poems", "Selected Poems", "Ingrid Jonker", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_euro_under_lit_selected_poems_waldo", "Selected Poems", "Waldo Williams", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_completion_lit_selected_poems_rainis", "Selected Poems", "Rainis", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_euro_under_lit_selected_poems_sorley", "Selected Poems", "Sorley MacLean", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_euro_under_lit_sutzkever_poems", "Selected Poems", "Avrom Sutzkever", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_scale_lit_tsvetaeva_selected", "Selected Poems", "Marina Tsvetaeva", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_bloom_reviewed_heaney_poems", "Selected Poems", "Seamus Heaney", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_me_lit_siamanto_poems", "Selected Poems", "Siamanto", "Generic selected-poems row; needs edition/selection policy."],
  ["work_candidate_me_lit_varoujan_poems", "Selected Poems", "Daniel Varoujan", "Generic selected-poems row; needs edition/selection policy."],
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
  source_id.sub(/\Ax081_/, "x081_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax081_/, "x081_ev_")
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
        "extraction_method" => "Targeted X081 exact-title public source review",
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
        "notes" => "X081 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X081 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

  manifest["status"] = "exact_title_external_rescue_x081_applied"
  artifacts["source_items"] = "e001_ingested_through_x081_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x081_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x081_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x081_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x081_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x081_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x081_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x081_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x081_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x081_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x081_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x081"] = "generated_x081_for_exact_title_external_acquisition_rows"

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
  counts["x081_external_source_rescue_rows"] = applied_rows.size
  counts["x081_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x081"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x081"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x081_target_works_closed"],
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
    file.puts "# X081 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X081 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves generic selected-poems/stories rows, component-only rows, and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X081 |"
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
    "applied_id" => "x081_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x081.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x081.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_065_x081_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X081 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
