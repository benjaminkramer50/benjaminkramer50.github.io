#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
TABLE_DIR = File.join(ROOT, "_planning", "canon_build", "tables")

PAIR_REVIEW_QUEUE_PATH = File.join(TABLE_DIR, "canon_replacement_pair_review_queue.tsv")
CUT_CANDIDATES_PATH = File.join(TABLE_DIR, "canon_cut_candidates.tsv")
CUT_REVIEW_WORK_ORDERS_PATH = File.join(TABLE_DIR, "canon_cut_review_work_orders.tsv")

HEADERS = %w[
  work_order_id cut_work_id cut_title cut_creator cut_rank cut_risk_score
  cut_source_debt_status cut_evidence_count cut_generic_title_flag cut_duplicate_cluster_key
  cut_duplicate_cluster_size cut_chronology_issue_count cut_boundary_flag paired_add_work_ids
  paired_add_titles pair_queue_ids review_priority review_focus next_action
].freeze

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

def review_focus(cut)
  focuses = []
  focuses << "generic_title_selection_basis" if cut.fetch("generic_title_flag") == "true"
  focuses << "duplicate_cluster" if cut.fetch("duplicate_cluster_size").to_i.positive?
  focuses << "chronology" if cut.fetch("chronology_issue_count").to_i.positive?
  focuses << "boundary" if cut.fetch("boundary_flag") == "true"
  focuses << "source_debt" if cut.fetch("source_debt_status").start_with?("open_")
  focuses.empty? ? "manual_review" : focuses.join(";")
end

queue_rows = read_tsv(PAIR_REVIEW_QUEUE_PATH)
cut_by_work = read_tsv(CUT_CANDIDATES_PATH).to_h { |row| [row.fetch("work_id"), row] }

work_order_rows = queue_rows
                  .group_by { |row| row.fetch("cut_work_id") }
                  .map do |cut_work_id, rows|
                    cut = cut_by_work.fetch(cut_work_id)
                    {
                      "cut_work_id" => cut_work_id,
                      "cut_title" => cut.fetch("title"),
                      "cut_creator" => cut.fetch("creator"),
                      "cut_rank" => cut.fetch("rank"),
                      "cut_risk_score" => cut.fetch("risk_score"),
                      "cut_source_debt_status" => cut.fetch("source_debt_status"),
                      "cut_evidence_count" => cut.fetch("evidence_count"),
                      "cut_generic_title_flag" => cut.fetch("generic_title_flag"),
                      "cut_duplicate_cluster_key" => cut.fetch("duplicate_cluster_key"),
                      "cut_duplicate_cluster_size" => cut.fetch("duplicate_cluster_size"),
                      "cut_chronology_issue_count" => cut.fetch("chronology_issue_count"),
                      "cut_boundary_flag" => cut.fetch("boundary_flag"),
                      "paired_add_work_ids" => rows.map { |row| row.fetch("add_work_id") }.uniq.join(";"),
                      "paired_add_titles" => rows.map { |row| row.fetch("add_title") }.uniq.join(";"),
                      "pair_queue_ids" => rows.map { |row| row.fetch("queue_id") }.join(";"),
                      "review_priority" => format("%.3f", rows.map { |row| row.fetch("pair_review_priority").to_f }.max),
                      "review_focus" => review_focus(cut),
                      "next_action" => "review_cut_identity_source_support_selection_basis_before_pair_promotion"
                    }
                  end
                  .sort_by { |row| [-row.fetch("review_priority").to_f, -row.fetch("cut_risk_score").to_f, row.fetch("cut_rank").to_i] }
                  .map.with_index(1) do |row, index|
                    row.merge("work_order_id" => "x050_cut_review_#{index.to_s.rjust(4, "0")}")
                  end

write_tsv(CUT_REVIEW_WORK_ORDERS_PATH, HEADERS, work_order_rows)

puts "wrote #{CUT_REVIEW_WORK_ORDERS_PATH.sub(ROOT + "/", "")} (#{work_order_rows.size} rows)"
work_order_rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.fetch("review_focus")] += 1 }.sort.each do |focus, count|
  puts "#{focus}: #{count}"
end
