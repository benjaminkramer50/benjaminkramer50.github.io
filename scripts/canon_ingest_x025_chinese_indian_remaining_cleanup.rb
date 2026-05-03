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
REPORT_FILE = File.join(REPORT_DIR, "x_batch_009_x025_chinese_indian_remaining_cleanup.md")

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

SHORTER_SOURCE_ID = "shorter_columbia_traditional_chinese_lit_2000"
CAMBRIDGE_CHINESE_ID = "cambridge_history_chinese_lit_2010"
FULL_TRAD_CHINESE_ID = "columbia_traditional_chinese_lit_1996"
OXFORD_INDIAN_ID = "oxford_modern_indian_poetry_1998"

URLS = {
  SHORTER_SOURCE_ID => "https://cincinnatistate.ecampus.com/shorter-columbia-anthology-traditional/bk/9780231119986",
  CAMBRIDGE_CHINESE_ID => [
    "https://www.cambridge.org/core/books/cambridge-history-of-chinese-literature/76F4628F8A769EEF2DF952B530ED0CEE",
    "https://www.cambridge.org/core/books/cambridge-history-of-chinese-literature/6FEBDC1995B8D05749A1F453D7577D21"
  ],
  FULL_TRAD_CHINESE_ID => "https://search.cpl.org/Record/a207337",
  OXFORD_INDIAN_ID => "https://india.oup.com/product/the-oxford-anthology-of-modern-indian-poetry-9780195639179/"
}.freeze

CITATIONS = {
  SHORTER_SOURCE_ID => "eCampus/Cincinnati State public TOC for ISBN 9780231119986",
  CAMBRIDGE_CHINESE_ID => "Cambridge Core public chapter lists for The Cambridge History of Chinese Literature, Vols. 1-2",
  OXFORD_INDIAN_ID => "Oxford University Press India official product metadata for ISBN 9780195639179"
}.freeze

SOURCE_PREFIXES = {
  SHORTER_SOURCE_ID => "e016_shorter_columbia_tradch",
  CAMBRIDGE_CHINESE_ID => "e016_cambridge_chinese_hist"
}.freeze

EXPECTED_COUNTS = {
  SHORTER_SOURCE_ID => 262,
  CAMBRIDGE_CHINESE_ID => 15
}.freeze

REPLACE_SOURCES = EXPECTED_COUNTS.keys.to_set

MATCH_OVERRIDES = {
  [SHORTER_SOURCE_ID, "Confucian Analects, Book 2"] => ["work_canon_analects", "shorter_columbia_toc_selection_current_path", "0.96", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "Mencius, \"Bull Mountain\" and \"Fish and Bear's Paws\""] => ["work_candidate_mandatory_mencius", "shorter_columbia_toc_selection_current_path", "0.96", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "Chuang Tzu, Chapter 17 and other passages"] => ["work_canon_zhuangzi", "shorter_columbia_toc_selection_current_path", "0.96", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "The Classic Book of Integrity and the Way: Tao te ching"] => ["work_canon_dao_de_jing", "shorter_columbia_toc_selection_current_path", "0.95", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "Classic of Odes"] => ["work_candidate_book_of_songs", "shorter_columbia_toc_selection_current_path", "0.94", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "A New Account of Tales of the World"] => ["work_candidate_wave005_shishuo_xinyu", "shorter_columbia_toc_selection_current_path", "0.96", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "Preface to and tales from Search for the Supernatural"] => ["work_candidate_soushen_ji", "shorter_columbia_toc_selection_current_path", "0.94", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "\"The Story of Ying-ying\""] => ["work_candidate_scale_lit_yingying_biography", "shorter_columbia_toc_selection_current_path", "0.96", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "The Journey to the West, Chapter 7"] => ["work_candidate_journey_to_the_west", "shorter_columbia_toc_selection_current_path", "0.95", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "\"Wu Sung Beats the Tiger,\" from Water Margin, with Commentary by Chin Sheng-t'an"] => ["work_candidate_water_margin", "shorter_columbia_toc_selection_current_path", "0.94", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "\"A Burial Mound for Flowers,\" from Dream of Red Towers"] => ["work_canon_dream_of_the_red_chamber", "shorter_columbia_toc_selection_current_path", "0.92", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "Master Tung's Western Chamber Romance, Chapter 2"] => ["work_candidate_romance_western_chamber", "shorter_columbia_toc_selection_current_path", "0.92", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "Injustice to Tou O"] => ["work_candidate_global_lit_injustice_dou_e", "shorter_columbia_toc_title_variant_current_path", "0.94", "represented_by_selection"],
  [SHORTER_SOURCE_ID, "The Peony Pavilion, Scene 7"] => ["work_candidate_peony_pavilion", "shorter_columbia_toc_selection_current_path", "0.95", "represented_by_selection"]
}.freeze

def fetch(url)
  output, status = Open3.capture2e(
    "curl", "-L", "--silent", "--show-error", "--max-time", "60",
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
  CGI.unescapeHTML(value.to_s)
     .gsub("``", '"')
     .gsub("''", '"')
     .gsub("\u00a0", " ")
     .gsub(/[“”]/, '"')
     .gsub(/[‘’]/, "'")
     .gsub(/[–—−]/, "-")
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

def split_creator_title(raw)
  value = clean(raw)
  if (match = value.match(/\A(Attributed to|Translated by|Compiled by)\s+(.+?),\s+(.+)\z/))
    return [match[3], "#{match[1]} #{match[2]}"]
  end
  if (match = value.match(/\A([^,]{2,50}?),\s+(.+)\z/))
    return [match[2], match[1]]
  end

  [value, ""]
end

def extract_shorter_columbia
  html = fetch(URLS.fetch(SHORTER_SOURCE_ID))
  doc = Nokogiri::HTML(html)
  heading = doc.css("h2").find { |node| clean(node.text) == "Table of Contents" }
  raise "Shorter Columbia public TOC heading missing" unless heading

  table = heading.next_element&.at_css("table")
  raise "Shorter Columbia public TOC table missing" unless table

  part = nil
  section = nil
  rows = []

  table.xpath("./tr").each do |tr|
    cells = tr.xpath("./td")
    next if cells.empty?

    raw = clean(cells[0].text)
    page = clean(cells[2]&.text)
    length = clean(cells[3]&.text)
    next if raw.empty?

    if raw.start_with?("PART ")
      part = raw
      section = nil
      next
    end

    if page.empty?
      section = raw
      next
    end

    next if page.match?(/\A[ivxlcdm]+\z/i)
    next if raw.match?(/\A(Introduction|Bibliographical Note|Acknowledgments|Map of|Principal Chinese Dynasties|Romanization Schemes|List of Permissions)\b/)

    title, creator = split_creator_title(raw)
    rows << [part, section, title, creator, page, length]
  end

  rows.map.with_index(1) do |(part, section, title, creator, page, length), index|
    item(
      source_id: SHORTER_SOURCE_ID,
      raw_title: title,
      raw_creator: creator,
      source_rank: index,
      source_section: [part, section, "p. #{page}", length.empty? ? nil : length].compact.join(" > "),
      evidence_type: "representative_selection",
      evidence_weight: "0.55",
      supports: "field_anthology_public_toc_abridged",
      notes: "Abridged Shorter Columbia public TOC row; useful comparator evidence, not a substitute for the blocked full Columbia anthology denominator."
    )
  end
end

def parse_cambridge_part_row(text)
  value = clean(text)
  return nil if value.match?(/\A(Frontmatter|Introduction|Select Bibliography|Glossary|Index)\b/i)

  if (match = value.match(/\A(\d+)\s+-\s+(.+?)\s+pp\s+(.+)\z/i))
    return [match[1], match[2], match[3]]
  end
  if (match = value.match(/\A(Epilogue:.+?)\s+pp\s+(.+)\z/i))
    return ["E", match[1], match[2]]
  end

  raise "unexpected Cambridge Chinese row: #{value}"
end

def extract_cambridge_chinese
  URLS.fetch(CAMBRIDGE_CHINESE_ID).flat_map.with_index(1) do |url, volume|
    html = fetch(url)
    Nokogiri::HTML(html).css("a.part-link").map { |link| parse_cambridge_part_row(link.text) }.compact.map do |rank, title, pages|
      item(
        source_id: CAMBRIDGE_CHINESE_ID,
        raw_title: title,
        source_rank: "#{volume}.#{rank}",
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

rows = []
rows.concat(extract_shorter_columbia)
rows.concat(extract_cambridge_chinese)

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
remaining_rows = source_item_rows.reject { |row| REPLACE_SOURCES.include?(row["source_id"]) }
source_items_by_id = remaining_rows.to_h { |row| [row["source_item_id"], row] }
rows.each do |row|
  raise "duplicate generated source_item_id: #{row["source_item_id"]}" if source_items_by_id.key?(row["source_item_id"])

  source_items_by_id[row["source_item_id"]] = row
end
write_tsv(SOURCE_ITEMS_FILE, SOURCE_ITEM_HEADERS, source_items_by_id.values, sort_key: "source_item_id")

registry_rows = read_tsv(SOURCE_REGISTRY_FILE)
registry_by_id = registry_rows.to_h { |row| [row["source_id"], row] }
registry_by_id[SHORTER_SOURCE_ID] = {
  "source_id" => SHORTER_SOURCE_ID,
  "source_title" => "The Shorter Columbia Anthology of Traditional Chinese Literature",
  "source_type" => "field_anthology",
  "source_scope" => "Abridged traditional Chinese literature anthology from beginnings to 1919",
  "source_date" => "2000",
  "source_citation" => "eCampus/Cincinnati State public product and TOC: https://cincinnatistate.ecampus.com/shorter-columbia-anthology-traditional/bk/9780231119986",
  "edition" => "abridged Shorter Columbia edition",
  "editors_or_authors" => "Victor H. Mair",
  "publisher" => "Columbia University Press",
  "coverage_limits" => "Abridged version of the full Columbia anthology; not a substitute for the full 1996 denominator",
  "extraction_method" => "Parse public eCampus TOC; classify all rows as anthology selections or excerpts",
  "packet_ids" => "E016;X025",
  "extraction_status" => "extracted",
  "notes" => "Accessible abridged comparator source parsed into 262 public TOC rows after the full Columbia CPL record remained access-blocked."
}

{
  CAMBRIDGE_CHINESE_ID => ["context_only", "Cambridge Core chapter lists parsed into 15 chapter-context rows across Vols. 1-2."],
  FULL_TRAD_CHINESE_ID => ["in_progress", "Full Columbia TOC remains blocked at CPL by Cloudflare; eCampus page for ISBN 9780231074292 exposes an unrelated autobiography TOC, so it was rejected. Shorter Columbia was added separately as an abridged comparator source."],
  OXFORD_INDIAN_ID => ["in_progress", "OUP India official metadata confirms 125 poets, 14 Indian languages, and eight thematic sections; NLA catalog access is Anubis-blocked and no official poem-level TOC was exposed, so 124 Book Excerptise rows remain unreconciled."]
}.each do |source_id, (status, notes)|
  raise "missing registry row for #{source_id}" unless registry_by_id[source_id]

  registry_by_id[source_id]["extraction_status"] = status
  registry_by_id[source_id]["packet_ids"] = append_packet(registry_by_id[source_id]["packet_ids"], "X025")
  registry_by_id[source_id]["notes"] = notes
end
write_tsv(SOURCE_REGISTRY_FILE, SOURCE_REGISTRY_HEADERS, registry_by_id.values, sort_key: "source_id")

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row["packet_id"] == "X025" }
packet_rows << {
  "packet_id" => "X025",
  "packet_family" => "X",
  "scope" => "Traditional Chinese remaining access, Shorter Columbia comparator, Cambridge Chinese context, and Oxford modern Indian official metadata",
  "status" => "source_items_ingested",
  "gate" => "matching_required",
  "output_artifact" => "_planning/canon_build/tables/canon_source_items.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_009_x025_chinese_indian_remaining_cleanup.md",
  "next_action" => "run_matching_relation_scope_evidence_then_move_to_large_world_american_british_anthology_packets",
  "notes" => "Added 277 X025 rows: 262 Shorter Columbia Traditional Chinese public TOC rows and 15 Cambridge Chinese literary-history context rows; full Columbia and Oxford Indian poem-level official-copy debts remain explicit."
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows, sort_key: "packet_id")

FileUtils.mkdir_p(REPORT_DIR)
report = []
report << "# X025 Chinese and Indian Remaining Cleanup"
report << ""
report << "- status: source_items_ingested_matching_required"
report << "- generated_rows: #{rows.size}"
report << "- direct_public_path_changes: 0"
report << "- direct_evidence_rows_added_by_ingester: 0"
report << ""
report << "## Source Counts"
report << ""
report << "| Source ID | Rows | Status After X025 | Notes |"
report << "|---|---:|---|---|"
[SHORTER_SOURCE_ID, CAMBRIDGE_CHINESE_ID, FULL_TRAD_CHINESE_ID, OXFORD_INDIAN_ID].each do |source_id|
  registry = registry_by_id.fetch(source_id)
  row_count = counts[source_id] || source_item_rows.count { |row| row["source_id"] == source_id }
  report << "| `#{source_id}` | #{row_count} | #{registry["extraction_status"]} | #{registry["notes"]} |"
end
report << ""
report << "## Access Decisions"
report << ""
report << "- The full Columbia anthology CPL record remains Cloudflare-blocked. Search snippets are still insufficient for reliable row-level ingestion."
report << "- The eCampus page for ISBN 9780231074292 was rejected because its TOC begins with memoir/autobiography chapter titles, not the Columbia anthology contents."
report << "- The Shorter Columbia anthology is ingested as a separate abridged comparator source, not as a replacement for the full anthology."
report << "- Cambridge Chinese rows are chapter-context evidence only."
report << "- OUP India confirms denominator metadata for Oxford modern Indian poetry, but no official poem-level TOC was exposed. NLA access was blocked by Anubis."
report << ""
report << "## Source URLs"
report << ""
[
  URLS.fetch(SHORTER_SOURCE_ID),
  *URLS.fetch(CAMBRIDGE_CHINESE_ID),
  URLS.fetch(FULL_TRAD_CHINESE_ID),
  URLS.fetch(OXFORD_INDIAN_ID),
  "https://masters.ecampus.com/columbia-anthology-traditional-chinese/bk/9780231074292",
  "https://catalogue.nla.gov.au/catalog/1539648"
].each { |url| report << "- #{url}" }
report << ""
File.write(REPORT_FILE, report.join("\n"))

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x025_chinese_indian_remaining_cleanup_ingested"
manifest["artifacts"]["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_x025_source_items"
manifest["source_item_extraction_batch_x025"] = {
  "source_items_added_or_updated" => rows.size,
  "shorter_columbia_traditional_chinese_rows" => counts.fetch(SHORTER_SOURCE_ID),
  "cambridge_chinese_context_rows" => counts.fetch(CAMBRIDGE_CHINESE_ID),
  "full_columbia_traditional_chinese_status" => "blocked_at_cpl_wrong_toc_rejected_elsewhere",
  "oxford_modern_indian_poetry_status" => "official_denominator_confirmed_poem_level_toc_unreconciled",
  "evidence_rows_added" => 0,
  "status" => "source_items_ingested_matching_required",
  "direct_replacements" => 0
}
manifest["current_counts"] ||= {}
manifest["current_counts"]["source_items"] = source_items_by_id.size
manifest["current_counts"]["source_registry_rows"] = registry_by_id.size
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "ingested or updated #{rows.size} X025 cleanup rows"
puts counts.sort.map { |source_id, count| "#{source_id}=#{count}" }.join("\n")
