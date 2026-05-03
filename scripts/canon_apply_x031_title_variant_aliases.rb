#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")
MANIFEST_DIR = File.join(BUILD_DIR, "manifests")

ALIASES_FILE = File.join(TABLE_DIR, "canon_aliases.tsv")
PACKET_STATUS_FILE = File.join(TABLE_DIR, "canon_packet_status.tsv")
MANIFEST_FILE = File.join(MANIFEST_DIR, "canon_build_manifest.yml")
REPORT_FILE = File.join(REPORT_DIR, "x_batch_015_x031_title_variant_aliases.md")

PACKET_ID = "X031"

ALIAS_HEADERS = %w[
  alias_id work_id alias normalized_alias alias_type language script source_id confidence notes
].freeze

PACKET_STATUS_HEADERS = %w[
  packet_id packet_family scope status gate output_artifact next_action notes
].freeze

ALIASES_TO_ADD = [
  ["work_candidate_bloom_fuente_ovejuna", "Fuenteovejuna"],
  ["work_candidate_eastasia_lit_song_everlasting_sorrow", "The Song of Lasting Regret"],
  ["work_candidate_eastasia_lit_song_everlasting_sorrow", "Song of Lasting Regret"],
  ["work_candidate_tale_of_heike", "Tales of Heike"],
  ["work_candidate_tale_of_heike", "The Tales of the Heike"],
  ["work_canon_ramayana", "The Ramayana of Valmiki"],
  ["work_canon_ramayana", "Ramayana of Valmiki"],
  ["work_candidate_global_lit_life_amorous_woman", "Life of a Sensuous Woman"],
  ["work_candidate_global_lit_life_amorous_woman", "The Life of a Sensuous Woman"],
  [
    "work_candidate_bloom_late_032_literature_bloom_democratic_age_reviewed_0482_christabel_kubla_khan_a_vision_in_a_dream_the_pa",
    "Kubla Khan"
  ],
  [
    "work_candidate_bloom_late_032_literature_bloom_democratic_age_reviewed_0482_christabel_kubla_khan_a_vision_in_a_dream_the_pa",
    "Kubla Khan, a Vision in a Dream"
  ]
].freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def normalize(value)
  value.to_s
       .downcase
       .gsub(/&/, " and ")
       .gsub(/[[:punct:]]+/, " ")
       .gsub(/\b(the|a|an|le|la|les|el|los|las|il|lo|gli|i|der|die|das)\b/, " ")
       .gsub(/\s+/, " ")
       .strip
end

aliases = read_tsv(ALIASES_FILE)
existing_keys = aliases.map { |row| [row.fetch("work_id"), row.fetch("normalized_alias")] }.to_set
max_alias_number = aliases.map { |row| row.fetch("alias_id").sub(/\Aalias_/, "").to_i }.max || 0
added_rows = []

ALIASES_TO_ADD.each do |work_id, title|
  normalized = normalize(title)
  next if existing_keys.include?([work_id, normalized])

  max_alias_number += 1
  row = {
    "alias_id" => "alias_#{max_alias_number.to_s.rjust(5, "0")}",
    "work_id" => work_id,
    "alias" => title,
    "normalized_alias" => normalized,
    "alias_type" => "source_title_variant",
    "language" => "",
    "script" => "",
    "source_id" => "x030_title_route_review",
    "confidence" => "reviewed",
    "notes" => "Added by X031 from X030 title-route decision; public canon unchanged."
  }
  aliases << row
  added_rows << row
  existing_keys << [work_id, normalized]
end

write_tsv(ALIASES_FILE, ALIAS_HEADERS, aliases)

packet_rows = read_tsv(PACKET_STATUS_FILE)
packet_rows.reject! { |row| row.fetch("packet_id") == PACKET_ID }
packet_rows << {
  "packet_id" => PACKET_ID,
  "packet_family" => "X",
  "scope" => "safe title-variant alias writes from X030",
  "status" => "aliases_added",
  "gate" => "matching_rerun_required",
  "output_artifact" => "_planning/canon_build/tables/canon_aliases.tsv;_planning/canon_build/source_crosswalk_reports/x_batch_015_x031_title_variant_aliases.md",
  "next_action" => "rerun_match_review_for_alias_affected_source_rows",
  "notes" => "#{added_rows.size} reviewed title-variant aliases added; public canon unchanged"
}
write_tsv(PACKET_STATUS_FILE, PACKET_STATUS_HEADERS, packet_rows.sort_by { |row| row.fetch("packet_id") })

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x031_title_variant_aliases_added"
manifest["artifacts"]["aliases"] = "bootstrapped_from_current_path_plus_x013_source_title_aliases_plus_x031"
manifest["current_counts"]["aliases"] = aliases.size
manifest["title_variant_aliases_x031"] = {
  "aliases_added" => added_rows.size,
  "direct_replacements" => 0
}
File.write(MANIFEST_FILE, manifest.to_yaml)

report = <<~MARKDOWN
  # X Batch 15 Report: X031 Title-Variant Aliases

  Date: 2026-05-03

  Status: reviewed aliases added; public canon unchanged.

  ## Summary

  X031 writes only title-variant aliases from X030 decisions where the target current-path work is clear. It does not alias ordinary poem/excerpt titles into collections, and it does not create replacement candidates.

  | Metric | Count |
  |---|---:|
  | Added aliases | #{added_rows.size} |

  ## Added Rows

  | Alias | Work ID |
  |---|---|
  #{added_rows.map { |row| "| #{row.fetch("alias")} | #{row.fetch("work_id")} |" }.join("\n")}

  ## Next Actions

  1. Rerun the match-review queue so source rows with these variants can resolve through aliases.
  2. Keep contained poem, essay, and excerpt rows in relation/scope review rather than flattening them into aliases.
MARKDOWN
File.write(REPORT_FILE, report)

puts "wrote #{ALIASES_FILE.sub(ROOT + "/", "")} (+#{added_rows.size} aliases)"
puts "wrote #{REPORT_FILE.sub(ROOT + "/", "")}"
