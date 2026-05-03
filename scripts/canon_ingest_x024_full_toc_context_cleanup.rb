#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "csv"
require "fileutils"
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
REPORT_FILE = File.join(REPORT_DIR, "x_batch_008_x024_full_toc_context_cleanup.md")
EXTRACTION_PLAN_FILE = File.join(BUILD_DIR, "source_item_extraction_plan.md")

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
  "columbia_modern_chinese_lit_2e_2007" => "https://www.loc.gov/catdir/toc/ecip0615/2006019770.html",
  "e017_columbia_traditional_japanese_lit_2007" => "https://www.loc.gov/catdir/toc/ecip064/2005034052.html",
  "e017_columbia_early_modern_japanese_lit_2002" => "https://external.dandelon.com/download/attachments/dandelon/ids/CH001B27FFCAAB5C83CF8C1257AD900519E1E.pdf",
  "e014_cambridge_history_african_caribbean_lit_2000" => [
    "https://www.cambridge.org/core/books/the-cambridge-history-of-african-and-caribbean-literature/1B9F2963235BC68CB3CA5EA6D534AC60",
    "https://www.cambridge.org/core/books/cambridge-history-of-african-and-caribbean-literature/383D7F023CD01BFB6AF3F29A7CDD7EB7"
  ],
  "e013_cambridge_history_latin_american_lit_1996" => [
    "https://www.cambridge.org/core/books/cambridge-history-of-latin-american-literature/1D0620D18EE73E2E7AC936C958296389",
    "https://www.cambridge.org/core/books/cambridge-history-of-latin-american-literature/7BD96D692CE735A7F0F92C1E91E3310A",
    "https://www.cambridge.org/core/books/cambridge-history-of-latin-american-literature/1CDA8EEB9673D751DBFA8A54EC3EAA07"
  ],
  "chinese_text_project_premodern" => "https://ctext.org/pre-qin-and-han?if=en",
  "oxford_modern_indian_poetry_1998" => "https://india.oup.com/product/the-oxford-anthology-of-modern-indian-poetry-9780195639179/"
}.freeze

CITATIONS = {
  "columbia_modern_chinese_lit_2e_2007" => "Library of Congress public prepublication TOC for LCCN 2006019770",
  "e017_columbia_traditional_japanese_lit_2007" => "Library of Congress public prepublication TOC for LCCN 2005034052",
  "e017_columbia_early_modern_japanese_lit_2002" => "Dandelon public TOC PDF for Columbia University Press Early Modern Japanese Literature",
  "e014_cambridge_history_african_caribbean_lit_2000" => "Cambridge Core public chapter lists for The Cambridge History of African and Caribbean Literature, Vols. 1-2",
  "e013_cambridge_history_latin_american_lit_1996" => "Cambridge Core public chapter lists for The Cambridge History of Latin American Literature, Vols. 1-3",
  "chinese_text_project_premodern" => "Chinese Text Project public Pre-Qin and Han index",
  "oxford_modern_indian_poetry_1998" => "Oxford University Press India official product metadata for ISBN 9780195639179"
}.freeze

SOURCE_PREFIXES = {
  "columbia_modern_chinese_lit_2e_2007" => "e016_mcl2007",
  "e017_columbia_traditional_japanese_lit_2007" => "e017_tradjp_full",
  "e017_columbia_early_modern_japanese_lit_2002" => "e017_emjp_full",
  "e014_cambridge_history_african_caribbean_lit_2000" => "e014_chacl",
  "e013_cambridge_history_latin_american_lit_1996" => "e013_chlal",
  "chinese_text_project_premodern" => "e016_ctext"
}.freeze

EXPECTED_COUNTS = {
  "columbia_modern_chinese_lit_2e_2007" => 168,
  "e017_columbia_traditional_japanese_lit_2007" => 409,
  "e017_columbia_early_modern_japanese_lit_2002" => 282,
  "e014_cambridge_history_african_caribbean_lit_2000" => 40,
  "e013_cambridge_history_latin_american_lit_1996" => 52,
  "chinese_text_project_premodern" => 108
}.freeze

REPLACE_SOURCES = EXPECTED_COUNTS.keys.to_set

MATCH_OVERRIDES = {
  ["columbia_modern_chinese_lit_2e_2007", "Preface to the First Collection of Short Stories, Call to Arms"] => ["work_candidate_global_lit_call_to_arms_lu_xun", "loc_toc_selection_current_candidate", "0.96", "represented_by_selection"],
  ["columbia_modern_chinese_lit_2e_2007", "A Madman's Diary"] => ["work_candidate_global_lit_call_to_arms_lu_xun", "loc_toc_selection_current_candidate", "0.94", "represented_by_selection"],
  ["columbia_modern_chinese_lit_2e_2007", "Excerpts from Wild Grass"] => ["work_candidate_eastasia_lit_wild_grass", "loc_toc_selection_current_candidate", "0.94", "represented_by_selection"],

  ["e017_columbia_traditional_japanese_lit_2007", "Kojiki"] => ["work_candidate_mandatory_kojiki", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Kojiki (Record of Ancient Matters)"] => ["work_candidate_mandatory_kojiki", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Nihon shoki"] => ["work_candidate_nihon_shoki_mythic_books", "loc_toc_title_variant_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Nihon shoki (Chronicles of Japan)"] => ["work_candidate_nihon_shoki_mythic_books", "loc_toc_title_variant_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Man'yoshu"] => ["work_candidate_manyoshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Man'yoshu (Collection of Myriad Leaves)"] => ["work_candidate_manyoshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Record of Miraculous Events in Japan"] => ["work_candidate_eastasia_lit_nihon_ryoiki", "loc_toc_english_title_current_candidate", "0.93", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Kokinshu"] => ["work_candidate_kokinshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Kokinshu (Collection of Ancient and Modern Poems)"] => ["work_candidate_kokinshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tale of the Bamboo Cutter"] => ["work_candidate_tale_of_bamboo_cutter", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tales of Ise"] => ["work_candidate_global_lit_ise_monogatari", "loc_toc_english_title_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Tosa Diary"] => ["work_candidate_scale_lit_tosa_diary", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Kagero Diary"] => ["work_candidate_scale_lit_kagero_diary", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Pillow Book"] => ["work_canon_pillow_book_sei_shonagon", "loc_toc_title_current_path", "0.99", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tale of Genji"] => ["work_canon_tale_of_genji", "loc_toc_title_current_path", "0.99", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Sarashina Diary"] => ["work_candidate_scale_lit_sarashina_diary", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Collection of Tales of Times Now Past"] => ["work_candidate_eastasia_lit_konjaku_monogatari", "loc_toc_english_title_current_candidate", "0.94", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Shinkokinshu"] => ["work_candidate_eastasia_lit_shinkokinshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Shinkokinshu (New Collection of Ancient and Modern Poems)"] => ["work_candidate_eastasia_lit_shinkokinshu", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "An Account of a Ten-Foot-Square Hut"] => ["work_candidate_hojoki", "loc_toc_english_title_current_candidate", "0.95", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "The Tales of the Heike"] => ["work_candidate_tale_of_heike", "loc_toc_title_variant_current_candidate", "0.97", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Essays in Idleness"] => ["work_candidate_tsurezuregusa", "loc_toc_title_variant_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Taiheiki"] => ["work_candidate_eastasia_lit_taiheiki", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Taiheiki (Chronicle of Great Peace)"] => ["work_candidate_eastasia_lit_taiheiki", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Sumida River"] => ["work_candidate_scale_lit_sumida_river", "loc_toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_traditional_japanese_lit_2007", "Teachings on Style and the Flower"] => ["work_candidate_wave005_fushikaden", "loc_toc_english_title_current_candidate", "0.90", "represented_by_selection"],

  ["e017_columbia_early_modern_japanese_lit_2002", "Five Sensuous Women"] => ["work_candidate_eastasia_lit_five_women_loved_love", "toc_title_variant_current_candidate", "0.92", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Five Sensuous Women (Koshoku gonin onna)"] => ["work_candidate_eastasia_lit_five_women_loved_love", "toc_title_variant_current_candidate", "0.92", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Life of a Sensuous Woman"] => ["work_candidate_global_lit_life_amorous_woman", "toc_title_variant_current_candidate", "0.92", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Life of a Sensuous Woman (Koshoku ichidai onna)"] => ["work_candidate_global_lit_life_amorous_woman", "toc_title_variant_current_candidate", "0.92", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Hokku"] => ["work_candidate_global_lit_basho_haiku", "toc_genre_author_current_candidate", "0.88", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Narrow Road to the Deep North"] => ["work_candidate_narrow_road_deep_north", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Narrow Road to the Deep North (Oku no hosomichi)"] => ["work_candidate_narrow_road_deep_north", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Love Suicides at Sonezaki"] => ["work_candidate_sonezaki_shinju_bunraku", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Love Suicides at Sonezaki (Sonezaki shinju)"] => ["work_candidate_sonezaki_shinju_bunraku", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Battles of Coxinga"] => ["work_candidate_mandatory_battles_coxinga", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Battles of Coxinga (Kokusenya kassen)"] => ["work_candidate_mandatory_battles_coxinga", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Love Suicides at Amijima"] => ["work_candidate_eastasia_lit_love_suicides_amijima", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Love Suicides at Amijima (Shinju ten no Amijima)"] => ["work_candidate_eastasia_lit_love_suicides_amijima", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Chushingura"] => ["work_candidate_global_lit_chushingura", "toc_title_current_candidate", "0.98", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Chushingura: The Storehouse of Loyal Retainers (Kanadehon Chushingura)"] => ["work_candidate_global_lit_chushingura", "toc_title_variant_current_candidate", "0.96", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Tales of Moonlight and Rain"] => ["work_candidate_global_lit_ugetsu_monogatari", "toc_english_title_current_candidate", "0.93", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "Tales of Moonlight and Rain (Ugetsu monogatari)"] => ["work_candidate_global_lit_ugetsu_monogatari", "toc_english_title_current_candidate", "0.93", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Eight Dog Chronicles"] => ["work_candidate_mandatory_hakkenden", "toc_english_title_current_candidate", "0.93", "represented_by_selection"],
  ["e017_columbia_early_modern_japanese_lit_2002", "The Eight Dog Chronicles (Nanso Satomi hakkenden)"] => ["work_candidate_mandatory_hakkenden", "toc_english_title_current_candidate", "0.93", "represented_by_selection"],

  ["chinese_text_project_premodern", "The Analects"] => ["work_canon_analects", "ctext_public_index_title_current_path", "0.98", "matched_current_path"],
  ["chinese_text_project_premodern", "Mengzi"] => ["work_candidate_mandatory_mencius", "ctext_public_index_title_variant_current_path", "0.96", "matched_current_path"],
  ["chinese_text_project_premodern", "Zhuangzi"] => ["work_canon_zhuangzi", "ctext_public_index_title_current_path", "0.98", "matched_current_path"],
  ["chinese_text_project_premodern", "Dao De Jing"] => ["work_canon_dao_de_jing", "ctext_public_index_title_current_path", "0.98", "matched_current_path"],
  ["chinese_text_project_premodern", "Book of Poetry"] => ["work_candidate_book_of_songs", "ctext_public_index_title_variant_current_path", "0.94", "matched_current_path"],
  ["chinese_text_project_premodern", "Chu Ci"] => ["work_candidate_chu_ci", "ctext_public_index_title_current_path", "0.96", "matched_current_path"],
  ["chinese_text_project_premodern", "Shan Hai Jing"] => ["work_candidate_mandatory_shanhaijing", "ctext_public_index_title_variant_current_path", "0.94", "matched_current_path"],
  ["chinese_text_project_premodern", "Shiji"] => ["work_candidate_shiji", "ctext_public_index_title_variant_current_path", "0.94", "matched_current_path"],
  ["chinese_text_project_premodern", "Chun Qiu Zuo Zhuan"] => ["work_candidate_mandatory_zuo_zhuan", "ctext_public_index_title_variant_current_path", "0.92", "matched_current_path"],
  ["chinese_text_project_premodern", "Xunzi"] => ["work_candidate_wave005_xunzi", "ctext_public_index_title_current_path", "0.98", "matched_current_path"],
  ["chinese_text_project_premodern", "Romance of the Three Kingdoms"] => ["work_candidate_romance_three_kingdoms", "ctext_public_index_title_current_path", "0.98", "matched_current_path"],
  ["chinese_text_project_premodern", "Hong Lou Meng"] => ["work_canon_dream_of_the_red_chamber", "ctext_public_index_title_variant_current_path", "0.94", "matched_current_path"],
  ["chinese_text_project_premodern", "The Scholars"] => ["work_candidate_scholars_wu_jingzi", "ctext_public_index_title_current_path", "0.98", "matched_current_path"]
}.freeze

def fetch(url)
  output, status = Open3.capture2e(
    "curl", "-L", "--silent", "--show-error", "--max-time", "60",
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

    output.lines.reject { |line| line.start_with?("Syntax Warning") }.join
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
  CGI.unescapeHTML(value.to_s)
     .gsub(/(?<=\d)\u00bf(?=\d)/, "-")
     .gsub("\u00bf", "'")
     .gsub("\u00a0", " ")
     .gsub(/[“”]/, '"')
     .gsub(/[‘’]/, "'")
     .gsub(/[–—−]/, "-")
     .gsub("Early Modem", "Early Modern")
     .gsub(/\blhara\b/, "Ihara")
     .gsub(/\bjapan's\b/, "Japan's")
     .gsub("]oumal", "Journal")
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
  slug = stable_id([creator, title].reject(&:empty?).join(" "))[0, 80]
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

  override = MATCH_OVERRIDES[[source_id, title]]
  if override
    row["matched_work_id"], row["match_method"], row["match_confidence"], row["match_status"] = override
  end

  row
end

def append_packet(packet_ids, packet_id)
  ids = packet_ids.to_s.split(";").map(&:strip).reject(&:empty?)
  ids << packet_id unless ids.include?(packet_id)
  ids.join(";")
end

def extract_loc_modern_chinese
  html = fetch(URLS.fetch("columbia_modern_chinese_lit_2e_2007"))
  lines = Nokogiri::HTML(html).at_css("pre").text.lines.map { |line| clean(line) }.reject(&:empty?)
  current_section = nil
  current_creator = nil
  rows = []
  section_re = /\A(ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE):\s*(.+?)\s+0+\z/
  skip = /\A(Table of Contents|Preface to the Second Edition|Acknowledgments|Introduction|Biographical Sketches|Permissions|Index)\b/i

  lines.each do |line|
    if (match = line.match(section_re))
      current_section = match[2]
      current_creator = nil
      next
    end

    line = line.sub(/\s+0+\z/, "")
    next if line.match?(skip)

    if line == line.upcase && line.match?(/[A-Z]/) && !line.match?(/[0-9]/) && line.split.size <= 6
      current_creator = line.split.map { |part| part[0] + part[1..].to_s.downcase }.join(" ")
      next
    end

    next if current_section.nil? || current_creator.nil?

    rows << [current_section, current_creator, line]
  end

  rows.map.with_index(1) do |(section, creator, title), index|
    item(
      source_id: "columbia_modern_chinese_lit_2e_2007",
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: section,
      evidence_type: "representative_selection",
      evidence_weight: "0.60",
      supports: "field_anthology_public_toc",
      notes: "LOC prepublication line-level TOC row; selection/excerpt evidence, not whole-work proof."
    )
  end
end

def merge_wrapped_loc_lines(lines)
  section_re = /\A\d+\. /
  join_end = /\b(the|a|an|of|for|to|in|with|and|or|by|as|all|is|no|from|at|on|kill|collecting|saved|given|appears|age)\z/i
  merged = []

  lines.each do |line|
    previous = merged[-1]
    if previous && !line.match?(section_re) && !previous.match?(section_re) &&
       previous.length < 130 && (previous.match?(join_end) || line.match?(/\A[a-z]/))
      merged[-1] = "#{previous} #{line}"
    else
      merged << line
    end
  end

  merged
end

def extract_loc_traditional_japanese
  html = fetch(URLS.fetch("e017_columbia_traditional_japanese_lit_2007"))
  raw_lines = Nokogiri::HTML(html).at_css("pre").text.lines.map { |line| clean(line) }.reject(&:empty?)
  lines = merge_wrapped_loc_lines(raw_lines)
  section = nil
  started = false
  rows = []
  section_re = /\A\d+\. /
  skip_re = /\A(Contents|Acknowledgments|Introduction|Preface|English-Language Bibliography|Index|Historical Periods|Language and Writing|Power and Courtship|Loss and Integration|Love and Eroticism|Sociality|Condensation and Intertextuality|Attachment and Detachment|Performance and Narration|Accretionary Genres|Japanese Literature and National Identity|Structure of This Anthology|The Cultural Topography|The Tomb Period|The Asuka Period|The Nara Period|The Beginnings|The Emergence|The Rise|Late Heian|First Period|Second Period|Third Period|Fourth Period|Book \d+\z|Part [IVX]+\z|Act \d+\z|Section \d+:|Book \d+:|Poems\z|Spring\z|Summer\z|Autumn\z|Winter\z|Love\z|Miscellaneous\z|Hokku\z|Songs\z)/

  lines.each do |line|
    if line.match?(section_re)
      section = line
      started = true
      next
    end

    break if line.match?(/\AEnglish-Language Bibliography|\AIndex\z/)
    next unless started
    next if line.match?(skip_re)

    rows << [section, line]
  end

  rows.map.with_index(1) do |(source_section, title), index|
    item(
      source_id: "e017_columbia_traditional_japanese_lit_2007",
      raw_title: title,
      source_rank: index,
      source_section: source_section,
      evidence_type: "representative_selection",
      evidence_weight: "0.45",
      supports: "field_anthology_public_toc_line",
      notes: "LOC prepublication line-level TOC row; generic subheadings remain boundary/context rows unless explicitly matched."
    )
  end
end

def extract_early_modern_japanese
  text = fetch_pdf_text(URLS.fetch("e017_columbia_early_modern_japanese_lit_2002"))
  lines = text.lines.map { |line| clean(line) }.reject(&:empty?).reject { |line| line.start_with?("Syntax Warning") }
  start = lines.index("CONTENTS") || lines.index("Contents")
  raise "early modern Japanese contents start not found" unless start

  section = nil
  pending = nil
  rows = []

  lines[(start + 1)..].each do |line|
    next if line.match?(/\A[ivxlcdm]+ CONTENTS\z/i) || line.match?(/\bCONTENTS\b/i)

    unless line.match?(/\s+\d+\z/)
      next if line.match?(/\A(COLUMBIA|NEW YORK|\\)\z/i)

      pending = [pending, line].compact.join(" ")
      next
    end

    title = line.sub(/\s+\d+\z/, "").strip
    title = [pending, title].compact.join(" ")
    pending = nil
    break if title.match?(/\A(English-Language Bibliography|Index|Bibliography|Translators' Notes)\b/i)
    next if title.match?(/\A(Preface|Historical Periods|A Note on|Glossary)\b/i)

    if title.match?(/\A\d+\.\s+/)
      section = title
      next
    end

    next if section.nil? || section.start_with?("1. Early Modern Japan")

    rows << [section, title]
  end

  rows.map.with_index(1) do |(source_section, title), index|
    item(
      source_id: "e017_columbia_early_modern_japanese_lit_2002",
      raw_title: title,
      source_rank: index,
      source_section: source_section,
      evidence_type: "representative_selection",
      evidence_weight: "0.45",
      supports: "field_anthology_public_toc_line",
      notes: "Dandelon line-level TOC row; generic subheadings remain boundary/context rows unless explicitly matched."
    )
  end
end

def parse_cambridge_part_row(text)
  cleaned = clean(text)
  return nil if cleaned.match?(/\A(Frontmatter|Index|Bibliograph)/i)

  match = cleaned.match(/\A(?:(\d+)\s+-\s+)?(.+?)\s+pp\s+(.+)\z/i)
  raise "unexpected Cambridge row: #{cleaned}" unless match

  rank, title, pages = match.captures
  return nil unless rank

  [rank, title, pages]
end

def extract_cambridge(source_id)
  URLS.fetch(source_id).flat_map.with_index(1) do |url, volume|
    html = fetch(url)
    Nokogiri::HTML(html).css("a.part-link").map { |link| parse_cambridge_part_row(link.text) }.compact.map do |rank, title, pages|
      item(
        source_id: source_id,
        raw_title: title,
        source_rank: rank,
        source_section: "Volume #{volume}; pp. #{pages}",
        source_url: url,
        evidence_type: "boundary_context",
        evidence_weight: "0.30",
        supports: "literary_history_chapter_context",
        notes: "Cambridge Core chapter row; context evidence, not anthology inclusion."
      )
    end
  end
end

def extract_ctext_index
  html = fetch(URLS.fetch("chinese_text_project_premodern"))
  doc = Nokogiri::HTML(html)
  menu = doc.at_css("#menu")
  raise "Chinese Text Project menu not found" unless menu

  category_hrefs = {
    "confucianism" => "Confucianism",
    "mohism" => "Mohism",
    "daoism" => "Daoism",
    "legalism" => "Legalism",
    "school-of-names" => "School of Names",
    "school-of-the-military" => "School of the Military",
    "mathematics" => "Mathematics",
    "miscellaneous-schools" => "Miscellaneous Schools",
    "histories" => "Histories",
    "ancient-classics" => "Ancient Classics",
    "etymology" => "Etymology",
    "chinese-medicine" => "Chinese Medicine",
    "excavated-texts" => "Excavated texts",
    "wei-jin-and-north-south" => "Wei, Jin, and North-South",
    "sui-tang" => "Sui-Tang",
    "song-ming" => "Song-Ming",
    "qing" => "Qing",
    "republican-era" => "Republican era"
  }
  skip_hrefs = %w[
    introduction font-test-page help-us faq instructions tools system-statistics digital-humanities
    pre-qin-and-han post-han
  ].to_set
  current_section = nil
  rows = []

  menu.css("a.etext[href]").each do |link|
    href = link["href"].to_s
    title = clean(link.text)
    next if title.empty? || href.start_with?("#") || href.match?(/\A(https?:)?\/\//)

    if category_hrefs.key?(href)
      current_section = category_hrefs.fetch(href)
      next
    end
    next if skip_hrefs.include?(href)

    rows << [current_section || "Chinese Text Project", title, href]
  end

  rows.uniq.map.with_index(1) do |(source_section, title, href), index|
    item(
      source_id: "chinese_text_project_premodern",
      raw_title: title,
      source_rank: index,
      source_section: source_section,
      source_url: "https://ctext.org/#{href}",
      evidence_type: "boundary_context",
      evidence_weight: "0.15",
      supports: "digital_text_public_index_metadata",
      notes: "Chinese Text Project index row; access/title-boundary metadata only, not standalone canon-selection evidence."
    )
  end
end

rows = []
rows.concat(extract_loc_modern_chinese)
rows.concat(extract_loc_traditional_japanese)
rows.concat(extract_early_modern_japanese)
rows.concat(extract_cambridge("e014_cambridge_history_african_caribbean_lit_2000"))
rows.concat(extract_cambridge("e013_cambridge_history_latin_american_lit_1996"))
rows.concat(extract_ctext_index)

counts = rows.group_by { |row| row["source_id"] }.transform_values(&:size)
EXPECTED_COUNTS.each do |source_id, expected|
  actual = counts.fetch(source_id, 0)
  raise "unexpected #{source_id} row count: expected #{expected}, got #{actual}" unless actual == expected
end

work_ids = read_tsv(WORK_CANDIDATES_FILE).map { |row| row["work_id"] }.to_set
bad_matches = rows.reject { |row| row["matched_work_id"].to_s.empty? || work_ids.include?(row["matched_work_id"]) }
unless bad_matches.empty?
  details = bad_matches.map { |row| "#{row["source_item_id"]}:#{row["matched_work_id"]}" }.join(", ")
  raise "unknown matched_work_id values: #{details}"
end

source_item_rows = read_tsv(SOURCE_ITEMS_FILE)
existing_by_title_creator = {}
source_item_rows.each do |row|
  next unless REPLACE_SOURCES.include?(row["source_id"])
  next if row["matched_work_id"].to_s.empty?

  existing_by_title_creator[[row["source_id"], clean(row["raw_title"]), clean(row["raw_creator"])]] = row
end
rows.each do |row|
  next unless row["matched_work_id"].to_s.empty?

  existing = existing_by_title_creator[[row["source_id"], row["raw_title"], row["raw_creator"]]]
  next unless existing

  %w[matched_work_id match_method match_confidence match_status].each do |field|
    row[field] = existing[field].to_s
  end
end

remaining_rows = source_item_rows.reject { |row| REPLACE_SOURCES.include?(row["source_id"]) }
source_items_by_id = remaining_rows.to_h { |row| [row["source_item_id"], row] }
rows.each do |row|
  raise "duplicate generated source_item_id: #{row["source_item_id"]}" if source_items_by_id.key?(row["source_item_id"])

  source_items_by_id[row["source_item_id"]] = row
end
write_tsv(SOURCE_ITEMS_FILE, SOURCE_ITEM_HEADERS, source_items_by_id.values, sort_key: "source_item_id")

registry_rows = read_tsv(SOURCE_REGISTRY_FILE)
registry_by_id = registry_rows.to_h { |row| [row["source_id"], row] }
registry_updates = {
  "columbia_modern_chinese_lit_2e_2007" => ["extracted", "LOC public prepublication TOC parsed into 168 line-level rows; count supersedes the earlier 14-row pilot and older 166-item estimate."],
  "e017_columbia_traditional_japanese_lit_2007" => ["extracted", "LOC public prepublication TOC parsed into 409 line-level rows; generic subheadings are retained as source rows but only explicit matches count downstream."],
  "e017_columbia_early_modern_japanese_lit_2002" => ["extracted", "Dandelon public TOC PDF parsed into 282 line-level rows after excluding chapter 1 editorial historical context."],
  "e014_cambridge_history_african_caribbean_lit_2000" => ["context_only", "Cambridge Core chapter lists parsed into 40 chapter-context rows across Vols. 1-2."],
  "e013_cambridge_history_latin_american_lit_1996" => ["context_only", "Cambridge Core chapter lists parsed into 52 chapter-context rows across Vols. 1-3."],
  "chinese_text_project_premodern" => ["metadata_ready", "Chinese Text Project public Pre-Qin/Han index parsed into 108 title/access metadata rows; rows are not canon-selection evidence."],
  "columbia_traditional_chinese_lit_1996" => ["in_progress", "CPL public TOC remains blocked to automated extraction; search snippets are insufficient for reliable line-level ingestion, so the earlier 22-row pilot is retained pending alternate access or physical copy."],
  "oxford_modern_indian_poetry_1998" => ["in_progress", "OUP India official metadata confirms 125 poets in 14 Indian languages and thematic organization; it does not expose poem-level TOC, so Book Excerptise rows remain pending official-copy reconciliation."]
}
registry_updates.each do |source_id, (status, notes)|
  raise "missing registry row for #{source_id}" unless registry_by_id[source_id]

  registry_by_id[source_id]["extraction_status"] = status
  registry_by_id[source_id]["packet_ids"] = append_packet(registry_by_id[source_id]["packet_ids"], "X024")
  registry_by_id[source_id]["notes"] = notes
end
write_tsv(SOURCE_REGISTRY_FILE, SOURCE_REGISTRY_HEADERS, registry_by_id.values, sort_key: "source_id")

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row["packet_id"] == "X024" }
packet_rows << {
  "packet_id" => "X024",
  "packet_family" => "X",
  "scope" => "full-line Chinese/Japanese TOCs plus Cambridge context and CText metadata cleanup",
  "status" => "source_items_ingested",
  "gate" => "matching_required",
  "output_artifact" => "_planning/canon_build/tables/canon_source_items.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_008_x024_full_toc_context_cleanup.md",
  "next_action" => "run_matching_relation_scope_evidence_then_continue_unresolved_traditional_chinese_and_official_indian_poetry_checks",
  "notes" => "Expanded X024 parseable public sources into 1,059 generated rows; left CPL Traditional Chinese and Oxford Indian poem-level official copy debt explicit."
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows, sort_key: "packet_id")

FileUtils.mkdir_p(REPORT_DIR)
report = []
report << "# X024 Full-Line TOC and Context Cleanup"
report << ""
report << "- status: source_items_ingested_matching_required"
report << "- generated_rows: #{rows.size}"
report << "- replaced_sources: #{REPLACE_SOURCES.size}"
report << "- direct_public_path_changes: 0"
report << "- direct_evidence_rows_added_by_ingester: 0"
report << ""
report << "## Source Counts"
report << ""
report << "| Source ID | Rows | Status After X024 | Notes |"
report << "|---|---:|---|---|"
EXPECTED_COUNTS.keys.sort.each do |source_id|
  registry = registry_by_id.fetch(source_id)
  report << "| `#{source_id}` | #{counts.fetch(source_id)} | #{registry["extraction_status"]} | #{registry["notes"]} |"
end
report << "| `columbia_traditional_chinese_lit_1996` | 22 retained | #{registry_by_id.fetch("columbia_traditional_chinese_lit_1996")["extraction_status"]} | #{registry_by_id.fetch("columbia_traditional_chinese_lit_1996")["notes"]} |"
report << "| `oxford_modern_indian_poetry_1998` | 124 retained | #{registry_by_id.fetch("oxford_modern_indian_poetry_1998")["extraction_status"]} | #{registry_by_id.fetch("oxford_modern_indian_poetry_1998")["notes"]} |"
report << ""
report << "## Parser Boundaries"
report << ""
report << "- LOC modern Chinese rows are line-level title rows under author headings. The source page is prepublication metadata, so rows are selection/excerpt evidence, not whole-work proof."
report << "- LOC traditional Japanese rows preserve line-level contents after merging obvious wrapped lines and removing front/back matter. Generic subheadings are retained so later review can distinguish author headings, nested works, and excerpts."
report << "- Dandelon early modern Japanese rows are page-bearing TOC rows after chapter 1 editorial history is excluded. Wrapped Chushingura-style titles are merged before ingestion."
report << "- Cambridge rows are chapter-context rows only. They help map regional literary-history coverage and gaps, but they are not anthology inclusion evidence."
report << "- Chinese Text Project rows are public index/access metadata only; the site explicitly functions as a text database, not a canon list."
report << "- Traditional Chinese remains a real open gap: the CPL line-level TOC is blocked to automated access, and search snippets are not reliable enough for ingestion."
report << "- Oxford modern Indian poetry remains an official-copy gap at poem level: OUP confirms anthology scope and denominator, but not the line-level poem list."
report << ""
report << "## Source URLs"
report << ""
[
  URLS.fetch("columbia_modern_chinese_lit_2e_2007"),
  URLS.fetch("e017_columbia_traditional_japanese_lit_2007"),
  URLS.fetch("e017_columbia_early_modern_japanese_lit_2002"),
  *URLS.fetch("e014_cambridge_history_african_caribbean_lit_2000"),
  *URLS.fetch("e013_cambridge_history_latin_american_lit_1996"),
  URLS.fetch("chinese_text_project_premodern"),
  URLS.fetch("oxford_modern_indian_poetry_1998")
].each { |url| report << "- #{url}" }
report << ""
File.write(REPORT_FILE, report.join("\n"))

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x024_full_toc_context_cleanup_ingested"
manifest["artifacts"]["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_source_items"
manifest["source_item_extraction_batch_x024"] = {
  "source_items_added_or_updated" => rows.size,
  "sources_replaced_or_expanded" => REPLACE_SOURCES.size,
  "modern_chinese_line_rows" => counts.fetch("columbia_modern_chinese_lit_2e_2007"),
  "traditional_japanese_line_rows" => counts.fetch("e017_columbia_traditional_japanese_lit_2007"),
  "early_modern_japanese_line_rows" => counts.fetch("e017_columbia_early_modern_japanese_lit_2002"),
  "cambridge_african_caribbean_context_rows" => counts.fetch("e014_cambridge_history_african_caribbean_lit_2000"),
  "cambridge_latin_american_context_rows" => counts.fetch("e013_cambridge_history_latin_american_lit_1996"),
  "ctext_metadata_rows" => counts.fetch("chinese_text_project_premodern"),
  "evidence_rows_added" => 0,
  "status" => "source_items_ingested_matching_required",
  "direct_replacements" => 0
}
manifest["current_counts"] ||= {}
manifest["current_counts"]["source_items"] = source_items_by_id.size
manifest["current_counts"]["source_registry_rows"] = registry_by_id.size
File.write(MANIFEST_FILE, manifest.to_yaml)

if File.file?(EXTRACTION_PLAN_FILE)
  plan = File.read(EXTRACTION_PLAN_FILE)
  plan = plan.sub(
    /Registered; X020-X023 generated\/updated 1,354 E013\/E014\/E015\/E016\/E017\/E018 source-item observations; current table has 1,422 total source-item rows; X013\/X014\/X017 queues rerun; deeper full-line TOC extraction remains pending for selected Chinese\/Japanese\/context sources/,
    "Registered; X020-X024 generated/updated 2,413 E013/E014/E015/E016/E017/E018 source-item observations; current table has #{source_items_by_id.size} total source-item rows; X013/X014/X017 queues rerun after X024; remaining source debt is explicit for blocked Traditional Chinese CPL TOC and official Oxford modern Indian poem-level reconciliation"
  )
  plan = plan.sub(
    /\| X024 \| Full-line TOC and context cleanup \| Continue E013-E018 cleanup where X023 deliberately stopped: full line-level Chinese and Japanese TOCs, Cambridge African\/Caribbean and Latin American chapter-context rows, Chinese Text Project metadata boundaries, and official-copy reconciliation for Oxford modern Indian poetry \|/,
    "| X024 | Full-line TOC and context cleanup | Source items ingested; 1,059 generated rows from LOC Modern Chinese, LOC/Dandelon Japanese, Cambridge African/Caribbean and Latin American chapter-context rows, and Chinese Text Project metadata; Traditional Chinese CPL and Oxford modern Indian poem-level official-copy debt retained explicitly |"
  )
  File.write(EXTRACTION_PLAN_FILE, plan)
end

puts "ingested or updated #{rows.size} X024 full-TOC/context rows"
puts counts.sort.map { |source_id, count| "#{source_id}=#{count}" }.join("\n")
