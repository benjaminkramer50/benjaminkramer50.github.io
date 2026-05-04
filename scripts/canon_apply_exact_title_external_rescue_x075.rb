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

PACKET_ID = "X075"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x075.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_059_x075_exact_title_external_rescue.md")

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
    work_id: "work_candidate_global_lit_odes_solomon",
    title: "Odes of Solomon",
    creator: "Early Syriac Christian poetic tradition",
    raw_date: "1st-2nd century",
    form_note: "early Christian hymn collection",
    rationale: "Encyclopedia.com and Cambridge Core confirm the Odes of Solomon as an early Christian poem/hymn collection.",
    sources: [
      ["x075_encyclopedia_com_odes_solomon_reference", "Encyclopedia.com: Solomon, Odes of", "reference_encyclopedia", "Encyclopedia.com, Solomon, Odes of, https://www.encyclopedia.com/religion/encyclopedias-almanacs-transcripts-and-maps/solomon-odes", "Solomon, Odes of reference entry", "https://www.encyclopedia.com/religion/encyclopedias-almanacs-transcripts-and-maps/solomon-odes", "x075_encyclopedia_exact_odes_solomon", "0.55", "reference_support_for_odes_solomon"],
      ["x075_cambridge_odes_solomon_early_christian_writings", "Cambridge Core: Odes of Solomon 7, 19, 41, and 42", "scholarly_edition_series", "Cambridge Core, Odes of Solomon 7, 19, 41, and 42, https://www.cambridge.org/core/books/abs/cambridge-edition-of-early-christian-writings/odes-of-solomon-7-19-41-and-42/D88AA6AFE106E342B5BF5FDAE213552B", "Cambridge Edition of Early Christian Writings chapter page", "https://www.cambridge.org/core/books/abs/cambridge-edition-of-early-christian-writings/odes-of-solomon-7-19-41-and-42/D88AA6AFE106E342B5BF5FDAE213552B", "x075_cambridge_exact_odes_solomon", "0.35", "scholarly_edition_support_for_odes_solomon"]
    ]
  },
  {
    work_id: "work_candidate_bloom_reviewed_novelle_rusticane",
    title: "Novelle Rusticane",
    creator: "Giovanni Verga",
    raw_date: "1883",
    form_note: "Italian short story collection",
    rationale: "Britannica and Treccani independently confirm Verga's Novelle rusticane as an 1883 story collection.",
    sources: [
      ["x075_britannica_verga_novelle_rusticane", "Britannica: Giovanni Verga", "reference_encyclopedia", "Encyclopaedia Britannica, Giovanni Verga, https://www.britannica.com/biography/Giovanni-Verga", "Giovanni Verga biography", "https://www.britannica.com/biography/Giovanni-Verga", "x075_britannica_exact_novelle_rusticane", "0.55", "reference_support_for_novelle_rusticane"],
      ["x075_treccani_verga_novelle_rusticane", "Treccani: Giovanni Verga", "reference_encyclopedia", "Treccani, Giovanni Verga, https://www.treccani.it/enciclopedia/giovanni-verga/", "Giovanni Verga encyclopedia entry", "https://www.treccani.it/enciclopedia/giovanni-verga/", "x075_treccani_exact_novelle_rusticane", "0.55", "reference_support_for_novelle_rusticane"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_old_indian_legends",
    title: "Old Indian Legends",
    creator: "Zitkala-Sa",
    raw_date: "1901",
    form_note: "Dakota story collection",
    rationale: "Britannica, Nebraska Press, and Cambridge Core confirm the 1901 Old Indian Legends scope.",
    sources: [
      ["x075_britannica_zitkala_old_indian_legends", "Britannica: Zitkala-Sa", "reference_encyclopedia", "Encyclopaedia Britannica, Zitkala-Sa, https://www.britannica.com/biography/Zitkala-Sa", "Zitkala-Sa biography", "https://www.britannica.com/biography/Zitkala-Sa", "x075_britannica_exact_old_indian_legends", "0.55", "reference_support_for_old_indian_legends"],
      ["x075_nebraska_press_old_indian_legends", "Nebraska Press: Old Indian Legends", "publisher_reference_series", "University of Nebraska Press, Old Indian Legends, https://www.nebraskapress.unl.edu/bison-books/9780803299030/old-indian-legends/", "Bison Books edition page", "https://www.nebraskapress.unl.edu/bison-books/9780803299030/old-indian-legends/", "x075_nebraska_exact_old_indian_legends", "0.55", "publisher_support_for_old_indian_legends"],
      ["x075_cambridge_old_indian_legends_chapter", "Cambridge Core: Zitkala-Sa's Old Indian Legends", "scholarly_edition_series", "Cambridge Core, Zitkala-Sa's Old Indian Legends: A New Perspective, https://www.cambridge.org/core/books/abs/new-perspectives-in-english-and-american-studies/zitkalasas-old-indian-legends-a-new-perspective/C78F34678A20D521E6A862FC30207966", "New Perspectives in English and American Studies chapter page", "https://www.cambridge.org/core/books/abs/new-perspectives-in-english-and-american-studies/zitkalasas-old-indian-legends-a-new-perspective/C78F34678A20D521E6A862FC30207966", "x075_cambridge_exact_old_indian_legends", "0.35", "scholarly_chapter_support_for_old_indian_legends"]
    ]
  },
  {
    work_id: "work_candidate_scale4_lit_magana_jari_ce",
    title: "Magana Jari Ce",
    creator: "Abubakar Imam",
    raw_date: "1937-1949",
    form_note: "Hausa story collection",
    rationale: "A DOAJ-indexed University of Warsaw article and Google Books record confirm Abubakar Imam's Magana Jari Ce as a major Hausa work.",
    sources: [
      ["x075_doaj_magana_jari_ce_reference", "DOAJ: Foreign influences in Magana Jari Ce", "language_literary_history", "DOAJ, Foreign influences and their adaptation to the Hausa culture in Magana Jari Ce by Abubakar Imam, https://doaj.org/article/03a6343382754003921a1df592733290", "Studies in African Languages and Cultures article record", "https://doaj.org/article/03a6343382754003921a1df592733290", "x075_doaj_exact_magana_jari_ce", "0.55", "scholarly_article_support_for_magana_jari_ce"],
      ["x075_google_books_magana_jari_ce", "Google Books: Magana jari ce", "publisher_reference_series", "Google Books, Magana jari ce by Alhaji Abubakar Imam, https://books.google.com/books/about/Magana_jari_ce.html?id=1rWFeopvzHsC", "Google Books title record", "https://books.google.com/books/about/Magana_jari_ce.html?id=1rWFeopvzHsC", "x075_google_books_exact_magana_jari_ce", "0.55", "publisher_record_support_for_magana_jari_ce"]
    ]
  },
  {
    work_id: "work_candidate_completion_lit_love_fallen_city",
    title: "Love in a Fallen City",
    creator: "Eileen Chang",
    raw_date: "1943; English collection 2006",
    form_note: "Chinese short fiction collection",
    rationale: "Penguin Random House/NYRB and the MCLC Resource Center confirm the English collection scope and reception.",
    sources: [
      ["x075_prh_love_in_a_fallen_city", "Penguin Random House: Love in a Fallen City", "publisher_reference_series", "Penguin Random House, Love in a Fallen City by Eileen Chang, https://www.penguinrandomhouse.com/books/26084/love-in-a-fallen-city-by-translated-by-eileen-chang-and-karen-s-kingsbury/", "NYRB Classics book page", "https://www.penguinrandomhouse.com/books/26084/love-in-a-fallen-city-by-translated-by-eileen-chang-and-karen-s-kingsbury/", "x075_prh_exact_love_in_a_fallen_city", "0.55", "publisher_support_for_love_in_a_fallen_city"],
      ["x075_mclc_love_in_a_fallen_city_review", "MCLC Resource Center: Review of Love in a Fallen City", "prize_or_reception_layer", "MCLC Resource Center, Eileen Chang's Poetics of the Social: Review of Love in a Fallen City, https://u.osu.edu/mclc/book-reviews/review-of-love-in-a-fallen-city/", "MCLC book review", "https://u.osu.edu/mclc/book-reviews/review-of-love-in-a-fallen-city/", "x075_mclc_exact_love_in_a_fallen_city", "0.35", "reception_support_for_love_in_a_fallen_city"]
    ]
  },
  {
    work_id: "work_candidate_southasia_lit_malgudi_days",
    title: "Malgudi Days",
    creator: "R. K. Narayan",
    raw_date: "1943",
    form_note: "Indian English short story collection",
    rationale: "Britannica and Penguin Classics confirm Malgudi Days as a Narayan story collection and canonical Penguin Classics title.",
    sources: [
      ["x075_britannica_malgudi_days", "Britannica: Malgudi Days", "reference_encyclopedia", "Encyclopaedia Britannica, Malgudi Days, https://www.britannica.com/topic/Malgudi-Days", "Malgudi Days reference entry", "https://www.britannica.com/topic/Malgudi-Days", "x075_britannica_exact_malgudi_days", "0.55", "reference_support_for_malgudi_days"],
      ["x075_prh_malgudi_days", "Penguin Random House: Malgudi Days", "publisher_reference_series", "Penguin Random House, Malgudi Days by R. K. Narayan, https://www.penguinrandomhouse.com/books/322341/malgudi-days-by-r-k-narayan/", "Penguin Classics book page", "https://www.penguinrandomhouse.com/books/322341/malgudi-days-by-r-k-narayan/", "x075_prh_exact_malgudi_days", "0.55", "publisher_support_for_malgudi_days"]
    ]
  },
  {
    work_id: "work_candidate_africa_lit_luuanda",
    title: "Luuanda",
    creator: "Jose Luandino Vieira",
    raw_date: "1963",
    form_note: "Angolan short story collection",
    rationale: "Britannica and RTP education/news sources confirm Luuanda's 1963 story-collection scope and 1965 prize/banning reception.",
    sources: [
      ["x075_britannica_luandino_luuanda", "Britannica: Jose Luandino Vieira", "reference_encyclopedia", "Encyclopaedia Britannica, Jose Luandino Vieira, https://www.britannica.com/biography/Jose-Luandino-Vieira", "Jose Luandino Vieira biography", "https://www.britannica.com/biography/Jose-Luandino-Vieira", "x075_britannica_exact_luuanda", "0.55", "reference_support_for_luuanda"],
      ["x075_rtp_ensina_luuanda", "RTP Ensina: Como a PIDE destruiu a Sociedade Portuguesa de Escritores", "language_literary_history", "RTP Ensina, Como a PIDE destruiu a Sociedade Portuguesa de Escritores, https://ensina.rtp.pt/artigo/como-a-pide-destruiu-a-sociedade-portuguesa-de-escritores/", "RTP Ensina literary-history article", "https://ensina.rtp.pt/artigo/como-a-pide-destruiu-a-sociedade-portuguesa-de-escritores/", "x075_rtp_ensina_exact_luuanda", "0.55", "literary_history_support_for_luuanda"],
      ["x075_rtp_luuanda_prize_reference", "RTP Noticias: Luandino Vieira vence Premio Nacional de Cultura", "prize_or_reception_layer", "RTP Noticias, Luandino Vieira vence Premio Nacional de Cultura angolano, em Literatura, https://www.rtp.pt/noticias/cultura/luandino-vieira-vence-premio-nacional-de-cultura-angolano-em-literatura_n167649", "RTP Noticias reception article", "https://www.rtp.pt/noticias/cultura/luandino-vieira-vence-premio-nacional-de-cultura-angolano-em-literatura_n167649", "x075_rtp_prize_exact_luuanda", "0.35", "prize_reception_support_for_luuanda"]
    ]
  },
  {
    work_id: "work_candidate_africa_lit_land_without_thunder",
    title: "Land Without Thunder",
    creator: "Grace Ogot",
    raw_date: "1968",
    form_note: "Kenyan short story collection",
    rationale: "Google Books and Encyclopedia.com confirm Land Without Thunder as Grace Ogot's 1968 short story collection.",
    sources: [
      ["x075_google_books_land_without_thunder", "Google Books: Land Without Thunder", "publisher_reference_series", "Google Books, Land Without Thunder: Short Stories by Grace Ogot, https://books.google.com/books?id=ZMsIeaBX0SIC", "Google Books title record", "https://books.google.com/books?id=ZMsIeaBX0SIC", "x075_google_books_exact_land_without_thunder", "0.55", "publisher_record_support_for_land_without_thunder"],
      ["x075_encyclopedia_com_grace_ogot_land_without_thunder", "Encyclopedia.com: Grace Ogot", "reference_encyclopedia", "Encyclopedia.com, Ogot, Grace (1930-), https://www.encyclopedia.com/women/encyclopedias-almanacs-transcripts-and-maps/ogot-grace-1930", "Grace Ogot reference entry", "https://www.encyclopedia.com/women/encyclopedias-almanacs-transcripts-and-maps/ogot-grace-1930", "x075_encyclopedia_exact_land_without_thunder", "0.55", "reference_support_for_land_without_thunder"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_flying_fox",
    title: "Flying Fox in a Freedom Tree",
    creator: "Albert Wendt",
    raw_date: "1974",
    form_note: "Samoan/Pacific story collection",
    rationale: "University of Hawaii Press and Encyclopedia.com confirm Wendt's Flying-Fox in a Freedom Tree as an early story collection.",
    sources: [
      ["x075_uhpress_flying_fox", "University of Hawaii Press: Flying-Fox in a Freedom Tree", "publisher_reference_series", "University of Hawaii Press, Flying-Fox in a Freedom Tree, https://uhpress.hawaii.edu/title/flying-fox-in-a-freedom-tree/", "University of Hawaii Press book page", "https://uhpress.hawaii.edu/title/flying-fox-in-a-freedom-tree/", "x075_uhpress_exact_flying_fox", "0.55", "publisher_support_for_flying_fox"],
      ["x075_encyclopedia_com_wendt_flying_fox", "Encyclopedia.com: Albert Wendt", "reference_encyclopedia", "Encyclopedia.com, Wendt, Albert, https://www.encyclopedia.com/education/news-wires-white-papers-and-books/wendt-albert", "Albert Wendt reference entry", "https://www.encyclopedia.com/education/news-wires-white-papers-and-books/wendt-albert", "x075_encyclopedia_exact_flying_fox", "0.55", "reference_support_for_flying_fox"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_arctic_dreams",
    title: "Arctic Dreams and Nightmares",
    creator: "Alootook Ipellie",
    raw_date: "1993",
    form_note: "Inuit story and art collection",
    rationale: "Inuit Art Foundation and Google Books confirm Arctic Dreams and Nightmares as Ipellie's 1993 short-story/art collection.",
    sources: [
      ["x075_inuit_art_foundation_arctic_dreams", "Inuit Art Foundation: Alootook Ipellie", "reference_encyclopedia", "Inuit Art Foundation, Alootook Ipellie, https://www.inuitartfoundation.org/profiles/artist/alootook-ipellie", "Alootook Ipellie artist profile", "https://www.inuitartfoundation.org/profiles/artist/alootook-ipellie", "x075_iaf_exact_arctic_dreams", "0.55", "reference_support_for_arctic_dreams"],
      ["x075_google_books_arctic_dreams", "Google Books: Arctic Dreams and Nightmares", "publisher_reference_series", "Google Books, Arctic Dreams and Nightmares by Alootook Ipellie, https://books.google.com/books/about/Arctic_Dreams_and_Nightmares.html?id=SddaAAAAMAAJ", "Google Books title record", "https://books.google.com/books/about/Arctic_Dreams_and_Nightmares.html?id=SddaAAAAMAAJ", "x075_google_books_exact_arctic_dreams", "0.55", "publisher_record_support_for_arctic_dreams"]
    ]
  },
  {
    work_id: "work_candidate_latcarib_lit_mouthful_birds",
    title: "Mouthful of Birds",
    creator: "Samanta Schweblin",
    raw_date: "2009; English 2019",
    form_note: "Argentine short story collection",
    rationale: "Penguin Random House, Booker, and National Book Foundation evidence confirm the collection and international reception.",
    sources: [
      ["x075_prh_mouthful_birds", "Penguin Random House: Mouthful of Birds", "publisher_reference_series", "Penguin Random House, Mouthful of Birds by Samanta Schweblin, https://www.penguinrandomhouse.com/books/533972/mouthful-of-birds-by-samanta-schweblin-translated-by-megan-mcdowell/", "Riverhead Books page", "https://www.penguinrandomhouse.com/books/533972/mouthful-of-birds-by-samanta-schweblin-translated-by-megan-mcdowell/", "x075_prh_exact_mouthful_birds", "0.55", "publisher_support_for_mouthful_birds"],
      ["x075_booker_mouthful_birds", "The Booker Prizes: Mouthful of Birds", "prize_or_reception_layer", "The Booker Prizes, Mouthful of Birds, https://thebookerprizes.com/the-booker-library/books/mouthful-of-birds", "International Booker longlist page", "https://thebookerprizes.com/the-booker-library/books/mouthful-of-birds", "x075_booker_exact_mouthful_birds", "0.35", "booker_reception_support_for_mouthful_birds"],
      ["x075_nbf_schweblin_mouthful_birds", "National Book Foundation: Samanta Schweblin", "prize_or_reception_layer", "National Book Foundation, Samanta Schweblin, https://www.nationalbook.org/people/samanta-schweblin/", "National Book Foundation author page", "https://www.nationalbook.org/people/samanta-schweblin/", "x075_nbf_exact_mouthful_birds", "0.35", "national_book_foundation_support_for_mouthful_birds"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_heat_light",
    title: "Heat and Light",
    creator: "Ellen van Neerven",
    raw_date: "2014",
    form_note: "First Nations Australian story collection",
    rationale: "UQP, Stella, and NSW Premier's Literary Awards sources confirm Heat and Light's collection scope and prize reception.",
    sources: [
      ["x075_uqp_heat_light", "UQP: Heat and Light", "publisher_reference_series", "University of Queensland Press, Heat and Light, https://www.uqp.com.au/books/heat-and-light", "UQP book page", "https://www.uqp.com.au/books/heat-and-light", "x075_uqp_exact_heat_light", "0.55", "publisher_support_for_heat_light"],
      ["x075_stella_heat_light", "Stella Prize: Heat and Light", "prize_or_reception_layer", "Stella Prize, Heat and Light, https://stellacanyon.com/prize/2015-prize/heat-and-light/", "2015 Stella Prize shortlist page", "https://stellacanyon.com/prize/2015-prize/heat-and-light/", "x075_stella_exact_heat_light", "0.35", "stella_reception_support_for_heat_light"],
      ["x075_sl_nsw_heat_light", "State Library of NSW: Heat and Light", "prize_or_reception_layer", "State Library of NSW, Heat and Light, https://www.sl.nsw.gov.au/heat-and-light", "NSW Premier's Literary Awards page", "https://www.sl.nsw.gov.au/heat-and-light", "x075_nsw_exact_heat_light", "0.35", "nsw_prize_reception_support_for_heat_light"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_bloom_gap_031_0015_poems", "Poems", "Alcman", "Generic fragmentary corpus title; needs selected-fragment or corpus-scope policy."],
  ["work_candidate_me_lit_shmuel_hanagid_poems", "Selected Poems", "Samuel ha-Nagid", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_xin_qiji_ci", "Selected Ci Poems", "Xin Qiji", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_li_qingzhao_ci", "Selected Ci Poems", "Li Qingzhao", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0827_gogol_s_wife_and_other_stories", "Gogol's Wife and Other Stories", "Tommaso Landolfi", "Exact-title row, but second independent source support remains thin."],
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
  source_id.sub(/\Ax075_/, "x075_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax075_/, "x075_ev_")
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
        "extraction_method" => "Targeted X075 exact-title public source review",
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
        "notes" => "X075 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X075 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

  manifest["status"] = "exact_title_external_rescue_x075_applied"
  artifacts["source_items"] = "e001_ingested_through_x075_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x075_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x075_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x075_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x075_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x075_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x075_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x075_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x075_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x075_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x075_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x075"] = "generated_x075_for_exact_title_external_acquisition_rows"

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
  counts["x075_external_source_rescue_rows"] = applied_rows.size
  counts["x075_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x075"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x075"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x075_target_works_closed"],
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
    file.puts "# X075 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X075 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves selected-poems/stories rows and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X075 |"
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
    "applied_id" => "x075_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
    "scope" => "exact-title external-source rescue for twelve current-path rows",
    "status" => "exact_title_external_source_rescue_applied",
    "gate" => "cut_and_replacement_review_still_required",
    "output_artifact" => [
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x075.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x075.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_059_x075_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X075 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
