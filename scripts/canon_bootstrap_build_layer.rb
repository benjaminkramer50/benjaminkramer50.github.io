#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DATA_FILE = File.join(ROOT, "_data", "canon_quick_path.yml")
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
MANIFEST_FILE = File.join(BUILD_DIR, "manifests", "canon_build_manifest.yml")

WORK_HEADERS = %w[
  work_id candidate_status incumbent_path_id incumbent_rank canonical_title sort_title original_title
  creator_display date_label sort_year date_precision macro_region subregion original_language
  language_family literary_tradition period_bucket form_bucket unit_type boundary_flags
  included_as_literature boundary_policy_id boundary_note selection_basis edition_basis completion_unit
  source_status review_status confidence provisional_until notes
].freeze

CREATOR_HEADERS = %w[creator_id creator_display normalized_name name_variants life_dates culture_or_tradition notes].freeze
WORK_CREATOR_HEADERS = %w[work_id creator_id creator_role attribution_status notes].freeze
ALIAS_HEADERS = %w[alias_id work_id alias normalized_alias alias_type language script source_id confidence notes].freeze
PATH_HEADERS = %w[path_id work_id path_name selected rank selection_status replacement_transaction_id notes].freeze

def normalize(value)
  value.to_s.downcase
       .gsub(/&amp;/, " and ")
       .gsub(/[''`]/, "")
       .gsub(/[^a-z0-9]+/, " ")
       .gsub(/\b(the|a|an)\b/, " ")
       .gsub(/\s+/, " ")
       .strip
end

def stable_id(value)
  value.to_s.downcase
       .gsub(/[^a-z0-9]+/, "_")
       .gsub(/\A_+|_+\z/, "")
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

def date_precision(item)
  label = item["date_label"].to_s.downcase
  return "unknown" if item["sort_year"].nil?
  return "traditional_or_oral" if label.match?(/\b(oral|living|traditional|manuscript tradition)\b/)
  return "range" if label.match?(/\d+\s*-\s*\d+/)
  return "century" if label.include?("century")
  return "approximate_year" if label.match?(/\bc\.|circa|approx/)
  "exact_year"
end

def write_tsv(path, headers, rows)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row[header] } }
  end
end

FileUtils.mkdir_p(TABLE_DIR)
data = YAML.load_file(DATA_FILE)
items = data.fetch("items")

creator_ids = {}
creator_rows = []
work_creator_rows = []
work_rows = []
alias_rows = []
path_rows = []

items.each do |item|
  work_id = "work_#{stable_id(item.fetch("id"))}"
  creators = Array(item["creators"])
  creator_display = creators.join(" | ")

  work_rows << {
    "work_id" => work_id,
    "candidate_status" => "incumbent_current_path",
    "incumbent_path_id" => item["id"],
    "incumbent_rank" => item["rank"],
    "canonical_title" => item["title"],
    "sort_title" => normalize(item["title"]),
    "original_title" => "",
    "creator_display" => creator_display,
    "date_label" => item["date_label"],
    "sort_year" => item["sort_year"],
    "date_precision" => date_precision(item),
    "macro_region" => "taxonomy_pending",
    "subregion" => "",
    "original_language" => "",
    "language_family" => "",
    "literary_tradition" => "taxonomy_pending",
    "period_bucket" => period_bucket(item["sort_year"]),
    "form_bucket" => "taxonomy_pending",
    "unit_type" => item["unit_type"],
    "boundary_flags" => "",
    "included_as_literature" => "",
    "boundary_policy_id" => "",
    "boundary_note" => "",
    "selection_basis" => "",
    "edition_basis" => "",
    "completion_unit" => item["completion_unit"],
    "source_status" => item["source_status"],
    "review_status" => item["review_status"],
    "confidence" => "incumbent_unscored",
    "provisional_until" => "source_crosswalk_review",
    "notes" => "Bootstrapped from incumbent path; current topic=#{item["topic"]}; current group=#{item["group"]}"
  }

  creators.each do |creator|
    normalized = normalize(creator)
    creator_ids[normalized] ||= begin
      creator_id = format("creator_%05d", creator_ids.size + 1)
      creator_rows << {
        "creator_id" => creator_id,
        "creator_display" => creator,
        "normalized_name" => normalized,
        "name_variants" => "",
        "life_dates" => "",
        "culture_or_tradition" => "",
        "notes" => "Bootstrapped from incumbent path"
      }
      creator_id
    end

    work_creator_rows << {
      "work_id" => work_id,
      "creator_id" => creator_ids[normalized],
      "creator_role" => "author_or_tradition",
      "attribution_status" => "incumbent_label",
      "notes" => ""
    }
  end

  Array(item["aliases"]).each_with_index do |aliaz, index|
    alias_rows << {
      "alias_id" => format("alias_%05d", alias_rows.size + 1),
      "work_id" => work_id,
      "alias" => aliaz,
      "normalized_alias" => normalize(aliaz),
      "alias_type" => "incumbent_alias",
      "language" => "",
      "script" => "",
      "source_id" => "",
      "confidence" => "incumbent",
      "notes" => "Alias index #{index + 1} from incumbent path"
    }
  end

  path_rows << {
    "path_id" => "quick_path_3000",
    "work_id" => work_id,
    "path_name" => "global_literature_canon_quick_path",
    "selected" => "true",
    "rank" => item["rank"],
    "selection_status" => "incumbent_selected",
    "replacement_transaction_id" => "",
    "notes" => "Wave 005 incumbent path"
  }
end

write_tsv(File.join(TABLE_DIR, "canon_work_candidates.tsv"), WORK_HEADERS, work_rows)
write_tsv(File.join(TABLE_DIR, "canon_creators.tsv"), CREATOR_HEADERS, creator_rows)
write_tsv(File.join(TABLE_DIR, "canon_work_creators.tsv"), WORK_CREATOR_HEADERS, work_creator_rows)
write_tsv(File.join(TABLE_DIR, "canon_aliases.tsv"), ALIAS_HEADERS, alias_rows)
write_tsv(File.join(TABLE_DIR, "canon_path_selection.tsv"), PATH_HEADERS, path_rows)

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "incumbent_path_bootstrapped"
manifest["artifacts"]["work_candidates"] = "bootstrapped_from_current_path"
manifest["artifacts"]["creators"] = "bootstrapped_from_current_path"
manifest["artifacts"]["aliases"] = "bootstrapped_from_current_path"
manifest["artifacts"]["path_selection"] = "bootstrapped_from_current_path"
manifest["bootstrap_counts"] = {
  "work_candidates" => work_rows.size,
  "creators" => creator_rows.size,
  "work_creators" => work_creator_rows.size,
  "aliases" => alias_rows.size,
  "path_selection_rows" => path_rows.size
}
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "bootstrapped #{work_rows.size} incumbent work candidates"
puts "bootstrapped #{creator_rows.size} creators"
puts "bootstrapped #{alias_rows.size} aliases"
