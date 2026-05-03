#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

REPLACEMENT_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_replacement_candidates.tsv")
CUT_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_cut_candidates.tsv")
PAIR_REVIEW_QUEUE_PATH = File.join(TABLE_DIR, "canon_replacement_pair_review_queue.tsv")

HEADERS = %w[
  queue_id transaction_id add_work_id add_title add_creator cut_work_id cut_title
  cut_creator add_score cut_risk_score pair_review_priority review_bucket
  duplicate_check chronology_check boundary_check cut_rationale next_action
].freeze

MAX_ROWS = 75
MAX_PER_ADD = 15
MAX_PER_CUT_TITLE = 10

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows)
  FileUtils.mkdir_p(File.dirname(path))
  CSV.open(path, "w", col_sep: "\t", force_quotes: false) do |csv|
    csv << headers
    rows.each { |row| csv << headers.map { |header| row.fetch(header, "") } }
  end
end

def add_score(row)
  row.fetch("score_delta").match(/\+([0-9.]+)/)&.captures&.first.to_f
end

def cut_risk(row)
  row.fetch("score_delta").match(/cut_risk=([0-9.]+)/)&.captures&.first.to_f
end

def review_bucket(row)
  return "boundary_first" if row.fetch("boundary_check").start_with?("cut_boundary_flag_review_required")
  return "chronology_first" if row.fetch("chronology_check").start_with?("cut_chronology_issue_review_required")
  return "generic_duplicate_cluster_first" if row.fetch("duplicate_check").start_with?("cut_generic_duplicate_cluster_review_required")
  return "duplicate_cluster_first" if row.fetch("duplicate_check").start_with?("cut_duplicate_cluster_review_required")

  "source_debt_first"
end

def blocker_penalty(row)
  penalty = 0.0
  penalty += 0.75 if row.fetch("boundary_check").start_with?("cut_boundary_flag_review_required")
  penalty += 0.50 if row.fetch("chronology_check").start_with?("cut_chronology_issue_review_required")
  penalty += 0.25 if row.fetch("duplicate_check").start_with?("same_author_cluster_blocked")
  penalty
end

replacement_rows = read_tsv(REPLACEMENT_CANDIDATES_PATH)
cut_by_work = read_tsv(CUT_CANDIDATES_PATH).to_h { |row| [row.fetch("work_id"), row] }

ranked = replacement_rows
         .select { |row| row.fetch("gate_status") == "blocked" }
         .map do |row|
           cut = cut_by_work.fetch(row.fetch("cut_work_id"))
           priority = add_score(row) + (cut_risk(row) * 0.50) - blocker_penalty(row)
           [row, cut, priority]
         end
         .sort_by { |row, _cut, priority| [-priority, row.fetch("add_title"), row.fetch("cut_title")] }

selected = []
counts_by_add = Hash.new(0)
counts_by_cut_title = Hash.new(0)
seen_cuts = {}

ranked.each do |row, cut, priority|
  next if counts_by_add[row.fetch("add_work_id")] >= MAX_PER_ADD
  next if counts_by_cut_title[row.fetch("cut_title")] >= MAX_PER_CUT_TITLE
  next if seen_cuts[row.fetch("cut_work_id")] && selected.size < MAX_ROWS / 2

  selected << [row, cut, priority]
  counts_by_add[row.fetch("add_work_id")] += 1
  counts_by_cut_title[row.fetch("cut_title")] += 1
  seen_cuts[row.fetch("cut_work_id")] = true
  break if selected.size >= MAX_ROWS
end

queue_rows = selected.map.with_index(1) do |(row, cut, priority), index|
  {
    "queue_id" => "x049_pair_review_#{index.to_s.rjust(4, "0")}",
    "transaction_id" => row.fetch("transaction_id"),
    "add_work_id" => row.fetch("add_work_id"),
    "add_title" => row.fetch("add_title"),
    "add_creator" => row.fetch("add_creator"),
    "cut_work_id" => row.fetch("cut_work_id"),
    "cut_title" => row.fetch("cut_title"),
    "cut_creator" => row.fetch("cut_creator"),
    "add_score" => format("%.3f", add_score(row)),
    "cut_risk_score" => format("%.2f", cut_risk(row)),
    "pair_review_priority" => format("%.3f", priority),
    "review_bucket" => review_bucket(row),
    "duplicate_check" => row.fetch("duplicate_check"),
    "chronology_check" => row.fetch("chronology_check"),
    "boundary_check" => row.fetch("boundary_check"),
    "cut_rationale" => cut.fetch("rationale"),
    "next_action" => "manual_pair_review_before_any_ready_for_review_promotion"
  }
end

write_tsv(PAIR_REVIEW_QUEUE_PATH, HEADERS, queue_rows)

puts "wrote #{PAIR_REVIEW_QUEUE_PATH.sub(ROOT + "/", "")} (#{queue_rows.size} rows)"
queue_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("review_bucket")] += 1 }.sort.each do |bucket, count|
  puts "#{bucket}: #{count}"
end
