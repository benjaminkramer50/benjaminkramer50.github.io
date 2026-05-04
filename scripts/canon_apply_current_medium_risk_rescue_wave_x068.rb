#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REPORT_DIR = File.join(BUILD_DIR, "source_crosswalk_reports")

PACKET_ID = "X068"
MAX_BATCHES = 20

WORK_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_work_candidates.tsv")
SOURCE_ITEMS_PATH = File.join(TABLE_DIR, "canon_source_items.tsv")
EVIDENCE_PATH = File.join(TABLE_DIR, "canon_evidence.tsv")
SCOPE_REVIEW_PATH = File.join(TABLE_DIR, "canon_current_rescue_scope_review.tsv")
APPLIED_PATH = File.join(TABLE_DIR, "canon_current_medium_risk_rescue_evidence_applied.tsv")
REPORT_PATH = File.join(REPORT_DIR, "x_batch_052_x068_current_medium_risk_rescue_wave_apply.md")

HEADERS = %w[
  applied_id scope_review_id evidence_id work_id source_id source_item_id raw_title raw_creator
  source_item_action evidence_action evidence_type evidence_strength reviewer_status
  source_debt_effect next_action
].freeze

DOWNSTREAM_SCRIPTS = %w[
  scripts/canon_report_source_debt_status.rb
  scripts/canon_generate_scoring_inputs.rb
  scripts/canon_generate_scores.rb
  scripts/canon_generate_cut_candidates.rb
  scripts/canon_generate_replacement_pairings.rb
  scripts/canon_generate_pair_review_queue.rb
  scripts/canon_generate_cut_review_work_orders.rb
  scripts/canon_generate_generic_selection_basis_review.rb
  scripts/canon_generate_cut_side_post_x058_action_queue.rb
  scripts/canon_generate_current_rescue_scope_refresh_x065.rb
  scripts/canon_generate_high_risk_rescue_residue_x063.rb
  scripts/canon_report_source_item_progress.rb
].freeze

NOTE = "X068 linked for reviewed representative-selection evidence; not complete-work support or cut approval."

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def tsv_headers(path)
  CSV.open(path, col_sep: "\t", &:readline)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def append_note(existing, note)
  return existing if existing.to_s.include?(note)
  return note if existing.to_s.empty?

  "#{existing} #{note}"
end

def safe_id(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
end

def evidence_strength(source_id)
  return "moderate" if source_id.include?("oxford") || source_id.include?("fsg")
  return "moderate" if source_id.include?("longman") || source_id.include?("norton")
  return "moderate" if source_id.include?("penguin")

  "weak"
end

def current_medium_scope_rows
  read_tsv(SCOPE_REVIEW_PATH).select do |row|
    row.fetch("scope_risk") == "medium" &&
      row.fetch("evidence_generation_gate") == "manual_scope_acceptance_required_before_representative_selection_evidence"
  end
end

def packet_applied_rows
  return [] unless File.exist?(APPLIED_PATH)

  read_tsv(APPLIED_PATH).select { |row| row.fetch("applied_id").start_with?("x068_") }
end

def refresh_downstream!
  DOWNSTREAM_SCRIPTS.each do |script|
    ok = system("ruby", File.join(ROOT, script))
    raise "Downstream refresh failed at #{script}" unless ok
  end
end

def apply_scope_rows(scope_rows, batch_index, applied_offset)
  works_by_id = read_tsv(WORK_CANDIDATES_PATH).to_h { |row| [row.fetch("work_id"), row] }
  source_items = read_tsv(SOURCE_ITEMS_PATH)
  source_items_by_id = source_items.to_h { |row| [row.fetch("source_item_id"), row] }
  evidence_rows = read_tsv(EVIDENCE_PATH)
  evidence_by_work_item = evidence_rows.to_h { |row| [[row.fetch("work_id"), row.fetch("source_item_id")], row] }
  evidence_ids = evidence_rows.map { |row| row.fetch("evidence_id") }.to_h { |id| [id, true] }

  applied_rows = []

  scope_rows.each.with_index(1) do |scope, index|
    work_id = scope.fetch("cut_work_id")
    source_item_id = scope.fetch("source_item_id")
    source_item = source_items_by_id.fetch(source_item_id)
    work = works_by_id.fetch(work_id)

    existing_match = source_item.fetch("matched_work_id").to_s
    unless existing_match.empty? || existing_match == work_id
      raise "Refusing to reassign #{source_item_id} from #{existing_match} to #{work_id}"
    end

    source_item_action = source_item.fetch("match_status") == "represented_by_selection" ? "represented_by_selection_confirmed" : "represented_by_selection_after_apply"
    source_item["matched_work_id"] = work_id
    source_item["match_method"] = "x068_current_rescue_scope_review_representative_selection_wave"
    source_item["match_confidence"] = "0.88"
    source_item["match_status"] = "represented_by_selection"
    source_item["notes"] = append_note(source_item["notes"], NOTE)

    existing_evidence = evidence_by_work_item[[work_id, source_item_id]]
    evidence_id = existing_evidence ? existing_evidence.fetch("evidence_id") : "x068_ev_#{safe_id(source_item_id)}"
    raise "Evidence ID collision: #{evidence_id}" if !existing_evidence && evidence_ids[evidence_id]

    unless existing_evidence
      evidence_rows << {
        "evidence_id" => evidence_id,
        "work_id" => work_id,
        "source_id" => scope.fetch("source_id"),
        "source_item_id" => source_item_id,
        "evidence_type" => "representative_selection",
        "evidence_strength" => evidence_strength(scope.fetch("source_id")),
        "page_or_section" => "source item: #{scope.fetch("raw_title")}",
        "quote_or_note" => "",
        "packet_id" => PACKET_ID,
        "supports_tier" => "",
        "supports_boundary_policy_id" => work.fetch("boundary_policy_id"),
        "reviewer_status" => "accepted",
        "notes" => "Applied from current medium-risk wave refresh. Representative-selection evidence only; does not establish complete-work support or approve cuts."
      }
      evidence_ids[evidence_id] = true
      evidence_by_work_item[[work_id, source_item_id]] = evidence_rows.last
    end

    applied_index = applied_offset + index
    applied_rows << {
      "applied_id" => "x068_medium_risk_apply_#{applied_index.to_s.rjust(4, "0")}",
      "scope_review_id" => "x068_scope_snapshot_b#{batch_index.to_s.rjust(2, "0")}_#{safe_id(source_item_id)}",
      "evidence_id" => evidence_id,
      "work_id" => work_id,
      "source_id" => scope.fetch("source_id"),
      "source_item_id" => source_item_id,
      "raw_title" => scope.fetch("raw_title"),
      "raw_creator" => scope.fetch("raw_creator"),
      "source_item_action" => source_item_action,
      "evidence_action" => "evidence_present_after_apply",
      "evidence_type" => "representative_selection",
      "evidence_strength" => evidence_strength(scope.fetch("source_id")),
      "reviewer_status" => "accepted",
      "source_debt_effect" => "does_not_close_complete_work_source_debt",
      "next_action" => "refresh_source_debt_scoring_and_current_cut_side_action_queue"
    }
  end

  existing_applied_rows = File.exist?(APPLIED_PATH) ? read_tsv(APPLIED_PATH) : []
  write_tsv(SOURCE_ITEMS_PATH, tsv_headers(SOURCE_ITEMS_PATH), source_items)
  write_tsv(EVIDENCE_PATH, tsv_headers(EVIDENCE_PATH), evidence_rows)
  write_tsv(APPLIED_PATH, HEADERS, existing_applied_rows + applied_rows)

  applied_rows
end

def write_report(rows, status)
  FileUtils.mkdir_p(File.dirname(REPORT_PATH))
  action_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("evidence_action")] += 1 }
  work_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("work_id")] += 1 }
  creator_counts = rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("raw_creator")] += 1 }
  current_medium = current_medium_scope_rows

  File.open(REPORT_PATH, "w") do |file|
    file.puts "# X068 Current Medium-Risk Rescue Wave Apply"
    file.puts
    file.puts "Status: #{status}, build-layer only. Public canon path unchanged."
    file.puts
    file.puts "## Purpose"
    file.puts
    file.puts "X068 repeatedly applies current medium-risk representative-selection rescue rows, refreshing after each cluster. The wave accepts only selection-level support and does not establish complete-work support."
    file.puts
    file.puts "## Output"
    file.puts
    file.puts "- Added `scripts/canon_apply_current_medium_risk_rescue_wave_x068.rb`."
    file.puts "- Appended X068 rows to `canon_current_medium_risk_rescue_evidence_applied.tsv`."
    file.puts "- Confirmed #{rows.size} X068 representative-selection evidence rows present after apply."
    file.puts
    file.puts "Evidence action summary:"
    file.puts
    file.puts "| Action | Rows |"
    file.puts "|---|---:|"
    action_counts.sort.each { |action, count| file.puts "| `#{action}` | #{count} |" }
    file.puts
    file.puts "Work summary:"
    file.puts
    file.puts "| Work | Rows |"
    file.puts "|---|---:|"
    work_counts.sort.each { |work_id, count| file.puts "| `#{work_id}` | #{count} |" }
    file.puts
    file.puts "Creator summary:"
    file.puts
    file.puts "| Creator | Rows |"
    file.puts "|---|---:|"
    creator_counts.sort.each { |creator, count| file.puts "| #{creator} | #{count} |" }
    file.puts
    file.puts "Current medium-risk rows remaining after refresh: #{current_medium.size}."
    unless current_medium.empty?
      file.puts
      file.puts "Next surfaced medium-risk works:"
      file.puts
      file.puts "| Work | Rows |"
      file.puts "|---|---:|"
      current_medium.group_by { |row| row.fetch("cut_work_id") }.sort.each do |work_id, grouped|
        file.puts "| `#{work_id}` | #{grouped.size} |"
      end
    end
    file.puts
    file.puts "## Interpretation"
    file.puts
    file.puts "X068 is a throughput packet for repeated medium-risk selected-poems clusters. Every accepted row remains representative-selection evidence only; complete-work source debt, cut approval, and public replacement gates remain blocked."
    file.puts
    file.puts "Direct public replacements: 0."
  end
end

existing_packet_rows = packet_applied_rows
unless existing_packet_rows.empty?
  write_report(existing_packet_rows, "completed")
  puts "confirmed #{existing_packet_rows.size} previously applied X068 current medium-risk rescue evidence rows"
  exit
end

all_applied_rows = []
status = "completed"

(1..MAX_BATCHES).each do |batch_index|
  scope_rows = current_medium_scope_rows
  break if scope_rows.empty?

  if (scope_rows.map { |row| row.fetch("source_item_id") } & all_applied_rows.map { |row| row.fetch("source_item_id") }).any?
    raise "X068 detected repeated current medium rows; refusing to loop"
  end

  applied_rows = apply_scope_rows(scope_rows, batch_index, all_applied_rows.size)
  all_applied_rows.concat(applied_rows)
  refresh_downstream!

  next unless batch_index == MAX_BATCHES && current_medium_scope_rows.any?

  status = "completed_max_batch_limit_reached"
end

write_report(all_applied_rows, status)
puts "applied or confirmed #{all_applied_rows.size} X068 current medium-risk rescue evidence rows"
