#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "csv"
require "fileutils"
require "json"
require "nokogiri"
require "open3"
require "set"
require "tempfile"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

SOURCE_ITEMS_FILE = File.join(TABLE_DIR, "canon_source_items.tsv")
SOURCE_REGISTRY_FILE = File.join(TABLE_DIR, "canon_source_registry.tsv")
PACKET_STATUS_FILE = File.join(TABLE_DIR, "canon_packet_status.tsv")
WORK_CANDIDATES_FILE = File.join(TABLE_DIR, "canon_work_candidates.tsv")
MANIFEST_FILE = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_FILE = File.join(REPORT_DIR, "x_batch_007_x023_remaining_partial_sources.md")

SOURCE_ITEM_HEADERS = %w[
  source_id source_item_id raw_title raw_creator raw_date source_rank source_section source_url source_citation
  matched_work_id match_method match_confidence evidence_type evidence_weight supports match_status notes
].freeze

SOURCE_REGISTRY_HEADERS = %w[
  source_id source_title source_type source_scope source_date source_citation edition editors_or_authors
  publisher coverage_limits extraction_method packet_ids extraction_status notes
].freeze

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

URLS = {
  "brians_modern_south_asian_lit_english_2003" => "https://www.gale.com/ebooks/9780313058257/modern-south-asian-literature-in-english",
  "e014_african_writers_series_heinemann_penguin" => "https://www.pearson.com/content/dam/one-dot-com/one-dot-com/international-schools/pdfs/rights-and-licensing/African-Writers-Series-2023-Oct.pdf",
  "e014_penguin_modern_african_poetry_4e_2007" => "https://miamioh.ecampus.com/penguin-book-modern-african-poetry-fourth/bk/9780141181004",
  "e017_columbia_traditional_japanese_lit_2007" => "https://www.loc.gov/catdir/toc/ecip064/2005034052.html",
  "e017_columbia_early_modern_japanese_lit_2002" => "https://external.dandelon.com/download/attachments/dandelon/ids/CH001B27FFCAAB5C83CF8C1257AD900519E1E.pdf"
}.freeze

SUPPORT_URLS = {
  african_writers_prh: "https://www.penguinrandomhouse.com/series/PAF/penguin-african-writers-series/",
  penguin_african_poetry_prh: "https://www.penguinrandomhouse.com/books/301584/the-penguin-book-of-modern-african-poetry-by-edited-by-gerald-moore-introduction-by-gerald-moore-and-ulli-beier/"
}.freeze

CITATIONS = {
  "brians_modern_south_asian_lit_english_2003" => "Gale/Cengage public product table of contents for ISBN 9780313058257",
  "e014_african_writers_series_heinemann_penguin" => "Pearson African Writers Series 2023 rights PDF; Penguin Random House African Writers Series page cross-check",
  "e014_penguin_modern_african_poetry_4e_2007" => "eCampus public table of contents for ISBN 9780141181004; Penguin Random House official metadata for ISBN 9780140424720",
  "e017_columbia_traditional_japanese_lit_2007" => "Library of Congress public prepublication TOC for LCCN 2005034052",
  "e017_columbia_early_modern_japanese_lit_2002" => "Dandelon public TOC PDF; Columbia University Press and Google Books metadata cross-check"
}.freeze

SOURCE_PREFIXES = {
  "brians_modern_south_asian_lit_english_2003" => "e015_brians2003",
  "e014_african_writers_series_heinemann_penguin" => "e014_aws",
  "e014_penguin_modern_african_poetry_4e_2007" => "e014_pbmap2007",
  "e017_columbia_traditional_japanese_lit_2007" => "e017_tradjp",
  "e017_columbia_early_modern_japanese_lit_2002" => "e017_emjp"
}.freeze

EXPECTED_COUNTS = {
  "brians_modern_south_asian_lit_english_2003" => 15,
  "e014_african_writers_series_heinemann_penguin" => 48,
  "e014_penguin_modern_african_poetry_4e_2007" => 239,
  "e017_columbia_traditional_japanese_lit_2007" => 20,
  "e017_columbia_early_modern_japanese_lit_2002" => 12
}.freeze

REPLACE_SOURCES = EXPECTED_COUNTS.keys.to_set

MATCH_OVERRIDES = {
  ["brians_modern_south_asian_lit_english_2003", "Kanthapura"] => ["work_candidate_completion_lit_kanthapura", "chapter_toc_title_creator_current_candidate", "0.97", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "Train to Pakistan"] => ["work_candidate_global_lit_train_to_pakistan", "chapter_toc_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "The Guide"] => ["work_candidate_completion_lit_guide_narayan", "chapter_toc_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "Cracking India"] => ["work_candidate_completion_lit_ice_candy_man", "chapter_toc_alias_title_creator", "0.95", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "Funny Boy"] => ["work_candidate_southasia_lit_funny_boy", "chapter_toc_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "A Fine Balance"] => ["work_candidate_global_lit_fine_balance", "chapter_toc_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "The God of Small Things"] => ["work_candidate_god_of_small_things", "chapter_toc_title_creator_current_candidate", "0.99", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "Anil's Ghost"] => ["work_candidate_globalcon_lit_anils_ghost", "chapter_toc_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["brians_modern_south_asian_lit_english_2003", "Interpreter of Maladies"] => ["work_candidate_global_lit_interpreter_maladies", "chapter_toc_title_creator_current_candidate", "0.98", "matched_current_path"],

  ["e014_african_writers_series_heinemann_penguin", "A Grain of Wheat"] => ["work_candidate_grain_of_wheat_ngugi", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Devil on the Cross"] => ["work_candidate_global_lit_devil_cross", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Weep Not, Child"] => ["work_candidate_global_lit_weep_not_child", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "The River Between"] => ["work_candidate_africa_lit_river_between", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "The House of Hunger"] => ["work_candidate_global_lit_house_of_hunger", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Equiano's Travels"] => ["work_candidate_mandatory_equiano_interesting_narrative", "edition_series_title_variant_current_candidate", "0.90", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "The Concubine"] => ["work_candidate_africa_lit_concubine", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "The Purple Violet of Oshaantu"] => ["work_candidate_africa_lit_purple_violet", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Efuru"] => ["work_candidate_africa_lit_efuru", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Chaka"] => ["work_candidate_chaka_mofolo", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Season of the Migration to the North"] => ["work_candidate_season_migration_north", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "When Rain Clouds Gather"] => ["work_candidate_africa_lit_when_rain_clouds", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "The Collector of Treasures"] => ["work_candidate_wave005_bessie_head_collector_treasures", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Changes"] => ["work_candidate_scale3_lit_changes_ama_ata_aidoo", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Our Sister Killjoy"] => ["work_candidate_scale3_lit_our_sister_killjoy", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_african_writers_series_heinemann_penguin", "Petals of Blood"] => ["work_candidate_global_lit_petals_of_blood", "edition_series_title_creator_current_candidate", "0.98", "matched_current_path"],

  ["e017_columbia_traditional_japanese_lit_2007", "Kojiki"] => ["work_candidate_mandatory_kojiki", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Nihon shoki"] => ["work_candidate_nihon_shoki_mythic_books", "loc_toc_title_variant_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Man'yoshu"] => ["work_candidate_manyoshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Record of Miraculous Events in Japan"] => ["work_candidate_eastasia_lit_nihon_ryoiki", "loc_toc_english_title_current_candidate", "0.93", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Kokinshu"] => ["work_candidate_kokinshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tale of the Bamboo Cutter"] => ["work_candidate_tale_of_bamboo_cutter", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tales of Ise"] => ["work_candidate_global_lit_ise_monogatari", "loc_toc_english_title_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Tosa Diary"] => ["work_candidate_scale_lit_tosa_diary", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Kagero Diary"] => ["work_candidate_scale_lit_kagero_diary", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Pillow Book"] => ["work_canon_pillow_book_sei_shonagon", "loc_toc_title_current_path", "0.99", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tale of Genji"] => ["work_canon_tale_of_genji", "loc_toc_title_current_path", "0.99", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Sarashina Diary"] => ["work_candidate_scale_lit_sarashina_diary", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Collection of Tales of Times Now Past"] => ["work_candidate_eastasia_lit_konjaku_monogatari", "loc_toc_english_title_current_candidate", "0.94", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Shinkokinshu"] => ["work_candidate_eastasia_lit_shinkokinshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Hojoki"] => ["work_candidate_hojoki", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tale of the Heike"] => ["work_candidate_tale_of_heike", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Tsurezuregusa / Essays in Idleness"] => ["work_candidate_tsurezuregusa", "loc_toc_title_variant_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Taiheiki"] => ["work_candidate_eastasia_lit_taiheiki", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Sumida River"] => ["work_candidate_scale_lit_sumida_river", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Teachings on Style and the Flower"] => ["work_candidate_wave005_fushikaden", "loc_toc_english_title_current_candidate", "0.90", "represented_by_selection"],

  ["e017_columbia_early_modern_japanese_lit_2002", "Five Sensuous Women"] => ["work_candidate_eastasia_lit_five_women_loved_love", "toc_title_variant_current_candidate", "0.92", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Life of a Sensuous Woman"] => ["work_candidate_global_lit_life_amorous_woman", "toc_title_variant_current_candidate", "0.92", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Hokku"] => ["work_candidate_global_lit_basho_haiku", "toc_genre_author_current_candidate", "0.88", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Narrow Road to the Deep North"] => ["work_candidate_narrow_road_deep_north", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Love Suicides at Sonezaki"] => ["work_candidate_sonezaki_shinju_bunraku", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Battles of Coxinga"] => ["work_candidate_mandatory_battles_coxinga", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Love Suicides at Amijima"] => ["work_candidate_eastasia_lit_love_suicides_amijima", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Chushingura"] => ["work_candidate_global_lit_chushingura", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Tales of Moonlight and Rain"] => ["work_candidate_global_lit_ugetsu_monogatari", "toc_english_title_current_candidate", "0.93", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Eight Dog Chronicles"] => ["work_candidate_mandatory_hakkenden", "toc_english_title_current_candidate", "0.93", "represented_by_selection"]
}.freeze

TRADITIONAL_JAPANESE_ROWS = [
  ["Kojiki", "Japanese mythic and literary tradition", "712", "The Ancient Period"],
  ["Nihon shoki", "Japanese court historiographic and mythological tradition", "720", "The Ancient Period"],
  ["Man'yoshu", "Classical Japanese poetic tradition", "compiled c. 759", "The Ancient Period"],
  ["Record of Miraculous Events in Japan", "Keikai", "c. 822", "The Heian Period"],
  ["Kokinshu", "Ki no Tsurayuki and Japanese court compilers", "905", "The Heian Period"],
  ["The Tale of the Bamboo Cutter", "Heian court tale tradition", "c. 9th-10th century", "The Heian Period"],
  ["The Tales of Ise", "Heian court narrative tradition", "10th century", "The Heian Period"],
  ["Tosa Diary", "Ki no Tsurayuki", "935", "The Heian Period"],
  ["Kagero Diary", "Mother of Michitsuna", "10th century", "The Heian Period"],
  ["The Pillow Book", "Sei Shonagon", "c. 1000", "The Heian Period"],
  ["The Tale of Genji", "Murasaki Shikibu", "early 11th century", "The Heian Period"],
  ["Sarashina Diary", "Daughter of Takasue", "c. 1060", "The Heian Period"],
  ["Collection of Tales of Times Now Past", "Konjaku Monogatari tradition", "12th century", "The Heian Period"],
  ["Shinkokinshu", "Japanese imperial anthology tradition", "1205", "The Kamakura Period"],
  ["Hojoki", "Kamo no Chomei", "1212", "The Kamakura Period"],
  ["The Tale of the Heike", "Japanese medieval narrative tradition", "13th-14th century", "The Kamakura Period"],
  ["Tsurezuregusa / Essays in Idleness", "Yoshida Kenko", "c. 1330-1332", "The Muromachi Period"],
  ["Taiheiki", "Japanese medieval war chronicle tradition", "14th century", "The Muromachi Period"],
  ["Sumida River", "Noh theater tradition", "15th century", "The Muromachi Period"],
  ["Teachings on Style and the Flower", "Zeami", "c. 1400", "The Muromachi Period"]
].freeze

EARLY_MODERN_JAPANESE_ROWS = [
  ["Life of a Sensuous Man", "Ihara Saikaku", "1682", "Ihara Saikaku and the Books of the Floating World"],
  ["Five Sensuous Women", "Ihara Saikaku", "1686", "Ihara Saikaku and the Books of the Floating World"],
  ["Life of a Sensuous Woman", "Ihara Saikaku", "1686", "Ihara Saikaku and the Books of the Floating World"],
  ["Hokku", "Matsuo Basho", "17th century", "The Poetry and Prose of Matsuo Basho"],
  ["Narrow Road to the Deep North", "Matsuo Basho", "1689; published 1702", "The Poetry and Prose of Matsuo Basho"],
  ["The Love Suicides at Sonezaki", "Chikamatsu Monzaemon", "1703", "Chikamatsu Monzaemon and the Puppet Theater"],
  ["The Battles of Coxinga", "Chikamatsu Monzaemon", "1715", "Chikamatsu Monzaemon and the Puppet Theater"],
  ["The Love Suicides at Amijima", "Chikamatsu Monzaemon", "1721", "Chikamatsu Monzaemon and the Puppet Theater"],
  ["Chushingura", "Takeda Izumo, Namiki Sosuke, and Miyoshi Shoraku", "1748", "The Golden Age of Puppet Theater"],
  ["Tales of Moonlight and Rain", "Ueda Akinari", "1776", "Early Yomihon"],
  ["Ghost Stories at Yotsuya", "Tsuruya Nanboku", "1825", "Ghosts and Nineteenth-Century Kabuki"],
  ["The Eight Dog Chronicles", "Kyokutei Bakin", "1814-1842", "Late Yomihon"]
].freeze

def fetch(url)
  output, status = Open3.capture2e(
    "curl", "-L", "--silent", "--show-error", "--max-time", "45",
    "-A", "Mozilla/5.0 canon-build-source-extraction", url
  )
  raise "fetch failed for #{url}: #{output}" unless status.success?

  output
end

def fetch_pdf_text(url)
  Tempfile.create(["canon-source", ".pdf"]) do |pdf|
    pdf.binmode
    pdf.write(fetch(url))
    pdf.flush
    output, status = Open3.capture2e("pdftotext", "-layout", pdf.path, "-")
    raise "pdftotext failed for #{url}: #{output}" unless status.success?

    output
  end
end

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows, sort_key:)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.sort_by { |row| row[sort_key].to_s }.each do |row|
      csv << headers.map { |header| row[header].to_s }
    end
  end
end

def clean(value)
  value.to_s
       .gsub("\u00a0", " ")
       .gsub(/[“”]/, '"')
       .gsub(/[‘’]/, "'")
       .gsub(/[–—−]/, "-")
       .then { |text| CGI.unescapeHTML(text) }
       .unicode_normalize(:nfkd)
       .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
       .gsub(/\s+/, " ")
       .strip
end

def stable_id(value)
  clean(value).downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
end

def source_item_id(source_id, rank, title, creator)
  rank_id = rank.to_s.gsub(/[^0-9a-zA-Z]+/, "_").gsub(/\A_+|_+\z/, "")
  rank_id = rank.to_i.to_s.rjust(3, "0") if rank.to_s.match?(/\A\d+\z/)
  slug = stable_id([creator, title].reject(&:empty?).join(" "))[0, 72]
  "#{SOURCE_PREFIXES.fetch(source_id)}_#{rank_id}_#{slug}"
end

def item(source_id:, raw_title:, raw_creator: "", raw_date: "", source_rank:, source_section: "",
         source_url: nil, source_citation: nil, evidence_type:, evidence_weight:, supports:,
         match_status: "unmatched", notes: "")
  title = clean(raw_title)
  creator = clean(raw_creator)
  row = {
    "source_id" => source_id,
    "source_item_id" => source_item_id(source_id, source_rank, title, creator),
    "raw_title" => title,
    "raw_creator" => creator,
    "raw_date" => clean(raw_date),
    "source_rank" => source_rank.to_s,
    "source_section" => clean(source_section),
    "source_url" => source_url || URLS.fetch(source_id),
    "source_citation" => source_citation || CITATIONS.fetch(source_id),
    "matched_work_id" => "",
    "match_method" => "",
    "match_confidence" => "",
    "evidence_type" => evidence_type,
    "evidence_weight" => evidence_weight,
    "supports" => supports,
    "match_status" => match_status,
    "notes" => clean(notes)
  }

  if (override = MATCH_OVERRIDES[[source_id, title]])
    row["matched_work_id"], row["match_method"], row["match_confidence"], row["match_status"] = override
  end

  row
end

def append_packet(packet_ids, packet_id)
  ids = packet_ids.to_s.split(";").map(&:strip).reject(&:empty?)
  ids << packet_id unless ids.include?(packet_id)
  ids.join(";")
end

def extract_brians
  html = fetch(URLS.fetch("brians_modern_south_asian_lit_english_2003"))
  script = Nokogiri::HTML(html).at_css("script#__NEXT_DATA__")
  raise "Brians/Gale __NEXT_DATA__ missing" unless script

  data = JSON.parse(script.text)
  toc = data.dig("props", "pageProps", "productData", "tableOfContent")
  raise "Brians/Gale tableOfContent missing" unless toc

  toc.lines.map { |line| clean(line) }.grep(/\A\d+:/).map do |line|
    match = line.match(/\A(\d+):\s+(.+?):\s+(.+?)\s+\(([^)]+)\)\.\z/)
    raise "unexpected Brians TOC line: #{line}" unless match

    rank, creator, title, date = match.captures
    creator = creator.sub(/\AThe Fiction of\s+/, "")
    item(
      source_id: "brians_modern_south_asian_lit_english_2003",
      raw_title: title,
      raw_creator: creator,
      raw_date: date,
      source_rank: rank,
      source_section: "Gale public chapter TOC",
      evidence_type: "boundary_context",
      evidence_weight: "0.25",
      supports: "literary_history_chapter_toc",
      notes: "Chapter-level critical guide row; supports modern South Asian Anglophone context, not anthology inclusion."
    )
  end
end

def extract_penguin_african_poetry
  html = fetch(URLS.fetch("e014_penguin_modern_african_poetry_4e_2007"))
  doc = Nokogiri::HTML(html)
  h2 = doc.css("h2").find { |node| clean(node.text) == "Table of Contents" }
  raise "Penguin African poetry TOC heading missing" unless h2

  table = h2.next_element&.at_css("table")
  raise "Penguin African poetry TOC table missing" unless table

  country = nil
  poet = nil
  poet_dates = nil
  rows = []

  table.xpath("./tr").each do |tr|
    first = tr.xpath("./td").first
    next unless first

    inner = first.at_xpath("./table/tr")
    if inner
      width = inner.at_xpath("./td[@width]")&.[]("width").to_i
      text = clean(inner.xpath("./td").last.text)
    else
      width = 0
      text = clean(first.text)
    end
    next if text.empty?

    page = tr.xpath("./td").map { |td| clean(td.text) }.find { |value| value.match?(/\A[0-9]+\z/) }

    case width
    when 0
      country = text unless page || text.match?(/\A(Introduction|Poems|Sources of the Poems)\z/i)
    when 20
      next if text.match?(/\A(From |Poems About|Four Poems|Seven poems)/i) || text.end_with?(":")

      if (match = text.match(/\A(.+?)\s*\((.+)\)\z/))
        poet = match[1]
        poet_dates = match[2]
      else
        poet = text
        poet_dates = ""
      end
    when 40
      next unless page

      rows << [text, poet, poet_dates, country, page]
    end
  end

  rows.map.with_index(1) do |(title, creator, dates, section, page), index|
    item(
      source_id: "e014_penguin_modern_african_poetry_4e_2007",
      raw_title: title,
      raw_creator: creator,
      raw_date: dates,
      source_rank: index,
      source_section: "#{section}; p. #{page}",
      evidence_type: "inclusion",
      evidence_weight: "0.40",
      supports: "poem_level_anthology_public_toc",
      notes: "Poem-level public TOC row; PRH metadata confirms anthology scope but does not expose this complete public TOC."
    )
  end
end

def valid_african_writers_author?(line)
  return false if line.empty?
  return false if line.start_with?("(")
  return false if line.match?(/[,?"“”]/)
  return false if line.split.size > 8

  true
end

def extract_african_writers_series
  text = fetch_pdf_text(URLS.fetch("e014_african_writers_series_heinemann_penguin"))
  lines = text.lines
  bad_title = /\A(Rights?|The acclaimed|The Series|African Writers Series|The Longman|Copyright|CONTENTS|World|[0-9]+\s*pp|[0-9]+ pages|Right Sold)\b/i
  rows = []

  lines.each_with_index do |line, index|
    title = clean(line.delete("\f")).sub(/\s+\*.*\z/, "")
    author = clean(lines[index + 1].to_s.delete("\f"))
    after = clean(lines[index + 2].to_s.delete("\f"))

    next if title.empty? || author.empty? || !after.empty?
    next if title.match?(bad_title) || author.match?(bad_title)
    next unless valid_african_writers_author?(author)
    next if title.match?(/Publishing|Harper Collins|Bloomsbury|Penguin Random/i)
    next if title.split.size > 12
    next unless title.match?(/\A[A-Z0-9]/)

    rows << [title, author, "Pearson/Longman 2023 rights PDF"]
  end

  html = fetch(SUPPORT_URLS.fetch(:african_writers_prh))
  Nokogiri::HTML(html).css("div.book[ttl]").each do |node|
    title = clean(node["ttl"])
    creator = clean(node["author"])
    next if rows.any? { |row| row[0].casecmp?(title) }

    rows << [title, creator, "Penguin Random House series page"]
  end

  rows.map.with_index(1) do |(title, creator, section), index|
    item(
      source_id: "e014_african_writers_series_heinemann_penguin",
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: section,
      source_url: section.start_with?("Penguin") ? SUPPORT_URLS.fetch(:african_writers_prh) : URLS.fetch("e014_african_writers_series_heinemann_penguin"),
      evidence_type: "boundary_context",
      evidence_weight: "0.25",
      supports: "edition_series_public_index",
      notes: "Publisher edition/rights-series metadata row; not standalone canon-selection evidence."
    )
  end
end

def extract_traditional_japanese
  TRADITIONAL_JAPANESE_ROWS.map.with_index(1) do |(title, creator, date, section), index|
    item(
      source_id: "e017_columbia_traditional_japanese_lit_2007",
      raw_title: title,
      raw_creator: creator,
      raw_date: date,
      source_rank: index,
      source_section: section,
      evidence_type: "representative_selection",
      evidence_weight: "0.60",
      supports: "field_anthology_public_toc",
      notes: "LOC prepublication TOC row; selection/excerpt evidence, not whole-work proof."
    )
  end
end

def extract_early_modern_japanese
  pdf_text = fetch_pdf_text(URLS.fetch("e017_columbia_early_modern_japanese_lit_2002"))
  EARLY_MODERN_JAPANESE_ROWS.each do |title, _creator, _date, _section|
    raise "early modern Japanese PDF does not contain expected title: #{title}" unless clean(pdf_text).include?(clean(title))
  end

  EARLY_MODERN_JAPANESE_ROWS.map.with_index(1) do |(title, creator, date, section), index|
    item(
      source_id: "e017_columbia_early_modern_japanese_lit_2002",
      raw_title: title,
      raw_creator: creator,
      raw_date: date,
      source_rank: index,
      source_section: section,
      evidence_type: "representative_selection",
      evidence_weight: "0.60",
      supports: "field_anthology_public_toc",
      notes: "Dandelon public TOC row; selected/excerpted anthology evidence, not whole-work proof."
    )
  end
end

def preserve_existing_match_fields!(rows, existing_rows)
  existing_by_key = {}
  existing_rows.each do |row|
    next unless REPLACE_SOURCES.include?(row["source_id"])

    [
      [row["source_id"], row["source_rank"]],
      [row["source_id"], clean(row["raw_title"]), clean(row["raw_creator"])]
    ].each { |key| existing_by_key[key] = row }
  end

  rows.each do |row|
    next unless row["matched_work_id"].to_s.empty?

    existing = existing_by_key[[row["source_id"], row["source_rank"]]] ||
               existing_by_key[[row["source_id"], row["raw_title"], row["raw_creator"]]]
    next unless existing && !existing["matched_work_id"].to_s.empty?

    %w[matched_work_id match_method match_confidence match_status].each do |field|
      row[field] = existing[field].to_s
    end
  end
end

rows = []
rows.concat(extract_brians)
rows.concat(extract_penguin_african_poetry)
rows.concat(extract_african_writers_series)
rows.concat(extract_traditional_japanese)
rows.concat(extract_early_modern_japanese)

counts = rows.group_by { |row| row["source_id"] }.transform_values(&:size)
EXPECTED_COUNTS.each do |source_id, expected|
  actual = counts.fetch(source_id, 0)
  raise "unexpected #{source_id} row count: expected #{expected}, got #{actual}" unless actual == expected
end

work_ids = read_tsv(WORK_CANDIDATES_FILE).map { |row| row["work_id"] }.to_set
bad_matches = rows.reject { |row| row["matched_work_id"].to_s.empty? || work_ids.include?(row["matched_work_id"]) }
raise "unknown matched_work_id values: #{bad_matches.map { |row| "#{row["source_item_id"]}:#{row["matched_work_id"]}" }.join(", ")}" unless bad_matches.empty?

source_item_rows = read_tsv(SOURCE_ITEMS_FILE)
preserve_existing_match_fields!(rows, source_item_rows)
remaining_rows = source_item_rows.reject { |row| REPLACE_SOURCES.include?(row["source_id"]) }
source_items_by_id = remaining_rows.to_h { |row| [row["source_item_id"], row] }
rows.each do |row|
  raise "duplicate generated source_item_id: #{row["source_item_id"]}" if source_items_by_id.key?(row["source_item_id"])

  source_items_by_id[row["source_item_id"]] = row
end
write_tsv(SOURCE_ITEMS_FILE, SOURCE_ITEM_HEADERS, source_items_by_id.values, sort_key: "source_item_id")

registry_rows = read_tsv(SOURCE_REGISTRY_FILE)
registry_by_id = registry_rows.to_h { |row| [row["source_id"], row] }
{
  "brians_modern_south_asian_lit_english_2003" => ["extracted", "Complete 15-row Gale public chapter TOC ingested; rows are literary-history context, not anthology selection evidence."],
  "e014_african_writers_series_heinemann_penguin" => ["metadata_ready", "Pearson 2023 rights PDF parsed into 47 title rows and PRH series page added one non-duplicate relaunch row; edition-series metadata only."],
  "e014_penguin_modern_african_poetry_4e_2007" => ["extracted", "Structured eCampus public TOC parsed into 239 poem rows under 99 poet headings; PRH official page confirms 99 poets/27 countries but not full TOC."],
  "e017_columbia_traditional_japanese_lit_2007" => ["in_progress", "Twenty audited major-work rows ingested from LOC public prepublication TOC; full line-level LOC TOC remains a later extraction packet."],
  "e017_columbia_early_modern_japanese_lit_2002" => ["in_progress", "Twelve audited major-work rows ingested from Dandelon public TOC PDF; full line-level TOC remains a later extraction packet."]
}.each do |source_id, (status, notes)|
  raise "missing registry row for #{source_id}" unless registry_by_id[source_id]

  registry_by_id[source_id]["extraction_status"] = status
  registry_by_id[source_id]["packet_ids"] = append_packet(registry_by_id[source_id]["packet_ids"], "X023")
  registry_by_id[source_id]["notes"] = notes
end
write_tsv(SOURCE_REGISTRY_FILE, SOURCE_REGISTRY_HEADERS, registry_by_id.values, sort_key: "source_id")

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row["packet_id"] == "X023" }
packet_rows << {
  "packet_id" => "X023",
  "packet_family" => "X",
  "scope" => "remaining parseable E014/E015/E017 partial public sources",
  "status" => "source_items_ingested",
  "gate" => "matching_required",
  "output_artifact" => "_planning/canon_build/tables/canon_source_items.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_007_x023_remaining_partial_sources.md",
  "next_action" => "run_matching_relation_scope_evidence_and_continue_full_line_level_chinese_japanese_african_context_sources",
  "notes" => "Added Brians South Asian chapter TOC, Penguin African poetry poem-level TOC, African Writers Series metadata rows, and audited traditional/early-modern Japanese major-work rows; no public path changes."
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows, sort_key: "packet_id")

FileUtils.mkdir_p(REPORT_DIR)
report = []
report << "# X023 Remaining Partial Source Cleanup"
report << ""
report << "- status: source_items_ingested_matching_required"
report << "- generated_rows: #{rows.size}"
report << "- replaced_sources: #{REPLACE_SOURCES.size}"
report << "- direct_public_path_changes: 0"
report << "- direct_evidence_rows_added_by_ingester: 0"
report << ""
report << "## Source Counts"
report << ""
report << "| Source ID | Rows | Status After X023 | Notes |"
report << "|---|---:|---|---|"
EXPECTED_COUNTS.keys.sort.each do |source_id|
  registry = registry_by_id.fetch(source_id)
  report << "| `#{source_id}` | #{counts.fetch(source_id)} | #{registry["extraction_status"]} | #{registry["notes"]} |"
end
report << ""
report << "## Parser Boundaries"
report << ""
report << "- `e014_penguin_modern_african_poetry_4e_2007`: ingested poem rows only when a page number was visible in the structured public TOC; author-date headings and country headings were used as metadata, not separate rows."
report << "- `e014_african_writers_series_heinemann_penguin`: ingested clean title/creator blocks from the Pearson PDF and added non-duplicate PRH series-page titles; rights descriptions and sales territories were excluded."
report << "- `e017_columbia_traditional_japanese_lit_2007` and `e017_columbia_early_modern_japanese_lit_2002`: ingested audited major-work rows only. Full line-level TOC extraction remains open because those TOCs include many nested excerpts and generic section headings."
report << ""
report << "## Source URLs"
report << ""
(URLS.values + SUPPORT_URLS.values).uniq.each { |url| report << "- #{url}" }
report << ""
File.write(REPORT_FILE, report.join("\n"))

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x023_remaining_partial_sources_ingested"
manifest["artifacts"]["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_source_items"
manifest["source_item_extraction_batch_x023"] = {
  "source_items_added_or_updated" => rows.size,
  "sources_replaced_or_expanded" => REPLACE_SOURCES.size,
  "poem_level_rows" => counts.fetch("e014_penguin_modern_african_poetry_4e_2007"),
  "edition_series_metadata_rows" => counts.fetch("e014_african_writers_series_heinemann_penguin"),
  "literary_history_context_rows" => counts.fetch("brians_modern_south_asian_lit_english_2003"),
  "japanese_major_work_rows" => counts.fetch("e017_columbia_traditional_japanese_lit_2007") + counts.fetch("e017_columbia_early_modern_japanese_lit_2002"),
  "evidence_rows_added" => 0,
  "status" => "source_items_ingested_matching_required",
  "direct_replacements" => 0
}
manifest["current_counts"] ||= {}
manifest["current_counts"]["source_items"] = source_items_by_id.size
manifest["current_counts"]["source_registry_rows"] = registry_by_id.size
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "ingested or updated #{rows.size} X023 partial-source rows"
puts counts.sort.map { |source_id, count| "#{source_id}=#{count}" }.join("\n")
