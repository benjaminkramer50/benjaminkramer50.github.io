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

PACKET_ID = "X083"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x083.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_067_x083_exact_title_external_rescue.md")

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
    work_id: "work_candidate_bloom_reviewed_tales_belkin",
    title: "The Tales of Belkin",
    creator: "Alexander Pushkin",
    raw_date: "1831",
    form_note: "Russian prose tale cycle",
    rationale: "Penguin Random House and Britannica both support The Tales of Belkin / Tales of the Late Ivan Petrovich Belkin as Pushkin's linked prose-tale cycle; later title cleanup should preserve the longer original-title form.",
    sources: [
      ["x083_prh_pushkin_tales_belkin", "Penguin Random House: Tales of Belkin", "publisher_reference_series", "Penguin Random House, Tales of Belkin by Alexander Pushkin, https://www.penguinrandomhouse.com/books/136537/tales-of-belkin-by-alexander-pushkin/", "Penguin Random House book page", "https://www.penguinrandomhouse.com/books/136537/tales-of-belkin-by-alexander-pushkin/", "x083_prh_exact_pushkin_tales_belkin", "0.55", "publisher_support_for_pushkin_tales_belkin"],
      ["x083_britannica_pushkin_tales_belkin", "Britannica: Tales of the Late Ivan Petrovich Belkin", "language_literary_history", "Britannica, Russian literature: Aleksandr Pushkin, https://www.britannica.com/art/Russian-literature/Aleksandr-Pushkin", "Britannica Russian literature section", "https://www.britannica.com/art/Russian-literature/Aleksandr-Pushkin", "x083_britannica_exact_pushkin_tales_belkin", "0.55", "literary_history_support_for_pushkin_tales_belkin"]
    ]
  },
  {
    work_id: "work_candidate_wave003_mansfield_garden_party",
    title: "The Garden Party and Other Stories",
    creator: "Katherine Mansfield",
    raw_date: "1922",
    form_note: "Modernist short story collection",
    rationale: "Penguin Classics and Britannica both support The Garden Party and Other Stories as Mansfield's 1922 short-story collection; the current row title is already close enough for evidence closure.",
    sources: [
      ["x083_penguin_mansfield_garden_party", "Penguin: The Garden Party and Other Stories", "publisher_reference_series", "Penguin Books UK, The Garden Party and Other Stories by Katherine Mansfield, https://www.penguin.co.uk/books/17462/the-garden-party-and-other-stories-by-mansfield-katherine/9780141441801", "Penguin Classics book page", "https://www.penguin.co.uk/books/17462/the-garden-party-and-other-stories-by-mansfield-katherine/9780141441801", "x083_penguin_exact_mansfield_garden_party", "0.55", "publisher_support_for_mansfield_garden_party"],
      ["x083_britannica_mansfield_garden_party", "Britannica: Katherine Mansfield", "reference_encyclopedia", "Britannica, Katherine Mansfield, https://www.britannica.com/biography/Katherine-Mansfield", "Britannica author biography", "https://www.britannica.com/biography/Katherine-Mansfield", "x083_britannica_exact_mansfield_garden_party", "0.55", "reference_support_for_mansfield_garden_party"]
    ]
  }
].freeze

DEFERRED_NOTES = [
  ["work_candidate_southasia_lit_tukaram_abhangas", "Selected Abhangas", "Tukaram", "Existing local source items are individual abhangas; do not close until a selected-collection/edition policy is explicit."],
  ["work_candidate_wave004_guido_cavalcanti_rime", "Rime", "Guido Cavalcanti", "Single local source item is one poem; the corpus title needs title/edition policy before evidence."],
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
  ["work_candidate_wave004_whittier_snow_bound", "Snow-Bound and Selected Poems", "John Greenleaf Whittier", "Single poem plus selected-poems row; needs selection/title policy."],
  ["work_candidate_wave002_bryant_thanatopsis_selected_poems", "Thanatopsis and Selected Poems", "William Cullen Bryant", "Single poem plus selected-poems row; needs selection/title policy."],
  ["work_candidate_eastasia_lit_issa_haiku", "Selected Haiku", "Kobayashi Issa", "Generic selected-haiku row; needs edition/selection policy."],
  ["work_candidate_eastasia_lit_shiki_haiku", "Selected Haiku", "Masaoka Shiki", "Generic selected-haiku row; needs edition/selection policy."],
  ["work_candidate_bloom_tennyson_poems", "In Memoriam A.H.H. and Selected Poems", "Alfred Tennyson", "Single work plus selected-poems row; needs selection/title policy."],
  ["work_candidate_bloom_maupassant_selected_stories", "Boule de Suif and Selected Stories", "Guy de Maupassant", "Title evidence more often supports Boule de Suif and Other Stories; needs title/edition policy."],
  ["work_candidate_wave002_poe_raven_selected_poems", "The Raven and Selected Poems", "Edgar Allan Poe", "Single poem plus selected-poems row; needs selection/title policy."],
  ["work_candidate_wave004_andrea_zanzotto_selected_poetry", "Selected Poetry of Andrea Zanzotto", "Andrea Zanzotto", "Exact edition source is available but still selected-poetry; defer to selection policy batch."],
  ["work_candidate_wave004_alfred_jarry_selected_works", "Selected Works of Alfred Jarry", "Alfred Jarry", "Selected-works edition row; needs selection policy before evidence."],
  ["work_candidate_wave004_rene_char_poems", "Poems of Rene Char", "Rene Char", "Title source looks edition-specific; defer until title/scope policy."],
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
  source_id.sub(/\Ax083_/, "x083_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax083_/, "x083_ev_")
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
        "extraction_method" => "Targeted X083 exact-title public source review",
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
        "notes" => "X083 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X083 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

  manifest["status"] = "exact_title_external_rescue_x083_applied"
  artifacts["source_items"] = "e001_ingested_through_x083_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x083_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x083_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x083_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x083_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x083_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x083_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x083_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x083_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x083_from_current_x059_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x083_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x083"] = "generated_x083_for_exact_title_external_acquisition_rows"

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
  counts["x083_external_source_rescue_rows"] = applied_rows.size
  counts["x083_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x083"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x083"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x083_target_works_closed"],
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
    file.puts "# X083 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X083 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves generic selected-poems/stories rows, component-only rows, and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X083 |"
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
    "applied_id" => "x083_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x083.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x083.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_067_x083_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X083 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
