#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "pathname"
require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DATA_FILE = File.join(ROOT, "_data", "canon_quick_path.yml")
OUTPUT_DIR = File.join(ROOT, "_planning", "canon_audit_outputs")

FileUtils.mkdir_p(OUTPUT_DIR)

def normalize(value)
  value.to_s.downcase
       .gsub(/&amp;/, " and ")
       .gsub(/[''`]/, "")
       .gsub(/[^a-z0-9]+/, " ")
       .gsub(/\b(the|a|an)\b/, " ")
       .gsub(/\s+/, " ")
       .strip
end

def period_bucket(year)
  y = year.to_i
  return "pre_2500_bce" if y < -2500
  return "2500_1500_bce" if y < -1500
  return "1500_1000_bce" if y < -1000
  return "1000_500_bce" if y < -500
  return "500_300_bce" if y < -300
  return "300_1_bce" if y < 1
  return "1_300_ce" if y < 300
  return "300_600_ce" if y < 600
  return "600_900_ce" if y < 900
  return "900_1100_ce" if y < 1100
  return "1100_1300_ce" if y < 1300
  return "1300_1500_ce" if y < 1500
  return "1500_1600_ce" if y < 1600
  return "1600_1700_ce" if y < 1700
  return "1700_1750_ce" if y < 1750
  return "1750_1800_ce" if y < 1800
  return "1800_1830_ce" if y < 1830
  return "1830_1850_ce" if y < 1850
  return "1850_1870_ce" if y < 1870
  return "1870_1890_ce" if y < 1890
  return "1890_1900_ce" if y < 1900
  return "1900_1914_ce" if y < 1914
  return "1914_1918_ce" if y < 1919
  return "1919_1929_ce" if y < 1930
  return "1930_1939_ce" if y < 1940
  return "1939_1945_ce" if y < 1946
  return "1946_1959_ce" if y < 1960
  return "1960_1969_ce" if y < 1970
  return "1970_1979_ce" if y < 1980
  return "1980_1989_ce" if y < 1990
  return "1990_1999_ce" if y < 2000
  return "2000_2009_ce" if y < 2010
  return "2010_2019_ce" if y < 2020
  "2020_present"
end

def text_for(item)
  values = [
    item["title"],
    item["aliases"],
    item["creators"],
    item["section"],
    item["group"],
    item["topic"],
    item["medium"],
    item["unit_type"]
  ].flatten.compact
  normalize(values.join(" "))
end

def metadata_text_for(item)
  values = [
    item["creators"],
    item["section"],
    item["group"],
    item["topic"],
    item["medium"],
    item["unit_type"]
  ].flatten.compact
  normalize(values.join(" "))
end

def macro_region(item)
  text = text_for(item)
  return "oceania_arctic" if text.match?(/\b(aboriginal|maori|pacific|oceanian|polynesian|arctic|inuit|hawaiian)\b/)
  return "americas" if text.match?(/\b(american|canadian|caribbean|brazilian|maya|kiche|quechua|nahuatl|mapuche|zapotec|kichwa|mephaa|black atlantic|native|indigenous|chicano|cuban|dominican|mexican)\b/)
  return "africa" if text.match?(/\b(african|swahili|yoruba|hausa|somali|amharic|zulu|ghanaian|kenyan|horn of africa|amazigh|mande|ethiopic|geez)\b/)
  return "east_asia" if text.match?(/\b(chinese|japanese|korean|taiwanese|mongolian|tibetan|sinophone)\b/)
  return "south_asia" if text.match?(/\b(sanskrit|pali|prakrit|tamil|telugu|malayalam|bengali|hindi|urdu|punjabi|marathi|kannada|odia|assamese|nepali|sinhala|south asian|indian|jain|sikh)\b/)
  return "southeast_asia" if text.match?(/\b(thai|vietnamese|khmer|burmese|malay|indonesian|filipino|southeast asian|lao|javanese)\b/)
  return "middle_east_central_asia" if text.match?(/\b(arabic|persian|turkic|turkish|kurdish|hebrew|syriac|armenian|georgian|central asian|egyptian|mesopotamian|sumerian|akkadian|ugaritic|hittite|zoroastrian|ancient near east|islamic|hadith|aramaic)\b/)
  return "europe" if text.match?(/\b(greek|roman|latin|italian|french|francophone|spanish|portuguese|german|austrian|british|english|irish|scottish|welsh|dutch|scandinavian|norwegian|swedish|danish|icelandic|russian|polish|czech|slovak|hungarian|romanian|balkan|baltic|bulgarian|slovenian|albanian|ukrainian|europe)\b/)
  "cross_regional_or_unknown"
end

def form_bucket(item)
  text = metadata_text_for(item)
  title = normalize(item["title"])
  return "children_young_adult" if text.match?(/\b(children|childrens|young adult)\b/)
  return "graphic_visual_narrative" if text.match?(/\b(graphic|comic|comics|manga)\b/)
  return "speculative_genre" if text.match?(/\b(science fiction|fantasy|horror|weird|crime|detective|gothic|adventure|surrealist)\b/)
  return "drama_performance" if text.match?(/\b(play|drama|theater|theatre|tragedy|comedy|satyr|noh|bunraku|performance|pansori)\b/)
  return "sacred_myth_ritual" if text.match?(/\b(scripture|religion|religious|myth|mythology|ritual|funerary|liturgical|sutra|bible|qur|hadith|buddhist|hindu|jain|sikh|zoroastrian|apocalyptic)\b/)
  return "epic_oral_folk" if text.match?(/\b(epic|oral|saga|folklore|fable|fairy tale|ballad|trickster|beast)\b/) || title.start_with?("epic of ")
  return "poetry" if text.match?(/\b(poem|poems|poetry|poetic|poetics|lyric|hymn|ghazal|haiku|song|verse|ode|elegy)\b/)
  return "essays_memoir_testimony" if text.match?(/\b(memoir|autobiography|testimonio|essay|confession|diary|travel|chronicle|history|dialogue|wisdom|letters?|epistolary|epistle|oratory|rhetoric|grammar|philosophy|philosophical|prose)\b/)
  "fiction_narrative_prose"
end

def boundary_flags(item)
  text = text_for(item)
  metadata_text = metadata_text_for(item)
  flags = []
  flags << "sacred_religious" if text.match?(/\b(scripture|religion|religious|sutra|bible|qur|hadith|theology|hindu|buddhist|jain|sikh|zoroastrian)\b/)
  flags << "oral_tradition" if metadata_text.match?(/\b(oral|folklore|trickster|public accounts|chant)\b/)
  flags << "myth_ritual" if text.match?(/\b(myth|mythology|ritual|funerary|liturgical)\b/)
  flags << "philosophy_adjacent" if text.match?(/\b(philosophy|philosophical|dialogue|wisdom|analects|dao|poetics)\b/)
  flags << "history_chronicle" if text.match?(/\b(history|histories|chronicle|annals|records|travels)\b/)
  flags << "memoir_testimony" if text.match?(/\b(memoir|autobiography|testimonio|confession|diary|narrative of|incidents in the life)\b/)
  flags << "children_ya" if text.match?(/\b(children|childrens|young adult)\b/)
  flags << "graphic" if text.match?(/\b(graphic|comic|comics|manga)\b/)
  flags << "genre_fiction" if text.match?(/\b(science fiction|fantasy|horror|weird|crime|detective|gothic|adventure)\b/)
  flags
end

def generic_title?(item)
  title = item["title"].to_s
  unit = item["unit_type"].to_s
  title.match?(/\A(Selected|Collected|Complete|Poems|Stories|Tales|Sonnets|Odes|Epigrams|Hymns)\b/i) ||
    unit.match?(/\A(poetry_selection|short_story_collection|story_collection)\z/)
end

def write_tsv(path, rows, headers)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |key| row[key] } }
  end
end

data = YAML.load_file(DATA_FILE)
items = data.fetch("items")
inventory = items.map do |item|
  title = item["title"].to_s
  creators = Array(item["creators"])
  aliases = Array(item["aliases"])
  flags = boundary_flags(item)
  {
    "id" => item["id"],
    "rank" => item["rank"],
    "phase" => item["phase"],
    "title" => title,
    "aliases" => aliases.join(" | "),
    "creators" => creators.join(" | "),
    "date_label" => item["date_label"],
    "sort_year" => item["sort_year"],
    "period_bucket" => period_bucket(item["sort_year"]),
    "macro_region" => macro_region(item),
    "form_bucket" => form_bucket(item),
    "section" => item["section"],
    "group" => item["group"],
    "topic" => item["topic"],
    "medium" => item["medium"],
    "unit_type" => item["unit_type"],
    "tier" => item["tier"],
    "pool" => item["pool"],
    "source" => item["source"],
    "source_id" => item["source_id"],
    "source_status" => item["source_status"],
    "review_status" => item["review_status"],
    "progress_status" => item["progress_status"],
    "lifetime_path" => item["lifetime_path"],
    "url" => item["url"],
    "normalized_title" => normalize(title),
    "normalized_creators" => normalize(creators.join(" ")),
    "boundary_flags" => flags.join("|"),
    "generic_title" => generic_title?(item) ? "true" : "false"
  }
end

inventory_headers = %w[
  id rank phase title aliases creators date_label sort_year period_bucket macro_region form_bucket
  section group topic medium unit_type tier pool source source_id source_status review_status
  progress_status lifetime_path url normalized_title normalized_creators boundary_flags generic_title
]
write_tsv(File.join(OUTPUT_DIR, "canon_inventory.tsv"), inventory, inventory_headers)

%w[period_bucket macro_region form_bucket tier source_status review_status topic unit_type].each do |field|
  counts = inventory.each_with_object(Hash.new(0)) { |row, hash| hash[row[field].to_s] += 1 }
  rows = counts.sort_by { |key, count| [-count, key] }.map { |key, count| { "bucket" => key, "count" => count } }
  write_tsv(File.join(OUTPUT_DIR, "canon_inventory_by_#{field}.tsv"), rows, %w[bucket count])
end

title_index = Hash.new { |hash, key| hash[key] = [] }
inventory.each_with_index do |row, index|
  source_item = items[index]
  ([source_item["title"]] + Array(source_item["aliases"])).compact.each do |value|
    key = normalize(value)
    title_index[key] << row unless key.empty?
  end
end

duplicate_rows = title_index.each_with_object([]) do |(key, rows), out|
  unique_ids = rows.map { |row| row["id"] }.uniq
  next unless unique_ids.size > 1

  out << {
    "match_key" => key,
    "count" => unique_ids.size,
    "ids" => rows.map { |row| row["id"] }.uniq.join(" | "),
    "ranks" => rows.map { |row| row["rank"] }.uniq.join(" | "),
    "titles" => rows.map { |row| row["title"] }.uniq.join(" | "),
    "creators" => rows.map { |row| row["creators"] }.uniq.join(" | ")
  }
end.sort_by { |row| [-row["count"].to_i, row["match_key"]] }
write_tsv(File.join(OUTPUT_DIR, "canon_duplicate_candidates.tsv"), duplicate_rows, %w[match_key count ids ranks titles creators])

generic_rows = inventory.select { |row| row["generic_title"] == "true" }
write_tsv(File.join(OUTPUT_DIR, "canon_generic_titles.tsv"), generic_rows, inventory_headers)

boundary_rows = inventory.reject { |row| row["boundary_flags"].to_s.empty? }
write_tsv(File.join(OUTPUT_DIR, "canon_boundary_cases.tsv"), boundary_rows, inventory_headers)

source_debt_rows = inventory.select do |row|
  row["source_status"].to_s == "manual_only" || row["review_status"].to_s == "needs_sources"
end
write_tsv(File.join(OUTPUT_DIR, "canon_source_debt.tsv"), source_debt_rows, inventory_headers)

ids = inventory.map { |row| row["id"] }
ranks = inventory.map { |row| row["rank"].to_i }
missing_required = inventory.select do |row|
  %w[id title sort_year rank section group topic medium unit_type tier].any? { |field| row[field].to_s.strip.empty? }
end
rank_gaps = ((1..inventory.size).to_a - ranks).sort
duplicate_ids = ids.group_by(&:itself).select { |_key, values| values.size > 1 }
duplicate_ranks = ranks.group_by(&:itself).select { |_key, values| values.size > 1 }
future_years = inventory.select { |row| row["sort_year"].to_i > 2026 }
placeholder_dates = inventory.select { |row| row["date_label"].to_s.match?(/pending review|approximate chronological placement/i) }

summary = {
  "generated_on" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  "items" => inventory.size,
  "target_count" => data["target_count"],
  "duplicate_ids" => duplicate_ids.size,
  "duplicate_ranks" => duplicate_ranks.size,
  "rank_gaps" => rank_gaps.size,
  "missing_required_rows" => missing_required.size,
  "future_year_rows" => future_years.size,
  "placeholder_date_rows" => placeholder_dates.size,
  "duplicate_candidate_keys" => duplicate_rows.size,
  "generic_title_rows" => generic_rows.size,
  "boundary_case_rows" => boundary_rows.size,
  "source_debt_rows" => source_debt_rows.size,
  "manual_only_rows" => inventory.count { |row| row["source_status"].to_s == "manual_only" },
  "needs_sources_rows" => inventory.count { |row| row["review_status"].to_s == "needs_sources" }
}

File.write(File.join(OUTPUT_DIR, "canon_audit_summary.yml"), summary.to_yaml)

control_checks = [
  ["A001", "YAML schema and required fields", missing_required.empty? ? "PASS" : "FAIL", "#{missing_required.size} rows missing required fields"],
  ["A002", "Rank uniqueness, continuity, lifetime leakage", duplicate_ranks.empty? && rank_gaps.empty? ? "PASS" : "FAIL", "#{duplicate_ranks.size} duplicate rank values; #{rank_gaps.size} rank gaps"],
  ["A003", "ID uniqueness and stable naming", duplicate_ids.empty? ? "PASS" : "FAIL", "#{duplicate_ids.size} duplicate ID values"],
  ["A004", "Title normalization and article stripping", duplicate_rows.empty? ? "PASS" : "WARN", "#{duplicate_rows.size} normalized duplicate/alias candidate keys"],
  ["A005", "Creator normalization and traditional labels", "WARN", "#{inventory.count { |row| row["normalized_creators"].empty? }} rows have empty creators; traditional labels still need review"],
  ["A006", "Alias coverage for translated titles and spellings", "WARN", "#{inventory.count { |row| row["aliases"].to_s.empty? }} rows have no aliases"],
  ["A007", "Collection-contained title matching", "WARN", "Requires packet-specific source review; duplicate alias index generated"],
  ["A008", "Series versus volume duplicate policy", "WARN", "Requires policy review; duplicate alias index generated"],
  ["A009", "Generic Selected Poems audit", generic_rows.empty? ? "PASS" : "WARN", "#{generic_rows.count { |row| row["title"].to_s.match?(/selected poems|poems/i) }} poem/selected rows need selection basis review"],
  ["A010", "Generic Selected Stories audit", generic_rows.empty? ? "PASS" : "WARN", "#{generic_rows.count { |row| row["title"].to_s.match?(/selected stories|stories|tales/i) }} story/tale selection rows need review"],
  ["A011", "Generic anthology and selection-basis audit", generic_rows.empty? ? "PASS" : "WARN", "#{generic_rows.size} generic/selection rows total"],
  ["A012", "Placeholder date and approximate chronology audit", placeholder_dates.empty? ? "PASS" : "WARN", "#{placeholder_dates.size} rows have approximate/pending date labels"],
  ["A013", "Future-date and ongoing-series audit", future_years.empty? ? "PASS" : "FAIL", "#{future_years.size} rows sort after 2026"],
  ["A014", "Source-status debt audit", summary["manual_only_rows"].zero? ? "PASS" : "WARN", "#{summary["manual_only_rows"]} manual_only rows"],
  ["A015", "Review-status debt audit", summary["needs_sources_rows"].zero? ? "PASS" : "WARN", "#{summary["needs_sources_rows"]} needs_sources rows"],
  ["A016", "Tier drift audit", "WARN", inventory.group_by { |row| row["tier"] }.map { |k, v| "#{k}=#{v.size}" }.join(", ")],
  ["A017", "Completion-unit audit by form", "WARN", "Requires semantic review by form; inventory emitted"],
  ["A018", "Public UI category audit", "WARN", "Presentation categories are generated; scholarly metadata still missing"],
  ["A019", "Admin progress preservation audit", "PASS", "No progress edits performed by harness"],
  ["A020", "Search discoverability audit", "WARN", "Alias/search fields emitted; sentinel packets must test false negatives"],
  ["A021", "Duplicate candidate audit by title only", duplicate_rows.empty? ? "PASS" : "WARN", "#{duplicate_rows.size} candidate keys"],
  ["A022", "Duplicate candidate audit by title plus creator", "WARN", "Needs second-stage review; raw duplicate report emitted"],
  ["A023", "Duplicate candidate audit by alias", duplicate_rows.empty? ? "PASS" : "WARN", "#{duplicate_rows.size} alias/title candidate keys"],
  ["A024", "Duplicate candidate audit by translated/original title", "WARN", "Depends on fuller alias metadata"],
  ["A025", "Boundary-note missingness audit", boundary_rows.empty? ? "PASS" : "WARN", "#{boundary_rows.size} boundary-sensitive rows need explicit notes"],
  ["A026", "Region/language metadata missingness audit", "WARN", "Macro region inferred, not authoritative; language metadata not yet first-class"],
  ["A027", "Count cap and replacement-log audit", inventory.size == data["target_count"].to_i ? "PASS" : "FAIL", "items=#{inventory.size}; target=#{data["target_count"]}"],
  ["A028", "Reproducible build and generated-file hygiene", "WARN", "Harness ran; Jekyll build not run by this script"]
]

control_md = +"# Control Packets A001-A028\n\n"
control_md << "Generated: #{summary["generated_on"]}\n\n"
control_md << "| Packet | Status | Check | Observed |\n"
control_md << "|---|---:|---|---|\n"
control_checks.each do |packet, label, status, observed|
  control_md << "| #{packet} | #{status} | #{label} | #{observed.to_s.gsub("|", "\\|")} |\n"
end
File.write(File.join(OUTPUT_DIR, "control_packets_A001_A028.md"), control_md)

report = +"# Canon Validation Report\n\n"
report << "Generated: #{summary["generated_on"]}\n\n"
summary.each do |key, value|
  report << "- #{key}: #{value}\n"
end
report << "\n## Output Files\n\n"
Dir[File.join(OUTPUT_DIR, "*")].sort.each do |path|
  report << "- `#{Pathname.new(path).relative_path_from(Pathname.new(ROOT))}`\n"
end
File.write(File.join(OUTPUT_DIR, "canon_validation_report.md"), report)

def write_yaml_if_absent(path, payload)
  return if File.exist?(path)

  File.write(path, payload.to_yaml)
end

write_yaml_if_absent(
  File.join(OUTPUT_DIR, "canon_omission_queue.yml"),
  {
    "generated_on" => summary["generated_on"],
    "status" => "initialized_no_agent_findings_integrated",
    "items" => []
  }
)
write_yaml_if_absent(
  File.join(OUTPUT_DIR, "canon_replacement_log.yml"),
  { "generated_on" => summary["generated_on"], "items" => [] }
)

puts "Wrote audit outputs to #{OUTPUT_DIR}"
puts summary.to_yaml
