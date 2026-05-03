#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "csv"
require "fileutils"
require "json"
require "nokogiri"
require "open3"
require "open-uri"
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
EVIDENCE_FILE = File.join(TABLE_DIR, "canon_evidence.tsv")
WORK_CANDIDATES_FILE = File.join(TABLE_DIR, "canon_work_candidates.tsv")
ALIASES_FILE = File.join(TABLE_DIR, "canon_aliases.tsv")
MANIFEST_FILE = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_FILE = File.join(REPORT_DIR, "x_batch_011_x027_longman_world_lit_toc.md")

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

SOURCE_ID = "longman_world_lit_2e_2009"
PACKET_ID = "X027"
USER_AGENT = "Mozilla/5.0 canon-build-source-extraction"

VOLUME_SOURCES = {
  "A" => {
    method: :pearson_next_data,
    title: "The Ancient World",
    url: "https://www.pearson.com/en-us/subject-catalog/p/longman-anthology-of-world-literature-volume-i-abc-the-the-ancient-world-the-medieval-era-and-the-early-modern-period/P200000002123?view=educator",
    provenance: "Pearson public product page tableOfContents JSON"
  },
  "B" => {
    method: :ecampus_publisher_table,
    title: "The Medieval Era",
    url: "https://lyon.ecampus.com/longman-anthology-world-literature-volume/bk/9780205625963",
    provenance: "eCampus public product page publisher-provided table of contents"
  },
  "C" => {
    method: :ecampus_publisher_table,
    title: "The Early Modern Period",
    url: "https://lyon.ecampus.com/longman-anthology-world-literature-early/bk/9780205625970",
    provenance: "eCampus public product page publisher-provided table of contents"
  },
  "D" => {
    method: :pearson_next_data,
    title: "The Seventeenth and Eighteenth Centuries",
    url: "https://www.pearson.com/en-us/subject-catalog/p/longman-anthology-of-world-literature-the-the-seventeenth-and-eighteenth-centuries-volume-d/P200000002126?view=educator",
    provenance: "Pearson public product page tableOfContents JSON"
  },
  "E" => {
    method: :pearson_next_data,
    title: "The Nineteenth Century",
    url: "https://www.pearson.com/en-ca/subject-catalog/p/longman-anthology-of-world-literature-the-the-nineteenth-century-volume-e/P200000002125/9780134506678?view=educator",
    provenance: "Pearson public product page tableOfContents JSON"
  },
  "F" => {
    method: :pearson_next_data,
    title: "The Twentieth Century",
    url: "https://www.pearson.com/en-us/subject-catalog/p/longman-anthology-of-world-literature-volume-f-the-the-twentieth-century/P200000002124/9780134508627?view=educator",
    provenance: "Pearson public product page tableOfContents JSON"
  }
}.freeze

BOILERPLATE_ROWS = Set.new([
  "bibliography",
  "credits",
  "index",
  "table of contents provided by publisher all rights reserved"
]).freeze

COLON_WORK_PREFIXES = Set.new([
  "genesis",
  "shah nama",
  "shahnameh",
  "translations"
]).freeze

GENERIC_MATCH_TITLES = Set.new(%w[
  act aphorisms bibliography canto chapter comedy conclusion crosscurrents debate elegies epigrams
  excerpts index introduction lyrics ode odes poems preface prologue resonance resonances songs tales
]).freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows, sort_key:)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.sort_by { |row| row[sort_key].to_s }.each do |row|
      csv << headers.map { |header| row[header].to_s }
    end
  end
end

def clean(value)
  CGI.unescapeHTML(value.to_s)
     .gsub("\f", " ")
     .gsub(/\u00a0|\u00ad/, " ")
     .gsub(/[“”]/, '"')
     .gsub(/[‘’]/, "'")
     .gsub(/[–—−]/, "-")
     .unicode_normalize(:nfkd)
     .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
     .gsub(/[\u0000-\u001f]/, " ")
     .gsub(/\s+/, " ")
     .strip
end

def normalize_for_match(value)
  value.to_s
       .downcase
       .gsub(/&/, " and ")
       .gsub(/[[:punct:]]+/, " ")
       .gsub(/\b(the|a|an|le|la|les|el|los|las|il|lo|gli|i|der|die|das)\b/, " ")
       .gsub(/\s+/, " ")
       .strip
end

def date_pattern
  /(?:c\.|ca\.|fl\.|r\.|b\.|d\.|before|active|mid|early|late|century|millennium|b\.c|bce|c\.e|ce|\d{2,4})/i
end

def extract_date_suffix(title)
  match = title.match(/\s*\(([^)]*#{date_pattern}[^)]*)\)\s*\z/i)
  return [title, ""] unless match

  [title.sub(match[0], "").strip, clean(match[1])]
end

def strip_trailing_editorial_notes(value)
  line = clean(value)
  loop do
    stripped = line.sub(/,?\s*\((?:trans\.|translation|translated|new international version|jerusalem bible translation|revised standard version|edited by|version by|tr\.)[^)]*\)\s*\z/i, "").strip
    break if stripped == line

    line = stripped
  end
  line
end

def likely_work_heading?(value)
  line = clean(value)
  normalized = normalize_for_match(line)
  return true if normalized.match?(/\b(book|song|songs|epic|tale|tales|poem|poems|quran|bible|mahabharata|ramayana|odyssey|iliad|beowulf|cid|genji|canterbury|divine comedy|gilgamesh|song of songs|book of job)\b/)
  return true if line.match?(/\A(?:THE|The)\s+/)

  false
end

def creator_heading?(value)
  line = clean(value)
  return false if line.include?(":")
  return false if line.match?(/\bfrom\b/i)
  return false unless line.match?(/\([^)]*#{date_pattern}[^)]*\)\s*\z/i)
  return false if likely_work_heading?(line)

  words = line.sub(/\([^)]*\)\s*\z/, "").split(/\s+/)
  words.size <= 7
end

def section_like?(value)
  line = clean(value)
  section_base, = extract_date_suffix(line)
  return true if line.match?(/\AVolume\s+[A-F]:/i)
  return true if line.match?(/\A(?:Perspectives|Resonance|Resonances|Crosscurrents|Translations):?/i)
  return true if line.match?(/\A(?:Bibliography|Credits|Index)\z/i)
  return true if section_base.upcase == section_base && section_base.scan(/[A-Z]/).size >= 6

  section_titles = [
    "Classical Arabic And Islamic Literatures",
    "Early Modern Europe",
    "Early South Asia",
    "Japan",
    "Medieval China",
    "Medieval Europe",
    "Poetry Of The Tang Dynasty",
    "Pre-Islamic Poetry",
    "The Ancient Near East",
    "The Rise Of The Vernacular In Europe",
    "Vernacular Writing In South Asia",
    "Women And The Vernacular",
    "Women In Early China"
  ]
  section_titles.any? { |title| normalize_for_match(title) == normalize_for_match(section_base) }
end

def evidence_type_for(title, creator_heading)
  value = clean(title)
  return "boundary_context" if creator_heading || section_like?(value)
  return "representative_selection" if value.match?(/\Afrom\b/i)
  return "representative_selection" if value.match?(/:\s*(?:Chapters?|Books?|Cantos?|Suras?)\b/i)
  return "representative_selection" if value.match?(/\A(?:Book|Canto|Chapter|Part|Scene|Sura|Psalm|Tablet|Act)\b/i)
  return "representative_selection" if value.match?(/\A(?:First|Second|Third|Fourth|Fifth|Sixth|Seventh|Eighth|Ninth|Tenth)\s+(?:Day|Story|Canto)\b/i)
  return "representative_selection" if value.match?(/\A\d+\.?\s+/)
  return "representative_selection" if value.match?(/\A\[[^\]]+\]/)

  "inclusion"
end

def parse_creator_title(value, current_creator, current_date)
  line = strip_trailing_editorial_notes(value)
  title, raw_date = extract_date_suffix(line)

  if (match = line.match(/\A(.+?)\s*\(([^)]*#{date_pattern}[^)]*)\)\s*:\s+(.+)\z/i))
    return [clean(match[3]), clean(match[1]), clean(match[2])]
  end

  if (match = line.match(/\A(.+?)\s*\(([^)]*#{date_pattern}[^)]*)\)\s+(from\s+.+)\z/i))
    return [clean(match[3]), clean(match[1]), clean(match[2])]
  end

  if (match = line.match(/\A(.+?)\s*\(([^)]*#{date_pattern}[^)]*)\)\s+(.+)\z/i))
    return [clean(match[3]), clean(match[1]), clean(match[2])]
  end

  if (match = line.match(/\A([^:]{2,80}):\s+(.+)\z/))
    possible_creator = clean(match[1])
    possible_title = clean(match[2])
    return [title, current_creator, raw_date] if COLON_WORK_PREFIXES.include?(normalize_for_match(possible_creator))

    unless possible_creator.match?(/\A(?:Book|Canto|Chapter|Part|Scene|Sura|Psalm|Perspectives|Translations|Resonance|Resonances)\b/i)
      return [possible_title, possible_creator, raw_date]
    end
  end

  [title, current_creator, raw_date.empty? ? current_date : raw_date]
end

def title_match_variants(title)
  base = clean(title)
  variants = [base]
  variants << base.sub(/\Afrom\s+/i, "")
  variants << base.sub(/\ASelections?\s+from\s+/i, "")
  variants << base.sub(/\A\d+\.?\s+/, "")
  variants << base.sub(/\A(?:Book|Canto|Chapter|Part|Scene|Sura|Psalm)\s+\d+\.?\s*:\s*/i, "")
  variants << base.sub(/:\s+.+\z/, "")
  variants.map { |variant| normalize_for_match(variant) }.reject(&:empty?).uniq
end

def source_item_id(volume, rank, title, creator)
  slug = clean([creator, title].reject(&:empty?).join(" "))
         .downcase
         .gsub(/[^a-z0-9]+/, "_")
         .gsub(/\A_+|_+\z/, "")[0, 88]
  "longman2e_vol#{volume.downcase}_#{rank.to_s.rjust(3, "0")}_#{slug}"
end

def fetch_pearson_rows(url)
  html = URI.open(url, "User-Agent" => USER_AGENT, read_timeout: 45).read
  data = JSON.parse(Nokogiri::HTML(html).at_css("#__NEXT_DATA__").text)
  fallback = data.dig("props", "pageProps", "fallback")
  marketing = fallback.find { |key, _value| key.include?("marketing-content") }&.[](1)
  raise "Pearson marketing content missing for #{url}" unless marketing

  toc = marketing.dig("programMarketingContent", "marketingContentEducator", "tableOfContents").to_s
  if toc.empty?
    marketing.fetch("productMarketingContentCollection", []).each do |entry|
      candidate = entry.dig("marketingContentEducator", "tableOfContents").to_s
      toc = candidate unless candidate.empty?
    end
  end
  raise "Pearson TOC missing for #{url}" if toc.empty?

  Nokogiri::HTML.fragment(toc).css("p").map { |node| clean(node.text) }
end

def fetch_ecampus_rows(url)
  output, status = Open3.capture2e(
    "/usr/bin/curl", "--http1.1", "-L", "--silent", "--show-error", "--max-time", "45",
    "-A", USER_AGENT, url
  )
  raise "curl failed for #{url}: #{output}" unless status.success?

  doc = Nokogiri::HTML(output)
  toc_heading = doc.css("h2").find { |node| clean(node.text) == "Table of Contents" }
  raise "eCampus TOC heading missing for #{url}" unless toc_heading

  toc_table = toc_heading.next_element
  raise "eCampus TOC table missing for #{url}" unless toc_table

  toc_table.css("tr td:first-child").map { |node| clean(node.text) }
end

def build_work_indexes
  works = read_tsv(WORK_CANDIDATES_FILE)
  aliases = read_tsv(ALIASES_FILE)
  works_by_id = works.to_h { |row| [row.fetch("work_id"), row] }
  title_index = Hash.new { |hash, key| hash[key] = [] }

  works.each do |work|
    [work["canonical_title"], work["sort_title"], work["original_title"]].each do |title|
      normalized = normalize_for_match(title)
      title_index[normalized] << work.fetch("work_id") unless normalized.empty?
    end
  end

  aliases.each do |alias_row|
    work_id = alias_row.fetch("work_id")
    next unless works_by_id.key?(work_id)

    normalized = normalize_for_match(alias_row["alias"])
    title_index[normalized] << work_id unless normalized.empty?
  end

  [works_by_id, title_index.transform_values { |values| values.uniq }]
end

def unique_exact_match(title, title_index)
  variants = title_match_variants(title)
  return nil if variants.any? { |variant| GENERIC_MATCH_TITLES.include?(variant) }

  candidates = variants.flat_map { |variant| title_index.fetch(variant, []) }.uniq
  candidates.size == 1 ? candidates.first : nil
end

def build_rows_for_volume(volume, config, title_index)
  raw_rows =
    case config.fetch(:method)
    when :pearson_next_data
      fetch_pearson_rows(config.fetch(:url))
    when :ecampus_publisher_table
      fetch_ecampus_rows(config.fetch(:url))
    else
      raise "unknown extraction method: #{config.fetch(:method)}"
    end

  rows = []
  current_section = "Vol. #{volume}: #{config.fetch(:title)}"
  current_creator = ""
  current_creator_date = ""
  rank = 0

  raw_rows.each do |raw_row|
    line = clean(raw_row)
    next if line.empty?
    next if BOILERPLATE_ROWS.include?(normalize_for_match(line))

    rank += 1
    is_creator_heading = creator_heading?(line)
    if section_like?(line)
      current_section = "Vol. #{volume}: #{line}"
      current_creator = ""
      current_creator_date = ""
    elsif is_creator_heading
      creator_title, creator_date = extract_date_suffix(line)
      current_creator = clean(creator_title)
      current_creator_date = creator_date
    end

    title, creator, raw_date = parse_creator_title(line, current_creator, current_creator_date)
    evidence_type = evidence_type_for(title, is_creator_heading)
    matched_work_id = evidence_type == "boundary_context" ? nil : unique_exact_match(title, title_index)
    match_status =
      if matched_work_id && evidence_type == "representative_selection"
        "represented_by_selection"
      elsif matched_work_id
        "matched_current_path"
      else
        "unmatched"
      end

    rows << {
      "source_id" => SOURCE_ID,
      "source_item_id" => source_item_id(volume, rank, title, creator),
      "raw_title" => title,
      "raw_creator" => evidence_type == "boundary_context" ? "" : creator,
      "raw_date" => raw_date,
      "source_rank" => rank.to_s,
      "source_section" => current_section,
      "source_url" => config.fetch(:url),
      "source_citation" => "Longman Anthology of World Literature, 2nd ed., Vol. #{volume}: #{config.fetch(:title)}; #{config.fetch(:provenance)}",
      "matched_work_id" => matched_work_id.to_s,
      "match_method" => matched_work_id ? "unique_exact_title_or_alias" : "",
      "match_confidence" => matched_work_id ? "0.88" : "",
      "evidence_type" => evidence_type,
      "evidence_weight" => evidence_type == "boundary_context" ? "0.00" : (evidence_type == "representative_selection" ? "0.55" : "0.80"),
      "supports" => evidence_type == "boundary_context" ? "toc_structure" : "world_literature_anthology_toc",
      "match_status" => match_status,
      "notes" => "X027 Longman 2e TOC extraction; #{config.fetch(:provenance)}; exact matches remain provisional until X013/X014/X017 gates rerun."
    }
  end

  rows
end

def add_packet_id(packet_ids, packet_id)
  (packet_ids.to_s.split(";").reject(&:empty?) + [packet_id]).uniq.join(";")
end

works_by_id, title_index = build_work_indexes
source_items = read_tsv(SOURCE_ITEMS_FILE)
source_items = source_items.reject { |row| row.fetch("source_id") == SOURCE_ID }

new_rows = VOLUME_SOURCES.flat_map do |volume, config|
  build_rows_for_volume(volume, config, title_index)
end

duplicate_ids = new_rows.group_by { |row| row.fetch("source_item_id") }.select { |_id, rows| rows.size > 1 }
raise "duplicate source item IDs: #{duplicate_ids.keys.first(10).join(", ")}" unless duplicate_ids.empty?

source_items += new_rows
write_tsv(SOURCE_ITEMS_FILE, SOURCE_ITEM_HEADERS, source_items, sort_key: "source_item_id")
current_longman_evidence_rows =
  if File.file?(EVIDENCE_FILE)
    read_tsv(EVIDENCE_FILE).count { |row| row.fetch("source_id", "") == SOURCE_ID }
  else
    0
  end

source_registry = read_tsv(SOURCE_REGISTRY_FILE)
source_registry.each do |row|
  next unless row.fetch("source_id") == SOURCE_ID

  row["packet_ids"] = add_packet_id(row["packet_ids"], PACKET_ID)
  row["extraction_status"] = "extracted"
  row["coverage_limits"] = "Official Pearson public TOCs for Vols. A/D/E/F; publisher-provided eCampus TOC tables for Vols. B/C because Pearson live public C/B TOCs were not consistently accessible; many entries are excerpts, poem selections, or context rows"
  row["extraction_method"] = "Extract Pearson tableOfContents JSON plus eCampus publisher-provided TOC table rows; preserve provenance per source item; match only unique exact title/alias rows"
  row["notes"] = "X027 Longman World Literature 2e mixed public TOC extraction; not decisive without scope review"
end
write_tsv(SOURCE_REGISTRY_FILE, SOURCE_REGISTRY_HEADERS, source_registry, sort_key: "source_id")

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row.fetch("packet_id") == PACKET_ID }
packet_rows << {
  "packet_id" => PACKET_ID,
  "packet_family" => "X",
  "scope" => "Longman World Literature 2e public TOC extraction",
  "status" => "source_items_ingested",
  "gate" => "evidence_scope_review_required",
  "output_artifact" => "_planning/canon_build/source_crosswalk_reports/x_batch_011_x027_longman_world_lit_toc.md",
  "next_action" => "rerun_x013_x014_x017_then_continue_bedford_fragments",
  "notes" => "#{new_rows.size} Longman 2e source-item rows from Vols. A-F; mixed Pearson/eCampus public TOC provenance; public canon unchanged"
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows, sort_key: "packet_id")

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x027_longman_world_lit_toc_ingested"
manifest["artifacts"]["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_x025_x026_x027_source_items"
manifest["source_crosswalk_batch_e001_e006"]["e005_status"] = "extracted_x027_longman_world_lit_2e_public_toc"
manifest["source_item_extraction_batch_x027"] = {
  "source_items_added_or_updated" => new_rows.size,
  "volume_row_counts" => VOLUME_SOURCES.keys.to_h { |volume| [volume, new_rows.count { |row| row.fetch("source_item_id").include?("vol#{volume.downcase}_") }] },
  "pearson_direct_volume_rows" => new_rows.count { |row| row.fetch("source_url").include?("pearson.com") },
  "ecampus_publisher_toc_volume_rows" => new_rows.count { |row| row.fetch("source_url").include?("ecampus.com") },
  "provisional_unique_exact_matches" => new_rows.count { |row| !row.fetch("matched_work_id").empty? },
  "evidence_rows_added" => 0,
  "evidence_rows_after_x013_x014_x017_rerun" => current_longman_evidence_rows,
  "status" => "source_items_ingested_evidence_scope_review_required",
  "direct_replacements" => 0
}
File.write(MANIFEST_FILE, "#{manifest.to_yaml}")

volume_counts = VOLUME_SOURCES.keys.to_h { |volume| [volume, new_rows.count { |row| row.fetch("source_item_id").include?("vol#{volume.downcase}_") }] }
match_counts = new_rows.group_by { |row| row.fetch("match_status") }.transform_values(&:size)
evidence_counts = new_rows.group_by { |row| row.fetch("evidence_type") }.transform_values(&:size)
downstream_note =
  if current_longman_evidence_rows.positive?
    "Current evidence table contains #{current_longman_evidence_rows} Longman evidence rows generated after the matching/relation/evidence gates. They remain provisional until source-debt and scope blockers are resolved."
  else
    "Provisional exact matches use unique normalized title/alias matches only. They remain provisional until the expanded match, relation, evidence, and source-debt queues are rerun."
  end

report = <<~MARKDOWN
  # X Batch 11 Report: X027 Longman World Literature 2e TOC Extraction

  Date: 2026-05-03

  Status: source items ingested; public canon unchanged.

  ## Summary

  X027 extracted public table-of-contents rows for `longman_world_lit_2e_2009`, covering Volumes A-F of *The Longman Anthology of World Literature*, 2nd ed. Pearson's public product-page `tableOfContents` JSON was used where accessible. Volumes B and C were extracted from eCampus product-page TOC tables whose page labels the TOC as publisher-provided, because Pearson live public B/C TOC access was uneven.

  These rows expand the source-evidence universe only. They do not authorize additions, cuts, or score changes until X013/X014/X017 review gates are rerun and source-debt/scope blockers are resolved.

  ## Extraction Counts

  | Volume | Source provenance | Rows |
  |---|---|---:|
  #{VOLUME_SOURCES.map { |volume, config| "| #{volume} | #{config.fetch(:provenance)} | #{volume_counts.fetch(volume)} |" }.join("\n")}

  Total source-item rows added or replaced: #{new_rows.size}

  ## Provisional Matching

  | Match status | Rows |
  |---|---:|
  #{match_counts.sort.map { |status, count| "| #{status} | #{count} |" }.join("\n")}

  | Evidence type | Rows |
  |---|---:|
  #{evidence_counts.sort.map { |type, count| "| #{type} | #{count} |" }.join("\n")}

  #{downstream_note}

  ## Source Limits

  - Volumes A/D/E/F are Pearson-direct public TOC JSON rows.
  - Volumes B/C are public retailer-hosted TOC tables marked as publisher-provided; they are useful for source discovery but should be reviewed before any high-stakes boundary decision.
  - The Longman TOC mixes complete works, excerpts, poem selections, author headings, translations features, resonances, perspectives, and crosscurrents. The script marks obvious structure rows as `boundary_context` and obvious excerpts as `representative_selection`, but final scope remains gated.
  - No public `_data/canon_quick_path.yml` row changed.

  ## Next Actions

  1. Rerun X013/X014/X017 gates against the expanded source-item table.
  2. Review Longman rows that exact-match current path titles but may be selections/excerpts.
  3. Continue E006 Bedford fragment extraction only as partial anchor evidence unless a complete authorized TOC is found.
MARKDOWN

File.write(REPORT_FILE, report)

puts "ingested or updated #{new_rows.size} X027 Longman World Literature 2e TOC rows"
volume_counts.each { |volume, count| puts "Vol. #{volume}=#{count}" }
puts "provisional_unique_exact_matches=#{new_rows.count { |row| !row.fetch("matched_work_id").empty? }}"
