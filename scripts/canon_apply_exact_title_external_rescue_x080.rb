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

PACKET_ID = "X080"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x080.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_064_x080_exact_title_external_rescue.md")

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
    work_id: "work_candidate_latcarib_lit_tradiciones_peruanas",
    title: "Tradiciones peruanas",
    creator: "Ricardo Palma",
    raw_date: "1872-1910",
    form_note: "Peruvian historical-fiction prose tradition",
    rationale: "Britannica and Encyclopedia.com both identify Ricardo Palma's Tradiciones peruanas as his central literary work and as a major Peruvian/Latin American short-prose tradition.",
    sources: [
      ["x080_britannica_tradiciones_peruanas", "Britannica: Tradiciones peruanas", "reference_encyclopedia", "Britannica, The Knights of the Cape and Thirty-seven Other Selections from the Tradiciones Peruanas of Ricardo Palma, https://www.britannica.com/topic/The-Knights-of-the-Cape-and-Thirty-seven-Other-Selections-from-the-Tradiciones-Peruanas-of-Ricardo-Palma", "Britannica topic entry", "https://www.britannica.com/topic/The-Knights-of-the-Cape-and-Thirty-seven-Other-Selections-from-the-Tradiciones-Peruanas-of-Ricardo-Palma", "x080_britannica_exact_tradiciones_peruanas", "0.55", "reference_support_for_tradiciones_peruanas"],
      ["x080_encyclopedia_palma_tradiciones", "Encyclopedia.com: Ricardo Palma", "reference_encyclopedia", "Encyclopedia.com, Palma, Ricardo (1833-1919), https://www.encyclopedia.com/humanities/encyclopedias-almanacs-transcripts-and-maps/palma-ricardo-1833-1919", "Reference biography", "https://www.encyclopedia.com/humanities/encyclopedias-almanacs-transcripts-and-maps/palma-ricardo-1833-1919", "x080_encyclopedia_exact_palma_tradiciones", "0.55", "reference_support_for_palma_tradiciones"]
    ]
  },
  {
    work_id: "work_candidate_scale2_lit_sonnets_to_orpheus",
    title: "Sonnets to Orpheus",
    creator: "Rainer Maria Rilke",
    raw_date: "1922; first published 1923",
    form_note: "German sonnet cycle",
    rationale: "Macmillan and Wesleyan University Press both confirm Sonnets to Orpheus as Rilke's late sonnet sequence and treat it as a major work rather than the unrelated source items currently attached to this row.",
    sources: [
      ["x080_macmillan_sonnets_orpheus", "Macmillan: Sonnets to Orpheus", "publisher_reference_series", "Macmillan Publishers, Sonnets to Orpheus, https://us.macmillan.com/books/9780865477216/sonnetstoorpheus/", "Macmillan book page", "https://us.macmillan.com/books/9780865477216/sonnetstoorpheus/", "x080_macmillan_exact_sonnets_orpheus", "0.55", "publisher_support_for_sonnets_orpheus"],
      ["x080_wesleyan_sonnets_orpheus", "Wesleyan University Press: Sonnets to Orpheus", "publisher_reference_series", "Wesleyan University Press, Sonnets to Orpheus, https://www.weslpress.org/9780819561657/sonnets-to-orpheus/", "Wesleyan University Press book page", "https://www.weslpress.org/9780819561657/sonnets-to-orpheus/", "x080_wesleyan_exact_sonnets_orpheus", "0.55", "publisher_support_for_sonnets_orpheus"]
    ]
  },
  {
    work_id: "work_candidate_latcarib_lit_vampire_curitiba",
    title: "The Vampire of Curitiba",
    creator: "Dalton Trevisan",
    raw_date: "1965 Portuguese original; English collection 1972",
    form_note: "Brazilian short story collection",
    rationale: "Britannica and Encyclopedia.com both identify O vampiro de Curitiba / The Vampire of Curitiba and Other Stories as a central Dalton Trevisan collection; title normalization should still decide whether the display title needs the English subtitle.",
    sources: [
      ["x080_britannica_vampire_curitiba", "Britannica: Dalton Trevisan and The Vampire of Curitiba", "reference_encyclopedia", "Britannica, Brazilian literature: The short story, https://www.britannica.com/art/Brazilian-literature/The-short-story", "Brazilian literature reference section", "https://www.britannica.com/art/Brazilian-literature/The-short-story", "x080_britannica_exact_vampire_curitiba", "0.55", "reference_support_for_vampire_curitiba"],
      ["x080_encyclopedia_trevisan_vampire", "Encyclopedia.com: Dalton Trevisan", "reference_encyclopedia", "Encyclopedia.com, Trevisan, Dalton 1925-, https://www.encyclopedia.com/arts/educational-magazines/trevisan-dalton-1925", "Reference biography", "https://www.encyclopedia.com/arts/educational-magazines/trevisan-dalton-1925", "x080_encyclopedia_exact_trevisan_vampire", "0.55", "reference_support_for_trevisan_vampire_curitiba"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0869_when_i_sleep_then_i_see_clearly_selected_poems_o",
    title: "When I Sleep, Then I See Clearly: Selected Poems of J V Foix",
    creator: "J V Foix",
    raw_date: "1988",
    form_note: "Catalan poetry selection in English translation",
    rationale: "Google Books and EBSCO both confirm When I Sleep, Then I See Clearly: Selected Poems of J. V. Foix as David Rosenthal's 1988 Persea selected-poems edition.",
    sources: [
      ["x080_google_books_foix_when_i_sleep", "Google Books: When I Sleep, Then I See Clearly", "publisher_reference_series", "Google Books, When I Sleep, Then I See Clearly: Selected Poems of J.V. Foix, https://books.google.com/books/about/When_I_Sleep_Then_I_See_Clearly.html?id=4bvjAAAAMAAJ", "Google Books title record", "https://books.google.com/books/about/When_I_Sleep_Then_I_See_Clearly.html?id=4bvjAAAAMAAJ", "x080_google_books_exact_foix_when_i_sleep", "0.55", "publisher_record_support_for_foix_when_i_sleep"],
      ["x080_ebsco_catalan_poetry_foix", "EBSCO Research Starters: Catalan Poetry", "language_literary_history", "EBSCO, Catalan Poetry, https://www.ebsco.com/research-starters/literature-and-writing/catalan-poetry", "Literature research-starter bibliography", "https://www.ebsco.com/research-starters/literature-and-writing/catalan-poetry", "x080_ebsco_exact_foix_when_i_sleep", "0.55", "literary_history_support_for_foix_when_i_sleep"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_1003_transparence_of_the_world_poems",
    title: "Transparence of the World: Poems",
    creator: "Jean Follain",
    raw_date: "1969; Copper Canyon reissue 2003",
    form_note: "French poetry selection in English translation",
    rationale: "Copper Canyon Press and Publishers Weekly confirm Transparence of the World as a W. S. Merwin-selected and translated Jean Follain poetry volume.",
    sources: [
      ["x080_copper_follain_transparence", "Copper Canyon Press: Transparence of the World", "publisher_reference_series", "Copper Canyon Press, Transparence of the World by Jean Follain, W.S. Merwin, trans., https://www.coppercanyonpress.org/books/transparence-of-the-world-by-jean-follain-w-s-merwin/", "Copper Canyon Press book page", "https://www.coppercanyonpress.org/books/transparence-of-the-world-by-jean-follain-w-s-merwin/", "x080_copper_exact_follain_transparence", "0.55", "publisher_support_for_follain_transparence"],
      ["x080_pw_follain_transparence", "Publishers Weekly: Transparence of the World", "prize_or_reception_layer", "Publishers Weekly, Transparence of the World, https://www.publishersweekly.com/9781556591907", "Publishers Weekly review", "https://www.publishersweekly.com/9781556591907", "x080_pw_exact_follain_transparence", "0.55", "review_support_for_follain_transparence"]
    ]
  },
  {
    work_id: "work_candidate_wave002_cummings_tulips_chimneys",
    title: "Tulips and Chimneys",
    creator: "E. E. Cummings",
    raw_date: "1923",
    form_note: "American poetry collection",
    rationale: "Google Books and the Poetry Foundation both confirm Tulips and Chimneys as Cummings's first poetry collection, with the original 1923 title and later edition history.",
    sources: [
      ["x080_google_books_cummings_tulips", "Google Books: Tulips and Chimneys", "publisher_reference_series", "Google Books, Tulips and Chimneys, https://books.google.com/books/about/Tulips_and_Chimneys.html?id=pb_wAAAAQBAJ", "Google Books title record", "https://books.google.com/books/about/Tulips_and_Chimneys.html?id=pb_wAAAAQBAJ", "x080_google_books_exact_cummings_tulips", "0.55", "publisher_record_support_for_cummings_tulips"],
      ["x080_poetry_foundation_cummings_tulips", "Poetry Foundation: E. E. Cummings", "language_literary_history", "Poetry Foundation, E. E. Cummings, https://www.poetryfoundation.org/poets/e-e-cummings", "Poet profile", "https://www.poetryfoundation.org/poets/e-e-cummings", "x080_poetry_foundation_exact_cummings_tulips", "0.55", "literary_history_support_for_cummings_tulips"]
    ]
  },
  {
    work_id: "work_candidate_latcarib_lit_week_colors",
    title: "The Week of Colors",
    creator: "Elena Garro",
    raw_date: "1964 Spanish original; English translation 2025",
    form_note: "Mexican short story collection",
    rationale: "Two Lines Press and Publishers Weekly confirm The Week of Colors as Megan McDowell's English translation of Elena Garro's 1964 La semana de colores; the row still needs chronology/display review because the current English title follows the 2025 translation.",
    sources: [
      ["x080_two_lines_week_colors", "Two Lines Press: The Week of Colors", "publisher_reference_series", "Two Lines Press, The Week of Colors, https://www.twolinespress.com/shop/books/the-week-of-colors", "Two Lines Press book page", "https://www.twolinespress.com/shop/books/the-week-of-colors", "x080_two_lines_exact_week_colors", "0.55", "publisher_support_for_week_colors"],
      ["x080_pw_week_colors", "Publishers Weekly: The Week of Colors", "prize_or_reception_layer", "Publishers Weekly, The Week of Colors by Elena Garro, https://www.publishersweekly.com/9781949641899", "Publishers Weekly review", "https://www.publishersweekly.com/9781949641899", "x080_pw_exact_week_colors", "0.55", "review_support_for_week_colors"]
    ]
  },
  {
    work_id: "work_candidate_africa_lit_voices_made_night",
    title: "Voices Made Night",
    creator: "Mia Couto",
    raw_date: "1986 Portuguese original; English translation 1990",
    form_note: "Mozambican short story collection",
    rationale: "MertinWitt's Mia Couto bibliography and Encyclopedia.com both confirm Vozes anoitecidas / Voices Made Night as Couto's early short story collection and its 1990 English translation.",
    sources: [
      ["x080_mertinwitt_voices_made_night", "MertinWitt: Mia Couto bibliography", "language_literary_history", "MertinWitt Literary Agency, Mia Couto, https://mertinwitt-litag.de/portfolio-items/mia-couto/", "Author bibliography", "https://mertinwitt-litag.de/portfolio-items/mia-couto/", "x080_mertinwitt_exact_voices_made_night", "0.55", "literary_bibliography_support_for_voices_made_night"],
      ["x080_encyclopedia_couto_voices", "Encyclopedia.com: Mia Couto", "reference_encyclopedia", "Encyclopedia.com, Couto, Mia 1955-, https://www.encyclopedia.com/education/news-wires-white-papers-and-books/couto-mia-1955", "Reference biography", "https://www.encyclopedia.com/education/news-wires-white-papers-and-books/couto-mia-1955", "x080_encyclopedia_exact_couto_voices", "0.55", "reference_support_for_voices_made_night"]
    ]
  },
  {
    work_id: "work_candidate_bloom_carver_where_calling",
    title: "Where I'm Calling From",
    creator: "Raymond Carver",
    raw_date: "1988",
    form_note: "American new and selected short story collection",
    rationale: "Penguin Random House and Publishers Weekly confirm Where I'm Calling From / Where I'm Calling from: New and Selected Stories as Carver's final story collection; display-title policy can decide whether to expand the subtitle.",
    sources: [
      ["x080_prh_carver_where_calling", "Penguin Random House: Where I'm Calling From", "publisher_reference_series", "Penguin Random House, Where I'm Calling From by Raymond Carver, https://www.penguinrandomhouse.com/books/24964/where-im-calling-from-by-raymond-carver/", "Vintage book page", "https://www.penguinrandomhouse.com/books/24964/where-im-calling-from-by-raymond-carver/", "x080_prh_exact_carver_where_calling", "0.55", "publisher_support_for_carver_where_calling"],
      ["x080_pw_carver_where_calling", "Publishers Weekly: Where I'm Calling from", "prize_or_reception_layer", "Publishers Weekly, Where I'm Calling from: New and Selected Stories, https://www.publishersweekly.com/9780871132161", "Publishers Weekly review", "https://www.publishersweekly.com/9780871132161", "x080_pw_exact_carver_where_calling", "0.55", "review_support_for_carver_where_calling"]
    ]
  },
  {
    work_id: "work_candidate_latcarib_lit_things_lost_fire",
    title: "Things We Lost in the Fire",
    creator: "Mariana Enriquez",
    raw_date: "2016 Spanish original; English translation 2017",
    form_note: "Argentine short story collection",
    rationale: "Penguin Random House and Publishers Weekly confirm Things We Lost in the Fire as Mariana Enriquez's short story collection in Megan McDowell's English translation.",
    sources: [
      ["x080_prh_enriquez_things_lost_fire", "Penguin Random House: Things We Lost in the Fire", "publisher_reference_series", "Penguin Random House, Things We Lost in the Fire by Mariana Enriquez, https://www.penguinrandomhouse.com/books/538696/things-we-lost-in-the-fire-by-mariana-enriquez/", "Hogarth book page", "https://www.penguinrandomhouse.com/books/538696/things-we-lost-in-the-fire-by-mariana-enriquez/", "x080_prh_exact_enriquez_things_lost_fire", "0.55", "publisher_support_for_enriquez_things_lost_fire"],
      ["x080_pw_enriquez_things_lost_fire", "Publishers Weekly: Things We Lost in the Fire", "prize_or_reception_layer", "Publishers Weekly, Things We Lost in the Fire, https://www.publishersweekly.com/9780451495112", "Publishers Weekly review", "https://www.publishersweekly.com/9780451495112", "x080_pw_exact_enriquez_things_lost_fire", "0.55", "review_support_for_enriquez_things_lost_fire"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_southasia_lit_tukaram_abhangas", "Selected Abhangas", "Tukaram", "Existing source items are individual abhangas; this needs selected-collection policy or exact edition support."],
  ["work_candidate_indig_lit_akabal_poems", "Selected Poems", "Humberto Ak'abal", "Existing source items are representative poems; this needs selected-poems policy before evidence generation."],
  ["work_candidate_scale_lit_archilochus_poems", "Selected Poems", "Archilochus", "Generic ancient lyric selection; needs edition/selection policy."],
  ["work_candidate_bloom_gap_031_0015_poems", "Poems", "Alcman", "Generic fragmentary corpus title; needs selected-fragment or corpus-scope policy."],
  ["work_candidate_eastasia_lit_yuefu_songs", "Selected Yuefu Songs", "Han and post-Han poetic tradition", "Generic anthology selection; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_xin_qiji_ci", "Selected Ci Poems", "Xin Qiji", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_li_qingzhao_ci", "Selected Ci Poems", "Li Qingzhao", "Selected-poems row; needs edition/selection policy."],
  ["work_candidate_global_lit_prison_notebooks_poems", "Poems from Prison", "Ho Chi Minh", "Likely title/scope correction to Prison Diary or Poems from the Prison Diary is needed before scoring."],
  ["work_candidate_bloom_maupassant_selected_stories", "Boule de Suif and Selected Stories", "Guy de Maupassant", "Search results support Boule de Suif and Other Stories more strongly than the current selected-stories display title; needs title/edition policy before closure."],
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
  source_id.sub(/\Ax080_/, "x080_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax080_/, "x080_ev_")
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
        "extraction_method" => "Targeted X080 exact-title public source review",
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
        "notes" => "X080 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X080 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

  manifest["status"] = "exact_title_external_rescue_x080_applied"
  artifacts["source_items"] = "e001_ingested_through_x080_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x080_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x080_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x080_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x080_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x080_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x080_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x080_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x080_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x080_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x080_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x080"] = "generated_x080_for_exact_title_external_acquisition_rows"

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
  counts["x080_external_source_rescue_rows"] = applied_rows.size
  counts["x080_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x080"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x080"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x080_target_works_closed"],
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
    file.puts "# X080 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X080 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves generic selected-poems/stories rows, component-only rows, and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X080 |"
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
    "applied_id" => "x080_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x080.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x080.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_064_x080_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X080 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
