#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "date"
require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DATA_FILE = File.join(ROOT, "_data", "canon_quick_path.yml")
CANON_DIR = File.join(ROOT, "_canon")
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
MANIFEST_FILE = File.join(BUILD_DIR, "manifests", "canon_build_manifest.yml")

SOURCE_REGISTRY_HEADERS = %w[
  source_id source_title source_type source_scope source_date source_citation edition editors_or_authors
  publisher coverage_limits extraction_method packet_ids extraction_status notes
].freeze

SOURCE_ITEM_HEADERS = %w[
  source_id source_item_id raw_title raw_creator raw_date source_rank source_section source_url
  source_citation matched_work_id match_method match_confidence evidence_type evidence_weight supports
  match_status notes
].freeze

EVIDENCE_HEADERS = %w[
  evidence_id work_id source_id source_item_id evidence_type evidence_strength page_or_section quote_or_note
  packet_id supports_tier supports_boundary_policy_id reviewer_status notes
].freeze

def stable_id(value)
  value.to_s.downcase
       .gsub(/[^a-z0-9]+/, "_")
       .gsub(/\A_+|_+\z/, "")
end

def clean(value)
  Array(value).join(" | ").to_s.gsub(/\s+/, " ").strip
end

def write_tsv(path, headers, rows)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |header| row[header] } }
  end
end

def front_matter(path)
  raw = File.read(path)
  yaml = raw[/\A---\n(.*?)\n---/m, 1]
  raise "Missing front matter in #{path}" unless yaml

  YAML.safe_load(yaml, permitted_classes: [Date], aliases: true)
end

registry_rows = [
  {
    "source_id" => "e001_local_accepted_canon_records",
    "source_title" => "Accepted _canon records, Wave 005 baseline",
    "source_type" => "accepted_site_record",
    "source_scope" => "Local accepted site records in _canon/*.md",
    "source_date" => "2026-05-03",
    "source_citation" => "Local repository snapshot at commit 64600ddb264839d57a173438490f36eeed4c31b3; _canon/*.md",
    "edition" => "Wave 005 baseline",
    "editors_or_authors" => "Codex/local accepted records",
    "publisher" => "benjaminkramer50.github.io",
    "coverage_limits" => "Internal accepted records only; not an external canon source; embedded evidence remains separate source debt",
    "extraction_method" => "Parse front matter where canon_review.status starts with accepted and match canon_id to incumbent path IDs",
    "packet_ids" => "E001",
    "extraction_status" => "extracted",
    "notes" => "61 accepted records matched to incumbent path"
  },
  {
    "source_id" => "bloom_curated_seed_layer",
    "source_title" => "Harold Bloom curated seed layer",
    "source_type" => "legacy_canon_list",
    "source_scope" => "Western literature seed layer used as one evidence layer only",
    "source_date" => "2026-05-02 local audit freeze",
    "source_citation" => "Local audit narrative reports 200/200 Bloom seed matches; machine-readable seed list not present",
    "edition" => "local audit artifact",
    "editors_or_authors" => "Harold Bloom / project-curated extraction",
    "publisher" => "unknown",
    "coverage_limits" => "Western-weighted; not global; not sufficient as sole support",
    "extraction_method" => "Recover or reconstruct 200 seed rows, then match against current path",
    "packet_ids" => "E002",
    "extraction_status" => "not_started",
    "notes" => "Blocked pending machine-readable seed list"
  },
  {
    "source_id" => "bloom_full_appendix_1994",
    "source_title" => "The Western Canon full appendix",
    "source_type" => "legacy_canon_list",
    "source_scope" => "Western canon appendix cleanup layer",
    "source_date" => "1994",
    "source_citation" => "Harold Bloom, The Western Canon: The Books and School of the Ages, appendix; edition/publisher not locally captured",
    "edition" => "unknown",
    "editors_or_authors" => "Harold Bloom",
    "publisher" => "unknown",
    "coverage_limits" => "Western-heavy legacy canon list; not global; cannot be sole support for locked inclusion",
    "extraction_method" => "Local raw appendix extraction plus current-path matching",
    "packet_ids" => "E003",
    "extraction_status" => "not_started",
    "notes" => "Raw import artifact absent from repo"
  },
  {
    "source_id" => "bloom_full_appendix_review_batches",
    "source_title" => "Local Bloom appendix review batches",
    "source_type" => "packet_audit_output",
    "source_scope" => "Local reviewed/staged Bloom decisions",
    "source_date" => "2026-05-02",
    "source_citation" => "_planning/canon_literature_audit_2026_05_02.md",
    "edition" => "local audit output",
    "editors_or_authors" => "local canon audit",
    "publisher" => "local",
    "coverage_limits" => "Derived review layer, not an external source",
    "extraction_method" => "Decision reconciliation after raw/reviewed Bloom tables are recovered",
    "packet_ids" => "E003",
    "extraction_status" => "not_started",
    "notes" => "Underlying reviewed table absent; only summary counts available"
  },
  {
    "source_id" => "norton_world_lit_5e_full_pre1650",
    "source_title" => "The Norton Anthology of World Literature, 5th ed., Full Edition, Beginnings to 1650",
    "source_type" => "world_literature_anthology",
    "source_scope" => "Ancient to 1650; volumes A-C",
    "source_date" => "2024",
    "source_citation" => "Norton official anthology pages; package/TOC pages confirm edition and volume structure",
    "edition" => "5th ed., Vols. A-C",
    "editors_or_authors" => "Martin Puchner and coeditors",
    "publisher" => "W. W. Norton",
    "coverage_limits" => "Public Norton pages confirm package but not complete line-item TOC",
    "extraction_method" => "Extract verified public catalog/ebook/physical-copy TOC line items; match by title, creator, alias, and contained work",
    "packet_ids" => "E004",
    "extraction_status" => "in_progress",
    "notes" => "Requires complete TOC access before exhaustive source_items can be claimed"
  },
  {
    "source_id" => "norton_world_lit_5e_full_post1650",
    "source_title" => "The Norton Anthology of World Literature, 5th ed., Full Edition, 1650 to Present",
    "source_type" => "world_literature_anthology",
    "source_scope" => "1650 to present; volumes D-F",
    "source_date" => "2024",
    "source_citation" => "Norton official anthology pages; pricing/package pages confirm post-1650 volumes",
    "edition" => "5th ed., Vols. D-F",
    "editors_or_authors" => "Martin Puchner and coeditors",
    "publisher" => "W. W. Norton",
    "coverage_limits" => "Public line-item TOC not fully exposed",
    "extraction_method" => "Extract verified public catalog/ebook/physical-copy TOC line items; match by title, creator, alias, and contained work",
    "packet_ids" => "E004",
    "extraction_status" => "in_progress",
    "notes" => "Use shorter edition only as derivative after full edition is registered"
  },
  {
    "source_id" => "longman_world_lit_2e_2009",
    "source_title" => "The Longman Anthology of World Literature",
    "source_type" => "world_literature_anthology",
    "source_scope" => "Six-volume world literature anthology, ancient world through twentieth century",
    "source_date" => "2009",
    "source_citation" => "Pearson/Longman second edition; WorldCat OCLC 224444059",
    "edition" => "2nd ed.",
    "editors_or_authors" => "David Damrosch; David L. Pike; April Alliston; Marshall Brown; Sabry Hafez; Djelal Kadir; Sheldon Pollock; Bruce Robbins; Haruo Shirane; Jane Tylus; Pauline Yu",
    "publisher" => "Pearson/Longman",
    "coverage_limits" => "Public TOCs are uneven and sometimes retailer-derived; many items are excerpts or selections",
    "extraction_method" => "Extract public TOC metadata only; encode complete/excerpt/selection/context status; match against current path",
    "packet_ids" => "E005",
    "extraction_status" => "in_progress",
    "notes" => "Strong anthology source layer, not decisive alone"
  },
  {
    "source_id" => "bedford_world_lit_compact_v1_2009",
    "source_title" => "The Bedford Anthology of World Literature, Compact Edition, Volume 1: The Ancient, Medieval, and Early Modern World",
    "source_type" => "world_literature_anthology",
    "source_scope" => "Beginnings to 1650",
    "source_date" => "2009",
    "source_citation" => "Davis, Paul; Gary Harrison; David M. Johnson; John F. Crawford. Bedford/St. Martin's, 2009. ISBN 9780312441531",
    "edition" => "Compact ed., Vol. 1",
    "editors_or_authors" => "Paul Davis; Gary Harrison; David M. Johnson; John F. Crawford",
    "publisher" => "Bedford/St. Martin's",
    "coverage_limits" => "Public TOC fragment only; not complete enough for full extraction from web alone",
    "extraction_method" => "Extract public TOC anchors; match against current path; mark inaccessible remainder unresolved",
    "packet_ids" => "E006",
    "extraction_status" => "in_progress",
    "notes" => "Primary Bedford layer, partial public TOC"
  },
  {
    "source_id" => "bedford_world_lit_compact_v2_2008",
    "source_title" => "The Bedford Anthology of World Literature, Compact Edition, Volume 2: The Modern World",
    "source_type" => "world_literature_anthology",
    "source_scope" => "1650 to present",
    "source_date" => "2008",
    "source_citation" => "Davis, Paul; Gary Harrison; David M. Johnson; John F. Crawford. Bedford/St. Martin's, 2008. ISBN 9780312441548",
    "edition" => "Compact ed., Vol. 2",
    "editors_or_authors" => "Paul Davis; Gary Harrison; David M. Johnson; John F. Crawford",
    "publisher" => "Bedford/St. Martin's",
    "coverage_limits" => "Public TOC fragment only; not complete enough for full extraction from web alone",
    "extraction_method" => "Extract public TOC anchors; match against current path; mark inaccessible remainder unresolved",
    "packet_ids" => "E006",
    "extraction_status" => "in_progress",
    "notes" => "Primary Bedford modern layer, partial public TOC"
  }
]

data = YAML.load_file(DATA_FILE)
items_by_id = data.fetch("items").to_h { |item| [item.fetch("id"), item] }

source_item_rows = []
evidence_rows = []

Dir[File.join(CANON_DIR, "*.md")].sort.each do |path|
  metadata = front_matter(path)
  review = metadata.fetch("canon_review", {})
  next unless review.fetch("status", "").to_s.start_with?("accepted")

  canon_id = metadata.fetch("canon_id")
  path_id = "canon:#{canon_id}"
  item = items_by_id.fetch(path_id)
  work_id = "work_#{stable_id(path_id)}"
  source_item_id = "e001_accept_#{stable_id(canon_id)}"
  relative_path = path.sub("#{ROOT}/", "")
  evidence_count = Array(metadata["evidence"]).size
  creators = Array(metadata["creators"]).map { |creator| creator.is_a?(Hash) ? creator["name"] : creator }

  source_item_rows << {
    "source_id" => "e001_local_accepted_canon_records",
    "source_item_id" => source_item_id,
    "raw_title" => clean(metadata["title"]),
    "raw_creator" => clean(creators),
    "raw_date" => clean(metadata.dig("work_date", "label")),
    "source_rank" => clean(metadata.dig("path_membership", "lifetime_rank")),
    "source_section" => relative_path,
    "source_url" => "",
    "source_citation" => "Local _canon accepted record",
    "matched_work_id" => work_id,
    "match_method" => "exact_incumbent_path_id",
    "match_confidence" => "1.00",
    "evidence_type" => "inclusion",
    "evidence_weight" => "1.00",
    "supports" => "accepted_site_record",
    "match_status" => "matched_current_path",
    "notes" => "current_path_rank=#{item["rank"]}; embedded_evidence_count=#{evidence_count}; internal layer only"
  }

  evidence_rows << {
    "evidence_id" => "e001_ev_#{stable_id(canon_id)}",
    "work_id" => work_id,
    "source_id" => "e001_local_accepted_canon_records",
    "source_item_id" => source_item_id,
    "evidence_type" => "inclusion",
    "evidence_strength" => "moderate",
    "page_or_section" => "#{relative_path}:canon_review",
    "quote_or_note" => "",
    "packet_id" => "E001",
    "supports_tier" => clean(review["tier"]),
    "supports_boundary_policy_id" => "",
    "reviewer_status" => "accepted",
    "notes" => "Internal accepted record; embedded evidence count=#{evidence_count}; does not close external source debt by itself"
  }
end

write_tsv(File.join(TABLE_DIR, "canon_source_registry.tsv"), SOURCE_REGISTRY_HEADERS, registry_rows)
write_tsv(File.join(TABLE_DIR, "canon_source_items.tsv"), SOURCE_ITEM_HEADERS, source_item_rows)
write_tsv(File.join(TABLE_DIR, "canon_evidence.tsv"), EVIDENCE_HEADERS, evidence_rows)

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_crosswalk_batch_e001_e006_registered"
manifest["artifacts"]["source_registry"] = "e001_e006_registered"
manifest["artifacts"]["source_items"] = "e001_accepted_records_ingested"
manifest["artifacts"]["evidence"] = "e001_accepted_records_ingested"
manifest["source_crosswalk_batch_e001_e006"] = {
  "source_registry_rows" => registry_rows.size,
  "e001_source_items" => source_item_rows.size,
  "e001_evidence_rows" => evidence_rows.size,
  "e002_status" => "blocked_missing_bloom_seed_table",
  "e003_status" => "blocked_missing_bloom_raw_and_review_tables",
  "e004_status" => "registered_needs_complete_norton_toc_extraction",
  "e005_status" => "registered_needs_longman_toc_extraction",
  "e006_status" => "registered_partial_bedford_public_toc"
}
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "registered #{registry_rows.size} source layers"
puts "ingested #{source_item_rows.size} E001 source items"
puts "ingested #{evidence_rows.size} E001 evidence rows"
