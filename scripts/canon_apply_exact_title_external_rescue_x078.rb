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

PACKET_ID = "X078"

SOURCE_REGISTRY_PATH = File.join(TABLE_DIR, "canon_source_registry.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SOURCE_DEBT_PATH = File.join(TABLE_DIR, "canon_source_debt_status.tsv")
ACTION_QUEUE_PATH = File.join(TABLE_DIR, "canon_cut_side_post_x058_action_queue.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
HIGH_RISK_RESIDUE_PATH = File.join(TABLE_DIR, "canon_high_risk_rescue_residue.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_external_source_rescue_evidence_applied_x078.tsv")
PACKET_STATUS_PATH = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_PATH = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_062_x078_exact_title_external_rescue.md")

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
    work_id: "work_candidate_latcarib_lit_book_sand",
    title: "The Book of Sand",
    creator: "Jorge Luis Borges",
    raw_date: "1975; English 1977",
    form_note: "Argentine short story collection",
    rationale: "Britannica and Penguin Random House confirm The Book of Sand as Borges's late major story collection.",
    sources: [
      ["x078_britannica_book_of_sand", "Britannica: The Book of Sand", "reference_encyclopedia", "Encyclopaedia Britannica, The Book of Sand, https://www.britannica.com/topic/The-Book-of-Sand", "Work reference entry", "https://www.britannica.com/topic/The-Book-of-Sand", "x078_britannica_exact_book_of_sand", "0.55", "reference_support_for_book_of_sand"],
      ["x078_prh_book_of_sand", "Penguin Random House: The Book of Sand and Shakespeare's Memory", "publisher_reference_series", "Penguin Random House, The Book of Sand and Shakespeare's Memory by Jorge Luis Borges, https://www.penguinrandomhouse.com/books/302517/the-book-of-sand-and-shakespeares-memory-by-jorge-luis-borges/", "Penguin Classics book page", "https://www.penguinrandomhouse.com/books/302517/the-book-of-sand-and-shakespeares-memory-by-jorge-luis-borges/", "x078_prh_exact_book_of_sand", "0.55", "publisher_support_for_book_of_sand"]
    ]
  },
  {
    work_id: "work_candidate_global_lit_burning_plain",
    title: "The Burning Plain",
    creator: "Juan Rulfo",
    raw_date: "1953; English 1967",
    form_note: "Mexican short story collection",
    rationale: "Britannica and University of Texas Press confirm The Burning Plain as the English title for Rulfo's El Llano en llamas story collection.",
    sources: [
      ["x078_britannica_burning_plain", "Britannica: The Burning Plain", "reference_encyclopedia", "Encyclopaedia Britannica, The Burning Plain, https://www.britannica.com/topic/The-Burning-Plain", "Work reference entry", "https://www.britannica.com/topic/The-Burning-Plain", "x078_britannica_exact_burning_plain", "0.55", "reference_support_for_burning_plain"],
      ["x078_utpress_burning_plain", "University of Texas Press: The Burning Plain", "publisher_reference_series", "University of Texas Press, The Burning Plain, https://utpress.utexas.edu/9781477329962/", "University of Texas Press book page", "https://utpress.utexas.edu/9781477329962/", "x078_utpress_exact_burning_plain", "0.55", "publisher_support_for_burning_plain"]
    ]
  },
  {
    work_id: "work_candidate_scale5_lit_lottery_stories",
    title: "The Lottery and Other Stories",
    creator: "Shirley Jackson",
    raw_date: "1949",
    form_note: "American Gothic short story collection",
    rationale: "Macmillan/Farrar, Straus and Giroux and Google Books confirm The Lottery and Other Stories as Shirley Jackson's lifetime story collection.",
    sources: [
      ["x078_macmillan_lottery_stories", "Macmillan: The Lottery and Other Stories", "publisher_reference_series", "Macmillan Publishers, The Lottery and Other Stories, https://us.macmillan.com/books/9781250910158/thelotteryandotherstories/", "Farrar, Straus and Giroux book page", "https://us.macmillan.com/books/9781250910158/thelotteryandotherstories/", "x078_macmillan_exact_lottery_stories", "0.55", "publisher_support_for_lottery_stories"],
      ["x078_google_books_lottery_stories", "Google Books: The Lottery and Other Stories", "publisher_reference_series", "Google Books, The Lottery and Other Stories by Shirley Jackson, https://books.google.com/books/about/The_Lottery_and_Other_Stories.html?id=B9hEAwAAQBAJ", "Google Books title record", "https://books.google.com/books/about/The_Lottery_and_Other_Stories.html?id=B9hEAwAAQBAJ", "x078_google_books_exact_lottery_stories", "0.55", "publisher_record_support_for_lottery_stories"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_new_net_fishing",
    title: "The New Net Goes Fishing",
    creator: "Witi Ihimaera",
    raw_date: "1977",
    form_note: "Maori short story collection",
    rationale: "Britannica and Encyclopedia.com confirm The New Net Goes Fishing as Witi Ihimaera's 1977 short story collection.",
    sources: [
      ["x078_britannica_new_net", "Britannica: The New Net Goes Fishing", "reference_encyclopedia", "Encyclopaedia Britannica, The New Net Goes Fishing, https://www.britannica.com/topic/New-Net-Goes-Fishing-The", "Work reference entry", "https://www.britannica.com/topic/New-Net-Goes-Fishing-The", "x078_britannica_exact_new_net", "0.55", "reference_support_for_new_net_goes_fishing"],
      ["x078_encyclopedia_new_net", "Encyclopedia.com: Witi Ihimaera", "language_literary_history", "Encyclopedia.com, Witi Ihimaera, https://www.encyclopedia.com/people/social-sciences-and-law/political-science-biographies/witi-ihimaera", "Author reference entry", "https://www.encyclopedia.com/people/social-sciences-and-law/political-science-biographies/witi-ihimaera", "x078_encyclopedia_exact_new_net", "0.55", "literary_history_support_for_new_net_goes_fishing"]
    ]
  },
  {
    work_id: "work_candidate_euro_under_lit_encyclopedia_dead",
    title: "The Encyclopedia of the Dead",
    creator: "Danilo Kis",
    raw_date: "1983; English 1989",
    form_note: "Yugoslav short story collection",
    rationale: "Northwestern University Press and Google Books confirm The Encyclopedia of the Dead as Danilo Kis's story collection in English translation.",
    sources: [
      ["x078_nup_encyclopedia_dead", "Northwestern University Press: Encyclopedia of the Dead", "publisher_reference_series", "Northwestern University Press, Encyclopedia of the Dead, https://nupress.northwestern.edu/9780810115149/encyclopedia-of-the-dead/", "Northwestern University Press book page", "https://nupress.northwestern.edu/9780810115149/encyclopedia-of-the-dead/", "x078_nup_exact_encyclopedia_dead", "0.55", "publisher_support_for_encyclopedia_dead"],
      ["x078_google_books_encyclopedia_dead", "Google Books: The Encyclopedia of the Dead", "publisher_reference_series", "Google Books, The Encyclopedia of the Dead by Danilo Kis, https://books.google.com/books/about/The_Encyclopedia_of_the_Dead.html?id=6eqzrQEACAAJ", "Google Books title record", "https://books.google.com/books/about/The_Encyclopedia_of_the_Dead.html?id=6eqzrQEACAAJ", "x078_google_books_exact_encyclopedia_dead", "0.55", "publisher_record_support_for_encyclopedia_dead"]
    ]
  },
  {
    work_id: "work_candidate_indig_lit_lone_ranger_tonto",
    title: "The Lone Ranger and Tonto Fistfight in Heaven",
    creator: "Sherman Alexie",
    raw_date: "1993",
    form_note: "Native American interconnected short story collection",
    rationale: "Grove Atlantic and National Book Foundation confirm The Lone Ranger and Tonto Fistfight in Heaven as Sherman Alexie's breakthrough story collection.",
    sources: [
      ["x078_grove_lone_ranger_tonto", "Grove Atlantic: The Lone Ranger and Tonto Fistfight in Heaven", "publisher_reference_series", "Grove Atlantic, The Lone Ranger and Tonto Fistfight in Heaven, https://groveatlantic.com/book/the-lone-ranger-and-tonto-fistfight-in-heaven/", "Grove Atlantic book page", "https://groveatlantic.com/book/the-lone-ranger-and-tonto-fistfight-in-heaven/", "x078_grove_exact_lone_ranger_tonto", "0.55", "publisher_support_for_lone_ranger_tonto"],
      ["x078_nbf_sherman_alexie_lone_ranger_tonto", "National Book Foundation: Sherman Alexie", "prize_or_reception_layer", "National Book Foundation, Sherman Alexie, https://www.nationalbook.org/people/sherman-alexie/", "Author profile", "https://www.nationalbook.org/people/sherman-alexie/", "x078_nbf_exact_lone_ranger_tonto", "0.55", "reception_support_for_lone_ranger_tonto"]
    ]
  },
  {
    work_id: "work_candidate_me_lit_madman_freedom_square",
    title: "The Madman of Freedom Square",
    creator: "Hassan Blasim",
    raw_date: "2009",
    form_note: "Iraqi short story collection in English translation",
    rationale: "Comma Press and English PEN confirm The Madman of Freedom Square as Hassan Blasim's 2009 short story collection translated by Jonathan Wright.",
    sources: [
      ["x078_comma_madman_freedom_square", "Comma Press: The Madman of Freedom Square", "publisher_reference_series", "Comma Press, The Madman of Freedom Square, https://commapress.co.uk/books/the-madman-of-freedom-square", "Comma Press book page", "https://commapress.co.uk/books/the-madman-of-freedom-square", "x078_comma_exact_madman_freedom_square", "0.55", "publisher_support_for_madman_freedom_square"],
      ["x078_english_pen_madman_freedom_square", "English PEN: The Madman of Freedom Square", "prize_or_reception_layer", "English PEN, The Madman of Freedom Square, https://www.englishpen.org/posts/news/the-madman-of-freedom-square/", "English PEN news entry", "https://www.englishpen.org/posts/news/the-madman-of-freedom-square/", "x078_english_pen_exact_madman_freedom_square", "0.55", "pen_reception_support_for_madman_freedom_square"]
    ]
  },
  {
    work_id: "work_candidate_bloom_late_033_literature_bloom_chaotic_age_reviewed_0892_the_collected_stories_of_colette",
    title: "The Collected Stories of Colette",
    creator: "Colette",
    raw_date: "1983; paperback 1984",
    form_note: "French short story collection in English translation",
    rationale: "Macmillan/Farrar, Straus and Giroux and Google Books confirm The Collected Stories of Colette as the comprehensive English-language collection edited by Robert Phelps.",
    sources: [
      ["x078_macmillan_collected_colette", "Macmillan: Collected Stories of Colette", "publisher_reference_series", "Macmillan Publishers, Collected Stories of Colette, https://us.macmillan.com/books/9780374518653/collectedstoriesofcolette/", "Farrar, Straus and Giroux book page", "https://us.macmillan.com/books/9780374518653/collectedstoriesofcolette/", "x078_macmillan_exact_collected_colette", "0.55", "publisher_support_for_collected_colette"],
      ["x078_google_books_collected_colette", "Google Books: Collected Stories of Colette", "publisher_reference_series", "Google Books, Collected Stories of Colette, https://books.google.com/books/about/Collected_Stories_of_Colette.html?id=TVvoRX9IblIC", "Google Books title record", "https://books.google.com/books/about/Collected_Stories_of_Colette.html?id=TVvoRX9IblIC", "x078_google_books_exact_collected_colette", "0.55", "publisher_record_support_for_collected_colette"]
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
  ["work_candidate_bloom_maupassant_selected_stories", "Boule de Suif and Selected Stories", "Guy de Maupassant", "Selected-stories row; needs edition/selection policy."]
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
  source_id.sub(/\Ax078_/, "x078_item_")
end

def evidence_id(source_id)
  source_id.sub(/\Ax078_/, "x078_ev_")
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
        "extraction_method" => "Targeted X078 exact-title public source review",
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
        "notes" => "X078 accepted external exact-title support; no cut or replacement approved."
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
      "notes" => "X078 accepted targeted public source support for exact-title source rescue; no public canon replacement approved."
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

  manifest["status"] = "exact_title_external_rescue_x078_applied"
  artifacts["source_items"] = "e001_ingested_through_x078_exact_title_source_items"
  artifacts["evidence"] = "e001_ingested_policy_aware_rows_through_x078_exact_title_external_support"
  artifacts["source_debt_status"] = "refreshed_after_x078_exact_title_external_rescue"
  artifacts["scoring_inputs"] = "refreshed_after_x078_exact_title_external_rescue"
  artifacts["scores"] = "regenerated_x078_provisional_ready_rows_only"
  artifacts["replacement_candidates"] = "regenerated_after_x078_blocked_add_cut_pairings"
  artifacts["cut_candidates"] = "regenerated_after_x078_all_incumbent_cut_risk_table"
  artifacts["generic_selection_basis_review"] = "regenerated_x051_after_x078_from_cut_review_work_orders"
  artifacts["cut_side_post_x058_action_queue"] = "refreshed_after_x078_from_current_x051"
  artifacts["current_rescue_scope_review"] = "refreshed_x065_after_x078_from_current_x062_existing_source_rescue_lane"
  artifacts["high_risk_rescue_residue"] = "refreshed_x063_after_x078_from_current_x065_high_risk_rows"
  artifacts["external_source_rescue_evidence_applied_x078"] = "generated_x078_for_exact_title_external_acquisition_rows"

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
  counts["x078_external_source_rescue_rows"] = applied_rows.size
  counts["x078_target_works_closed"] = TARGETS.count do |target|
    !source_debt_after.fetch(target.fetch(:work_id)).fetch("source_debt_status").start_with?("open_")
  end
  counts["current_high_risk_residue_rows_after_x078"] = high_risk_rows.size

  manifest["exact_title_external_rescue_x078"] = {
    "status" => "applied_public_sources_for_exact_title_rows",
    "target_work_rows" => TARGETS.size,
    "source_registry_rows_added_or_updated" => new_registry_rows.size,
    "source_item_rows_added_or_updated" => new_source_items.size,
    "evidence_rows_added_or_updated" => new_evidence_rows.size,
    "target_source_debt_closed_after_refresh" => counts["x078_target_works_closed"],
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
    file.puts "# X078 Exact-Title External Rescue"
    file.puts
    file.puts "Status: completed, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "X078 closes exact-title source-debt blockers where at least two independent public support families were available. It deliberately leaves selected-poems/stories rows and thinly sourced exact-title rows for a separate policy pass."
    file.puts
    file.puts "## Target Status"
    file.puts
    file.puts "| Work | Creator | Evidence rows | Source debt after X078 |"
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
    "applied_id" => "x078_external_source_rescue_#{index.to_s.rjust(4, "0")}",
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
      "_planning/canon_build/tables/canon_external_source_rescue_evidence_applied_x078.tsv",
      "scripts/canon_apply_exact_title_external_rescue_x078.rb",
      "_planning/canon_build/source_crosswalk_reports/x_batch_062_x078_exact_title_external_rescue.md"
    ].join(";"),
    "next_action" => "continue_external_source_acquisition_queue_and_selection_scope_policy_rows",
    "notes" => "#{new_evidence_rows.size} accepted external evidence rows applied across #{TARGETS.size} works; source debt closed=#{closed_count}; public canon unchanged"
  }
)

update_manifest(applied_rows, source_debt_after, lane_counts, high_risk_rows, new_registry_rows, new_source_items, new_evidence_rows)
write_report(applied_rows, source_debt_after, lane_counts, high_risk_rows)

puts "applied #{applied_rows.size} X078 exact-title external source evidence rows"
puts "target works closed: #{closed_count}/#{TARGETS.size}"
lane_counts.sort.each { |lane, count| puts "#{lane}: #{count}" }
puts "current high-risk residues: #{high_risk_rows.size}"
