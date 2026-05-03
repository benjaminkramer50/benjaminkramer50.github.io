#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "csv"
require "fileutils"
require "nokogiri"
require "open3"
require "set"
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
REPORT_FILE = File.join(REPORT_DIR, "x_batch_006_x022_public_toc_source_items.md")

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

FETCHED_URLS = {
  fsg_latin_poetry: "https://boulder.marmot.org/Record/.b18763960",
  oxford_latin_poetry: "https://find.uoc.ac.in/Record/308884/TOC",
  rienner_african_lit: "https://www.rienner.com/title/The_Rienner_Anthology_of_African_Literature",
  oxford_indian_poetry: "https://cse.iitk.ac.in/users/amit/books/dharwadker-1994-oxford-anthology-of.html",
  clay_sanskrit: "https://claysanskritlibrary.org/volumes/volumes-list/",
  murty_books: "https://www.murtylibrary.com/books",
  japanese_v2: "https://www.kriso.ee/columbia-anthology-modern-japanese-literature-volume-db-9780231138048.html",
  lti_korea_classics: "https://www.ltikorea.or.kr/api/board.do?bcfId=classics"
}.freeze

SOURCE_URLS = {
  "e013_fsg_20c_latin_american_poetry_2011" => "https://boulder.marmot.org/Record/.b18763960",
  "e013_oxford_latin_american_poetry_2009" => "https://find.uoc.ac.in/Record/308884/TOC",
  "e014_rienner_anthology_african_lit_2007" => "https://www.rienner.com/title/The_Rienner_Anthology_of_African_Literature",
  "oxford_modern_indian_poetry_1998" => "https://cse.iitk.ac.in/users/amit/books/dharwadker-1994-oxford-anthology-of.html",
  "clay_sanskrit_library_56vol" => "https://claysanskritlibrary.org/volumes/volumes-list/",
  "murty_classical_library_india" => "https://www.murtylibrary.com/books",
  "e017_columbia_modern_japanese_lit_v2_2007" => "https://www.kriso.ee/columbia-anthology-modern-japanese-literature-volume-db-9780231138048.html",
  "e018_lti_korea_digital_library_classics" => "https://www.ltikorea.or.kr/api/board.do?bcfId=classics",
  "e018_columbia_traditional_korean_poetry_2003" => "https://cup.columbia.edu/book/the-columbia-anthology-of-traditional-korean-poetry/9780231111133/"
}.freeze

SOURCE_CITATIONS = {
  "e013_fsg_20c_latin_american_poetry_2011" => "Boulder Public Library MARC 505 public contents; Macmillan/FSG bibliographic metadata",
  "e013_oxford_latin_american_poetry_2009" => "University of Calicut public TOC; Google Books/OUP bibliographic metadata",
  "e014_rienner_anthology_african_lit_2007" => "Lynne Rienner official public contents",
  "oxford_modern_indian_poetry_1998" => "Book Excerptise public thematic TOC; OUP/NLA bibliographic metadata cross-check",
  "clay_sanskrit_library_56vol" => "Clay Sanskrit Library official public volumes list",
  "murty_classical_library_india" => "Murty Classical Library of India public Books page",
  "e017_columbia_modern_japanese_lit_v2_2007" => "Kriso public product Table of Contents for ISBN 9780231138048",
  "e018_lti_korea_digital_library_classics" => "LTI Korea Classic Sourcebook public OpenAPI",
  "e018_columbia_traditional_korean_poetry_2003" => "Columbia University Press official contents; De Gruyter/Columbia ebook TOC"
}.freeze

SOURCE_PREFIXES = {
  "e013_fsg_20c_latin_american_poetry_2011" => "e013_fsg20c",
  "e013_oxford_latin_american_poetry_2009" => "e013_oblap",
  "e014_rienner_anthology_african_lit_2007" => "e014_rienner",
  "oxford_modern_indian_poetry_1998" => "e015_omip1998",
  "clay_sanskrit_library_56vol" => "e015_clay",
  "murty_classical_library_india" => "e015_murty",
  "e017_columbia_modern_japanese_lit_v2_2007" => "e017_modjp_v2",
  "e018_lti_korea_digital_library_classics" => "e018_lti_classics",
  "e018_columbia_traditional_korean_poetry_2003" => "e018_ctkp2003"
}.freeze

EXPECTED_COUNTS = {
  "e013_fsg_20c_latin_american_poetry_2011" => 84,
  "e013_oxford_latin_american_poetry_2009" => 137,
  "e014_rienner_anthology_african_lit_2007" => 146,
  "oxford_modern_indian_poetry_1998" => 124,
  "clay_sanskrit_library_56vol" => 56,
  "murty_classical_library_india" => 19,
  "e017_columbia_modern_japanese_lit_v2_2007" => 96,
  "e018_lti_korea_digital_library_classics" => 26,
  "e018_columbia_traditional_korean_poetry_2003" => 9
}.freeze

REPLACE_SOURCES = EXPECTED_COUNTS.keys.to_set

MATCH_OVERRIDES = {
  ["e013_oxford_latin_american_poetry_2009", "Popol Vuh (excerpt)"] => ["work_canon_popol_vuh", "title_excerpt_current_path", "0.97", "represented_by_selection"],
  ["e013_oxford_latin_american_poetry_2009", "The Araucaniad (excerpt)"] => ["work_candidate_global_lit_la_araucana", "english_title_variant_excerpt_creator", "0.94", "represented_by_selection"],
  ["e013_oxford_latin_american_poetry_2009", "Martin Fierro (excerpt)"] => ["work_candidate_martin_fierro", "title_excerpt_current_candidate", "0.96", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "The Epic of Sundiata"] => ["work_candidate_sunjata_epic", "sundiata_sunjata_title_variant", "0.93", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "The Palm-Wine Drinkard"] => ["work_candidate_palm_wine_drinkard", "title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_rienner_anthology_african_lit_2007", "Chaka (Chapters 3-4)"] => ["work_candidate_chaka_mofolo", "title_creator_excerpt_current_candidate", "0.97", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "Things Fall Apart (Chapters 3-4)"] => ["work_canon_things_fall_apart", "title_creator_excerpt_current_path", "0.99", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "Efuru (Chapters 9-10)"] => ["work_candidate_africa_lit_efuru", "title_creator_excerpt_current_candidate", "0.98", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "Houseboy"] => ["work_candidate_global_lit_houseboy", "title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_rienner_anthology_african_lit_2007", "So Long a Letter (Chapters 1-8)"] => ["work_candidate_so_long_a_letter", "title_creator_excerpt_current_candidate", "0.98", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "Anowa (excerpt from Phase 1)"] => ["work_candidate_mandatory_anowa", "title_creator_excerpt_current_candidate", "0.98", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "Song of Lawino"] => ["work_candidate_global_lit_songs_lawino", "title_creator_current_candidate", "0.98", "matched_current_path"],
  ["e014_rienner_anthology_african_lit_2007", "I Will Marry When I Want (Act I)"] => ["work_candidate_africa_lit_i_will_marry", "title_creator_excerpt_current_candidate", "0.97", "represented_by_selection"],
  ["e014_rienner_anthology_african_lit_2007", "Nervous Conditions (Chapter 4)"] => ["work_candidate_nervous_conditions", "title_creator_excerpt_current_candidate", "0.98", "represented_by_selection"],
  ["e018_lti_korea_digital_library_classics", "The Cloud Dream of the Nine, A Korean Novel"] => ["work_candidate_cloud_dream_nine", "api_title_variant_current_candidate", "0.88", "matched_current_path"],
  ["e018_lti_korea_digital_library_classics", "Chunhyangjeon / Printemps Parfume"] => ["work_candidate_chunhyangjeon", "api_korean_title_current_candidate", "0.88", "matched_current_path"],
  ["e018_lti_korea_digital_library_classics", "Simcheongjeon / Le Bois sec Refleuri"] => ["work_candidate_scale_lit_tale_sim_cheong", "api_korean_title_current_candidate", "0.88", "matched_current_path"],
  ["e018_columbia_traditional_korean_poetry_2003", "Songs of Flying Dragons"] => ["work_candidate_global_lit_songs_flying_dragons", "title_exact_chapter_current_candidate", "0.97", "matched_current_path"]
}.freeze

KOREAN_POETRY_SECTIONS = [
  ["Hyangga", "Korean hyangga tradition", "Silla period", "1.1", "Part 1: Classical Poetry", "Publisher public contents expose a section heading only; no poem-level titles or authors visible."],
  ["Koryo Songs", "Koryo song tradition", "Koryo period", "1.2", "Part 1: Classical Poetry", "Publisher public contents expose a section heading only; no song-level titles visible."],
  ["Songs of Flying Dragons", "Early Joseon court poetic tradition", "1445-1447", "1.3", "Part 1: Classical Poetry", "Named chapter/section in public TOC; supports an assigned selection/chapter, not poem-by-poem extraction."],
  ["Sijo", "Korean sijo tradition", "traditional", "1.4", "Part 1: Classical Poetry", "Generic genre heading only; no source-visible item-level work support."],
  ["Sasol Sijo", "Korean sasol sijo tradition", "traditional", "1.5", "Part 1: Classical Poetry", "Generic genre heading only; no source-visible item-level work support."],
  ["Kasa", "Korean kasa tradition", "traditional", "1.6", "Part 1: Classical Poetry", "Generic genre heading only; no source-visible item-level work support."],
  ["Poetry in Chinese", "Korean hansi tradition", "traditional", "2", "Part 2: Poetry in Chinese", "Section heading only; no public author or poem denominator from CUP contents."],
  ["Folk Songs", "Korean folk song tradition", "traditional", "3", "Part 3: Folk Songs", "Section heading only; no public item-level song denominator from CUP contents."],
  ["Shamanist Narrative Songs", "Korean shamanist narrative song tradition", "traditional", "4", "Part 4: Shamanist Narrative Songs", "Section heading only; no public item-level song denominator from CUP contents."]
].freeze

def fetch(url)
  output, status = Open3.capture2e(
    "curl", "-L", "--silent", "--show-error", "--max-time", "30",
    "-A", "Mozilla/5.0 canon-build-source-extraction", url
  )
  raise "fetch failed for #{url}: #{output}" unless status.success?

  output
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
       .gsub("…", "...")
       .then { |text| CGI.unescapeHTML(text) }
       .unicode_normalize(:nfkd)
       .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
       .gsub(/\s+/, " ")
       .strip
end

def stable_id(value)
  clean(value).downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
end

def source_item_id(source_id, rank, raw_title, raw_creator)
  rank_id = rank.to_s.gsub(/[^0-9a-zA-Z]+/, "_").gsub(/\A_+|_+\z/, "")
  rank_id = rank.to_i.to_s.rjust(3, "0") if rank.to_s.match?(/\A\d+\z/)
  slug = stable_id([raw_creator, raw_title].reject(&:empty?).join(" "))[0, 70]
  "#{SOURCE_PREFIXES.fetch(source_id)}_#{rank_id}_#{slug}"
end

def selection?(title)
  title.match?(/chapter|chapters|excerpt|act |acts |scene|scenes|\bfrom\b/i)
end

def item(source_id:, raw_title:, raw_creator: "", raw_date: "", source_rank:, source_section: "",
         evidence_type:, evidence_weight:, supports:, match_status: "unmatched", notes: "")
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
    "source_url" => SOURCE_URLS.fetch(source_id),
    "source_citation" => SOURCE_CITATIONS.fetch(source_id),
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

def extract_fsg_latin_poetry
  html = fetch(FETCHED_URLS.fetch(:fsg_latin_poetry))
  doc = Nokogiri::HTML(html)
  record = doc.at_css("#formattedMarcRecord")
  raise "FSG MARC record missing" unless record

  cell = record.css("tr").find { |tr| tr.css("th").map(&:text).include?("505") }&.css("td")&.last
  raise "FSG 505 contents missing" unless cell

  text = clean(cell.text)
  entries = text.scan(/\|t\s*(.*?)\s*\/\s*\|r\s*(.*?)(?=\s*--\s*\|t|\.\s*\z)/).map do |title, creator|
    [clean(title).sub(/\A\s*deVersos/, "de Versos"), clean(creator).sub(/\.\z/, "")]
  end

  entries.map.with_index(1) do |(title, creator), index|
    item(
      source_id: "e013_fsg_20c_latin_american_poetry_2011",
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: "MARC 505 contents",
      evidence_type: "representative_selection",
      evidence_weight: "0.60",
      supports: "poem_level_anthology_inclusion"
    )
  end
end

def extract_oxford_latin_poetry
  html = fetch(FETCHED_URLS.fetch(:oxford_latin_poetry))
  doc = Nokogiri::HTML(html)
  entries = doc.css("ul.toc li").map { |li| clean(li.text) }
  body = entries.drop_while { |entry| !entry.start_with?("Maya scribes") }
  body = body.take_while { |entry| !entry.start_with?("List of translators") && !entry.start_with?("Source acknowledgments") }

  body.map.with_index(1) do |entry, index|
    title, creator = entry.split(/\s+\/\s+/, 2)
    item(
      source_id: "e013_oxford_latin_american_poetry_2009",
      raw_title: title || entry,
      raw_creator: creator.to_s,
      source_rank: index,
      source_section: "Table of Contents",
      evidence_type: "representative_selection",
      evidence_weight: "0.55",
      supports: "poem_level_anthology_inclusion",
      notes: creator ? "" : "Public TOC line has no visible creator delimiter; retained as raw title-level row."
    )
  end
end

def extract_rienner
  html = fetch(FETCHED_URLS.fetch(:rienner_african_lit))
  doc = Nokogiri::HTML(html)
  lis = doc.css("#book_contents li")
  lis.map.with_index(1) do |li, index|
    raw = clean(li.text)
    if li.at_css("em") && raw.include?(",")
      creator, title = raw.split(/\s*,\s*/, 2)
    else
      creator = ""
      title = raw
    end
    item(
      source_id: "e014_rienner_anthology_african_lit_2007",
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: "Official contents",
      evidence_type: selection?(title) ? "representative_selection" : "inclusion",
      evidence_weight: "0.60",
      supports: "field_anthology_public_toc",
      notes: selection?(title) ? "Title visibly marks chapter, act, scene, or excerpt scope; does not prove whole-work inclusion." : ""
    )
  end
end

def extract_indian_poetry
  html = fetch(FETCHED_URLS.fetch(:oxford_indian_poetry))
  text = Nokogiri::HTML(html).text
  start_index = text.rindex("I. On reading a love poem")
  raise "Oxford Indian poetry TOC start not found" unless start_index

  end_index = text.index("Afterword:", start_index)
  raise "Oxford Indian poetry TOC end not found" unless end_index

  lines = text[start_index...end_index].split("\n").map { |line| clean(line) }
  section = nil
  rows = []

  lines.each do |line|
    next if line.empty?

    if line.match?(/\A(I{1,3}|IV|V|VI|VII|VIII)\.?\s+/)
      section = line
      next
    end

    match = line.match(/\A(.+?)\s*:\s*(.+?)\s*(?:;?\s+\d+)\z/)
    next unless match

    creator = match[1]
    title = match[2].sub(/\s+link:Pratilipi;?\z/, "")
    rows << [title, creator, section]
  end

  rows.map.with_index(1) do |(title, creator, section_label), index|
    item(
      source_id: "oxford_modern_indian_poetry_1998",
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: section_label,
      evidence_type: "inclusion",
      evidence_weight: "0.40",
      supports: "poetry_anthology_public_toc",
      notes: "Poem-level anthology inclusion only."
    )
  end
end

def extract_clay
  html = fetch(FETCHED_URLS.fetch(:clay_sanskrit))
  doc = Nokogiri::HTML(html)
  doc.css("h3.wp-block-heading").map.with_index(1) do |h3, index|
    full = clean(h3.text)
    title, creator_and_editor = full.split(/\s+by\s+/, 2)
    creator = creator_and_editor.to_s.split(".").first.to_s
    item(
      source_id: "clay_sanskrit_library_56vol",
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: "Official volumes list",
      evidence_type: "boundary_context",
      evidence_weight: "0.25",
      supports: "translation_series_public_index",
      notes: "Translation-series metadata/access row; not standalone canon-selection evidence."
    )
  end
end

def extract_murty
  html = fetch(FETCHED_URLS.fetch(:murty_books))
  doc = Nokogiri::HTML(html)
  seen = Set.new
  rows = []

  doc.css(".booktitle, .book-title, h5").each do |node|
    title = clean(node.text)
    next if title.empty? || title.match?(/subscribe/i)

    container = node.ancestors.find { |ancestor| ancestor.at_css(".author") }
    creator = clean(container&.at_css(".author")&.text)
    key = [title, creator]
    next if seen.include?(key)

    seen << key
    rows << key
  end

  rows.map.with_index(1) do |(title, creator), index|
    item(
      source_id: "murty_classical_library_india",
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: "Public Books page",
      evidence_type: "boundary_context",
      evidence_weight: "0.25",
      supports: "translation_series_public_metadata",
      notes: "Publisher-series metadata row from visible Books page; not standalone canon-selection evidence."
    )
  end
end

def extract_japanese_v2
  html = fetch(FETCHED_URLS.fetch(:japanese_v2))
  doc = Nokogiri::HTML(html)
  toc = doc.at_css("[data-print-title=\"Table of Contents\"]")
  raise "Japanese v2 TOC missing" unless toc

  creator = nil
  section = nil
  rows = []

  toc.css("tr").each do |tr|
    cell = tr.at_css("td")
    next unless cell

    inner = cell.at_css("table tr")
    width = inner&.at_css("td[width]")&.[]("width")
    text = clean(inner ? inner.css("td").last.text : cell.text).gsub(/\A``|''\z/, "")

    case width
    when "40"
      section = text
    when "60"
      creator = text
    when "80"
      rows << [text, creator, section]
    end
  end

  rows.map.with_index(1) do |(title, row_creator, section_label), index|
    evidence_weight = if section_label.to_s.match?(/essay/i)
                        "0.30"
                      elsif section_label.to_s.match?(/poetry/i)
                        "0.45"
                      else
                        "0.55"
                      end
    item(
      source_id: "e017_columbia_modern_japanese_lit_v2_2007",
      raw_title: title,
      raw_creator: row_creator,
      source_rank: index,
      source_section: section_label,
      evidence_type: section_label.to_s.match?(/essay/i) ? "boundary_context" : "representative_selection",
      evidence_weight: evidence_weight,
      supports: "field_anthology_public_toc",
      notes: "Public product TOC row; selection-level anthology evidence."
    )
  end
end

def extract_lti_korea
  xml = fetch(FETCHED_URLS.fetch(:lti_korea_classics))
  doc = Nokogiri::XML(xml)
  doc.css("resultItem").map.with_index(1) do |node, index|
    title = clean(node.at_css("title")&.text.to_s.gsub(/<br\s*\/?>/i, " / "))
    english = title.split(/\s*\/\s*/).reject(&:empty?).last || title
    raw_date = [
      "reg #{clean(node.at_css("regDate")&.text).split.first}",
      "mod #{clean(node.at_css("modDate")&.text).split.first}"
    ].join("; ")
    item(
      source_id: "e018_lti_korea_digital_library_classics",
      raw_title: english,
      raw_creator: "",
      raw_date: raw_date,
      source_rank: index,
      source_section: "Classic Sourcebook OpenAPI",
      evidence_type: "boundary_context",
      evidence_weight: "0.20",
      supports: "classical_metadata_presence",
      notes: "OpenAPI metadata row; not canon-selection evidence."
    )
  end
end

def extract_korean_poetry_sections
  KOREAN_POETRY_SECTIONS.map.with_index(1) do |(title, creator, date, rank, section, notes), index|
    item(
      source_id: "e018_columbia_traditional_korean_poetry_2003",
      raw_title: title,
      raw_creator: creator,
      raw_date: date,
      source_rank: rank,
      source_section: section,
      evidence_type: "boundary_context",
      evidence_weight: index == 3 ? "0.60" : "0.20",
      supports: index == 3 ? "anthology_chapter_public_toc" : "anthology_section_metadata",
      notes: notes
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
rows.concat(extract_fsg_latin_poetry)
rows.concat(extract_oxford_latin_poetry)
rows.concat(extract_rienner)
rows.concat(extract_indian_poetry)
rows.concat(extract_clay)
rows.concat(extract_murty)
rows.concat(extract_japanese_v2)
rows.concat(extract_lti_korea)
rows.concat(extract_korean_poetry_sections)

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
  "e013_fsg_20c_latin_american_poetry_2011" => ["extracted", "Complete 84 creator-group public MARC 505 contents rows ingested from Boulder public record; poem groups remain selection-level evidence."],
  "e013_oxford_latin_american_poetry_2009" => ["extracted", "Public UOC TOC ingested as 137 line-item rows; rows with broken creator/title delimiters are retained raw and require later cleanup."],
  "e014_rienner_anthology_african_lit_2007" => ["extracted", "Complete 146 explicit official contents rows ingested from Lynne Rienner public page; excerpt/chapter/act scope coded conservatively."],
  "oxford_modern_indian_poetry_1998" => ["in_progress", "Book Excerptise public thematic TOC ingested as 124 poem rows; still needs official-copy reconciliation against OUP/NLA metadata."],
  "clay_sanskrit_library_56vol" => ["extracted", "Complete 56-volume official Clay Sanskrit Library list ingested as translation-series metadata rows."],
  "murty_classical_library_india" => ["metadata_ready", "Visible Murty Books page ingested as 19 public metadata rows; ongoing series requires periodic refresh."],
  "e017_columbia_modern_japanese_lit_v2_2007" => ["extracted", "Complete 96 explicit title+creator rows ingested from Kriso public product TOC for Volume 2."],
  "e018_lti_korea_digital_library_classics" => ["metadata_ready", "Complete 26-row Classic Sourcebook OpenAPI metadata list ingested; metadata/access rows do not count as canon-selection evidence."],
  "e018_columbia_traditional_korean_poetry_2003" => ["metadata_ready", "Nine public section/chapter metadata rows ingested; official contents are genre-level except Songs of Flying Dragons."]
}.each do |source_id, (status, notes)|
  raise "missing registry row for #{source_id}" unless registry_by_id[source_id]

  registry_by_id[source_id]["extraction_status"] = status
  registry_by_id[source_id]["notes"] = notes
end
write_tsv(SOURCE_REGISTRY_FILE, SOURCE_REGISTRY_HEADERS, registry_by_id.values, sort_key: "source_id")

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row["packet_id"] == "X022" }
packet_rows << {
  "packet_id" => "X022",
  "packet_family" => "X",
  "scope" => "parser-backed public TOC expansion for E013/E014/E015/E017/E018 sources",
  "status" => "source_items_ingested",
  "gate" => "matching_required",
  "output_artifact" => "_planning/canon_build/tables/canon_source_items.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_006_x022_public_toc_source_items.md",
  "next_action" => "run_matching_relation_scope_for_x022_then_continue_partial_sources",
  "notes" => "Added parser-backed rows from FSG/Oxford Latin American poetry, Rienner African literature, Oxford Indian poetry, Clay, Murty, Japanese v2, and Korean LTI/poetry metadata; no evidence rows or public path changes."
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows, sort_key: "packet_id")

FileUtils.mkdir_p(REPORT_DIR)
report = []
report << "# X022 Public TOC Source-Item Expansion"
report << ""
report << "- status: source_items_ingested_matching_required"
report << "- generated_rows: #{rows.size}"
report << "- replaced_sources: #{REPLACE_SOURCES.size}"
report << "- direct_public_path_changes: 0"
report << "- evidence_rows_added: 0"
report << ""
report << "## Source Counts"
report << ""
report << "| Source ID | Rows | Status After X022 | Notes |"
report << "|---|---:|---|---|"
EXPECTED_COUNTS.keys.sort.each do |source_id|
  registry = registry_by_id.fetch(source_id)
  report << "| `#{source_id}` | #{counts.fetch(source_id)} | #{registry["extraction_status"]} | #{registry["notes"]} |"
end
report << ""
report << "## Source URLs"
report << ""
FETCHED_URLS.each_value { |url| report << "- #{url}" }
report << ""
File.write(REPORT_FILE, report.join("\n"))

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x022_public_toc_expansion_ingested"
manifest["artifacts"]["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_source_items"
manifest["source_item_extraction_batch_x022"] = {
  "source_items_added_or_updated" => rows.size,
  "sources_replaced_or_expanded" => REPLACE_SOURCES.size,
  "complete_public_toc_or_index_sources" => 6,
  "metadata_or_partial_sources" => 3,
  "evidence_rows_added" => 0,
  "status" => "source_items_ingested_matching_required",
  "direct_replacements" => 0
}
manifest["current_counts"] ||= {}
manifest["current_counts"]["source_items"] = source_items_by_id.size
manifest["current_counts"]["source_registry_rows"] = registry_by_id.size
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "ingested or updated #{rows.size} X022 public TOC/source-index rows"
puts counts.sort.map { |source_id, count| "#{source_id}=#{count}" }.join("\n")
