#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "csv"
require "fileutils"
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
ALIASES_FILE = File.join(TABLE_DIR, "canon_aliases.tsv")
MANIFEST_FILE = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_FILE = File.join(REPORT_DIR, "x_batch_010_x026_norton_world_lit_toc.md")

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

PRE1650_SOURCE_ID = "norton_world_lit_5e_full_pre1650"
POST1650_SOURCE_ID = "norton_world_lit_5e_full_post1650"

VOLUME_URLS = {
  "A" => "https://cdn.wwnorton.com/marketing/college/misc_marketing_assets/LITERATURE_Highlighted_NAWOL5e_VolA_3pp_TOC_lr.pdf",
  "B" => "https://cdn.wwnorton.com/marketing/college/misc_marketing_assets/LITERATURE_Highlighted_NAWOL5e_VolB_6pp_TOC_lr.pdf",
  "C" => "https://cdn.wwnorton.com/marketing/college/misc_marketing_assets/LITERATURE_Highlighted_NAWOL5e_VolC_6pp_TOC_lr.pdf",
  "D" => "https://cdn.wwnorton.com/marketing/college/misc_marketing_assets/LITERATURE_Highlighted_NAWOL5e_VolD_6pp_TOC_lr.pdf",
  "E" => "https://cdn.wwnorton.com/marketing/college/misc_marketing_assets/LITERATURE_Highlighted_NAWOL5e_VolE_6pp_TOC_lr.pdf",
  "F" => "https://cdn.wwnorton.com/marketing/college/misc_marketing_assets/LITERATURE_Highlighted_NAWOL5e_VolF_6pp_TOC_lr.pdf"
}.freeze

VOLUME_SOURCE_IDS = {
  "A" => PRE1650_SOURCE_ID,
  "B" => PRE1650_SOURCE_ID,
  "C" => PRE1650_SOURCE_ID,
  "D" => POST1650_SOURCE_ID,
  "E" => POST1650_SOURCE_ID,
  "F" => POST1650_SOURCE_ID
}.freeze

EXPECTED_VOLUME_COUNTS = {
  "A" => 338,
  "B" => 512,
  "C" => 203,
  "D" => 80,
  "E" => 205,
  "F" => 248
}.freeze

REPLACE_SOURCES = [PRE1650_SOURCE_ID, POST1650_SOURCE_ID].to_set

GENERIC_MATCH_TITLES = Set.new(%w[
  aphorisms comedy debate elegy epigrams hymns introduction lyrics odes poems prologue songs tales
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
     .gsub(/\u00a0|\u00ad/, "")
     .gsub(/[“”]/, '"')
     .gsub(/[‘’]/, "'")
     .gsub(/[–—−]/, "-")
     .unicode_normalize(:nfkd)
     .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
     .gsub(/[\u0000-\u001f]/, " ")
     .gsub(/\s+/, " ")
     .strip
end

def normalize_line(value)
  line = clean(value)
  line = line.gsub(/\b[ivxlcdm](?:\s+[ivxlcdm])*\s*\|\s*C\s*O\s*N\s*T\s*E\s*N\s*T\s*S\s*/i, "")
  line = line.gsub(/\bC\s*O\s*N\s*T\s*E\s*N\s*T\s*S\s*\|\s*[ivxlcdm](?:\s+[ivxlcdm])*\s*/i, "")
  line = line.gsub(/\A[-+01\s]+(?=\S)/, "")
  clean(line)
end

def skip_line?(value)
  line = normalize_line(value)
  return true if line.empty?
  return true if line.match?(/\A(?:Contents|C\s*O\s*N\s*T\s*E\s*N\s*T\s*S)\z/i)
  return true if line.include?("NAWOL5e_")
  return true if line.match?(/\A(new to the|preface|acknowledg|acknowl|New selection|New translation)/i)
  return true if line.match?(/\A[-+01\s]+\z/) || line.match?(/\Av+i*\z/i)
  return true if line.match?(/\A\*?\s*New selection/i)
  return true if line.match?(/\A\(?Translated by\b/i)
  return true if line.match?(/\A\(?Versification by\b/i)
  return true if line.match?(/\A\(?Edited by\b/i)

  false
end

def page_line?(value)
  line = normalize_line(value)
  return false if line.match?(/\A[ivxlcdm]+\z/i)

  line.match?(%r{(?:/\s*\d|\s+\d+\s*\z|\d+\s*/\s*\z)})
end

def parse_page_line(value)
  line = normalize_line(value).sub(/\A\*\s*/, "").sub(/\A†\s*/, "").strip

  title, pages =
    if (match = line.match(%r{\s*/\s*([0-9][0-9,\s]*)\s*\z}))
      [line[0...match.begin(0)].strip, match[1].gsub(/\s+/, "")]
    elsif (match = line.match(/\s+([0-9][0-9,\s]*)\s*\/\s*\z/))
      [line[0...match.begin(0)].strip, match[1].gsub(/\s+/, "")]
    elsif (match = line.match(/\s+([0-9][0-9,\s]*)\s*\z/))
      [line[0...match.begin(0)].strip, match[1].gsub(/\s+/, "")]
    else
      return nil
    end

  title = normalize_line(title).sub(/\A\*\s*/, "").sub(/\A†\s*/, "").strip
  return nil if title.empty? || skip_line?(title)

  [title, pages]
end

def fetch_pdf_text(url)
  Tempfile.create(["nawol5e-toc", ".pdf"]) do |pdf|
    pdf.binmode
    output, status = Open3.capture2e(
      "curl", "-L", "--silent", "--show-error", "--max-time", "60",
      "-A", "Mozilla/5.0 canon-build-source-extraction", url, "-o", pdf.path
    )
    raise "curl failed for #{url}: #{output}" unless status.success?

    text, pdf_status = Open3.capture2e("pdftotext", "-raw", pdf.path, "-")
    raise "pdftotext failed for #{url}: #{text}" unless pdf_status.success?

    text
  end
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

def title_match_variants(title)
  base = clean(title)
  variants = [base]
  variants << base.sub(/\AFrom\s+/i, "")
  variants << base.sub(/\ASelections?\s+from\s+/i, "")
  variants << base.sub(/\A\d+\.?\s+/, "")
  variants.map { |variant| normalize_for_match(variant) }.reject(&:empty?).uniq
end

def date_suffix(title)
  match = title.match(/\s*\(([^)]*(?:century|b\.c|bce|c\.e|ce|ca\.|b\.|d\.|\d{3,4})[^)]*)\)\s*\z/i)
  return [title, ""] unless match

  [title.sub(match[0], "").strip, clean(match[1])]
end

def split_creator_title(raw_title)
  title_without_date, raw_date = date_suffix(clean(raw_title))
  if (match = title_without_date.match(/\A([^,]{2,60}),\s+(.+)\z/)) && match[2].match?(/\A(From|The|A|An|\[|[A-Z])/)
    return [clean(match[2]), clean(match[1]), raw_date]
  end

  [title_without_date, "", raw_date]
end

def section_like?(title)
  value = clean(title)
  upper = value.upcase
  return true if value.match?(/\A[IVX]+\.\s+/)
  return true if upper.match?(/\A(?:ORATURE|TRAVEL AND ENCOUNTER|REVOLUTIONARY CONTEXTS|ROMANTIC POETS AND THEIR SUCCESSORS|WHAT IS ENLIGHTENMENT\?)\z/)
  return false unless value.split.size >= 2

  uppercaseish = upper.gsub(/[^A-Z]/, "").size >= [6, (upper.size * 0.55).to_i].max
  return false unless uppercaseish

  upper.match?(/\b(LITERATURE|WORLD|POETRY|POETS|DRAMA|FICTION|CONTEXTS?|MODERNITIES|MODERNISMS|ORATURE|REVOLUTIONS?|COSMOS|ENCOUNTERS?|MEDITERRANEAN|EASTERN)\b/)
end

def evidence_type_for(title)
  value = clean(title)
  return "boundary_context" if section_like?(value)
  return "representative_selection" if value.match?(/\AFrom\b/i)
  return "representative_selection" if value.match?(/\A(Book|Chapter|Tablet|Part)\b/i)
  return "representative_selection" if value.match?(/\A\d+\.?\s+\[/)
  return "representative_selection" if value.match?(/\A\[[^\]]+\]/)

  "inclusion"
end

def source_item_id(volume, rank, title, creator)
  slug = clean([creator, title].reject(&:empty?).join(" "))
         .downcase
         .gsub(/[^a-z0-9]+/, "_")
         .gsub(/\A_+|_+\z/, "")[0, 88]
  "nawol5e_vol#{volume.downcase}_#{rank.to_s.rjust(3, "0")}_#{slug}"
end

def build_work_indexes
  works = read_tsv(WORK_CANDIDATES_FILE)
  aliases = read_tsv(ALIASES_FILE)
  works_by_id = works.to_h { |row| [row.fetch("work_id"), row] }
  title_index = Hash.new { |hash, key| hash[key] = [] }

  works.each do |work|
    [work["canonical_title"], work["sort_title"], work["original_title"]].each do |title|
      normalized = normalize_for_match(title)
      title_index[normalized] << work unless normalized.empty?
    end
  end

  aliases.each do |alias_row|
    normalized = normalize_for_match(alias_row["alias"])
    work = works_by_id[alias_row["work_id"]]
    title_index[normalized] << work if work && !normalized.empty?
  end

  [works_by_id, title_index]
end

def unique_exact_match(title, title_index)
  return nil if section_like?(title)

  title_match_variants(title).each do |normalized|
    next if normalized.length < 4 || GENERIC_MATCH_TITLES.include?(normalized)

    candidates = title_index[normalized].uniq { |work| work.fetch("work_id") }
    return candidates.first if candidates.size == 1
  end

  nil
end

def extract_volume_rows(volume, url, title_index)
  rows = []
  buffer = []

  fetch_pdf_text(url).each_line do |raw_line|
    line = normalize_line(raw_line)
    next if skip_line?(line)

    if page_line?(line)
      combined = (buffer + [line]).join(" ")
      buffer = []
      parsed = parse_page_line(combined)
      next unless parsed

      raw_title, pages = parsed
      title, creator, raw_date = split_creator_title(raw_title)
      evidence_type = evidence_type_for(title)
      source_id = VOLUME_SOURCE_IDS.fetch(volume)
      rank = rows.size + 1
      matched_work = unique_exact_match(title, title_index)
      match_status = "unmatched"
      match_method = ""
      match_confidence = ""
      matched_work_id = ""
      if matched_work && evidence_type != "boundary_context"
        matched_work_id = matched_work.fetch("work_id")
        match_method = "norton_world_lit_5e_exact_title_or_alias"
        match_confidence = creator.empty? ? "0.82" : "0.90"
        match_status = evidence_type == "representative_selection" ? "represented_by_selection" : "matched_current_path"
        match_status = "matched_candidate" unless matched_work.fetch("candidate_status") == "incumbent_current_path"
      end

      rows << {
        "source_id" => source_id,
        "source_item_id" => source_item_id(volume, rank, title, creator),
        "raw_title" => title,
        "raw_creator" => creator,
        "raw_date" => raw_date,
        "source_rank" => "#{volume}.#{rank.to_s.rjust(3, "0")}",
        "source_section" => "Norton World Literature 5e, Vol. #{volume}; TOC page #{pages}",
        "source_url" => url,
        "source_citation" => "W. W. Norton official World Literature 5e Volume #{volume} TOC PDF",
        "matched_work_id" => matched_work_id,
        "match_method" => match_method,
        "match_confidence" => match_confidence,
        "evidence_type" => evidence_type,
        "evidence_weight" => evidence_type == "boundary_context" ? "0.25" : "0.80",
        "supports" => evidence_type == "boundary_context" ? "anthology_section_or_context_heading" : "world_literature_anthology_public_toc",
        "match_status" => match_status,
        "notes" => "Official Norton World Literature 5e TOC row; no anthology text extracted. Exact title matches remain provisional until match, source-scope, and relation gates are reviewed."
      }
    else
      buffer << line
      buffer.shift while buffer.size > 3
    end
  end

  rows
end

works_by_id, title_index = build_work_indexes
rows = VOLUME_URLS.flat_map { |volume, url| extract_volume_rows(volume, url, title_index) }

volume_counts = rows.group_by { |row| row.fetch("source_rank").split(".").first }.transform_values(&:size)
EXPECTED_VOLUME_COUNTS.each do |volume, expected|
  actual = volume_counts.fetch(volume, 0)
  raise "unexpected Norton World Lit Vol. #{volume} count: expected #{expected}, got #{actual}" unless actual == expected
end

bad_matches = rows.reject { |row| row["matched_work_id"].empty? || works_by_id.key?(row["matched_work_id"]) }
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
{
  PRE1650_SOURCE_ID => "Official Norton World Literature 5e Vols. A-C TOC PDFs parsed into #{volume_counts.values_at("A", "B", "C").sum} page-indexed rows.",
  POST1650_SOURCE_ID => "Official Norton World Literature 5e Vols. D-F TOC PDFs parsed into #{volume_counts.values_at("D", "E", "F").sum} page-indexed rows."
}.each do |source_id, notes|
  raise "missing registry row for #{source_id}" unless registry_by_id[source_id]

  packet_ids = registry_by_id[source_id]["packet_ids"].to_s.split(";").reject(&:empty?)
  packet_ids << "X026" unless packet_ids.include?("X026")
  registry_by_id[source_id]["packet_ids"] = packet_ids.join(";")
  registry_by_id[source_id]["extraction_status"] = "extracted"
  registry_by_id[source_id]["coverage_limits"] = "Official TOC PDFs extracted; rows include works, selections, excerpts, author/context headings, and page-indexed components; scope must be reviewed before scoring."
  registry_by_id[source_id]["notes"] = notes
end
write_tsv(SOURCE_REGISTRY_FILE, SOURCE_REGISTRY_HEADERS, registry_by_id.values, sort_key: "source_id")

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row["packet_id"] == "X026" }
packet_rows << {
  "packet_id" => "X026",
  "packet_family" => "X",
  "scope" => "Norton World Literature 5e official TOC PDFs, Vols. A-F",
  "status" => "source_items_ingested",
  "gate" => "evidence_scope_review_required",
  "output_artifact" => "_planning/canon_build/tables/canon_source_items.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_010_x026_norton_world_lit_toc.md",
  "next_action" => "run_matching_relation_scope_evidence_then_continue_longman_bedford_world_lit",
  "notes" => "Added #{rows.size} Norton World Literature 5e official TOC rows from Vols. A-F; exact title/alias matches were linked provisionally only when unique."
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows, sort_key: "packet_id")

FileUtils.mkdir_p(REPORT_DIR)
matched_rows = rows.count { |row| !row["matched_work_id"].empty? }
report = []
report << "# X026 Norton World Literature 5e TOC Extraction"
report << ""
report << "- status: source_items_ingested_evidence_scope_review_required"
report << "- generated_rows: #{rows.size}"
report << "- provisional_unique_exact_matches: #{matched_rows}"
report << "- direct_public_path_changes: 0"
report << "- direct_evidence_rows_added_by_ingester: 0"
report << ""
report << "## Source Counts"
report << ""
report << "| Source ID | Volumes | Rows | Notes |"
report << "|---|---|---:|---|"
report << "| `#{PRE1650_SOURCE_ID}` | A-C | #{volume_counts.values_at("A", "B", "C").sum} | Official Norton TOC PDFs parsed; rows remain scope-gated. |"
report << "| `#{POST1650_SOURCE_ID}` | D-F | #{volume_counts.values_at("D", "E", "F").sum} | Official Norton TOC PDFs parsed; rows remain scope-gated. |"
report << ""
report << "## Volume Counts"
report << ""
report << "| Volume | Rows | URL |"
report << "|---|---:|---|"
VOLUME_URLS.each do |volume, url|
  report << "| #{volume} | #{volume_counts.fetch(volume)} | #{url} |"
end
report << ""
report << "## Scope Notes"
report << ""
report << "- Rows are page-indexed TOC observations only. They include complete works, excerpts, sub-selections, poems, stories, author headings, and context headings."
report << "- Unique exact title/alias matches were materialized only as provisional source-item matches. Source debt remains open until evidence and relation-scope review."
report << "- No public canon rows were added, removed, or re-ranked."
report << ""
File.write(REPORT_FILE, report.join("\n"))

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x026_norton_world_lit_toc_ingested"
manifest["artifacts"]["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_x022_x023_x024_x025_x026_source_items"
manifest["source_item_extraction_batch_x026"] = {
  "source_items_added_or_updated" => rows.size,
  "norton_world_lit_pre1650_rows" => volume_counts.values_at("A", "B", "C").sum,
  "norton_world_lit_post1650_rows" => volume_counts.values_at("D", "E", "F").sum,
  "provisional_unique_exact_matches" => matched_rows,
  "evidence_rows_added" => 0,
  "status" => "source_items_ingested_evidence_scope_review_required",
  "direct_replacements" => 0
}
manifest["current_counts"] ||= {}
manifest["current_counts"]["source_items"] = source_items_by_id.size
manifest["current_counts"]["source_registry_rows"] = registry_by_id.size
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "ingested or updated #{rows.size} X026 Norton World Literature TOC rows"
puts volume_counts.sort.map { |volume, count| "Vol. #{volume}=#{count}" }.join("\n")
puts "provisional_unique_exact_matches=#{matched_rows}"
