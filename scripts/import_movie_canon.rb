#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'nokogiri'
require 'open-uri'
require 'yaml'

SOURCE_URL = 'https://1001movies.fandom.com/api.php?action=parse&page=By_Director&prop=text&format=json&redirects=1'
OUTPUT_PATH = File.expand_path('../_data/movie_canon.yml', __dir__)

def slugify(text)
  text.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-+|-+$/, '')
end

def clean_text(text)
  text.to_s.gsub("\u00a0", ' ').gsub(/\s+/, ' ').strip
end

def fetch_json(url)
  URI.open(url, 'User-Agent' => 'Mozilla/5.0').read
end

payload = JSON.parse(fetch_json(SOURCE_URL))
html = payload.dig('parse', 'text', '*')
abort 'Could not read Fandom API response.' unless html

doc = Nokogiri::HTML(html)
table = doc.at_css('.mw-parser-output table')
abort 'Could not find the combined canon table on the Fandom page.' unless table

canon = []
current_director = nil
source_index = 0

table.css('tr').each do |tr|
  cells = tr.css('th,td')
  next if cells.empty?

  row_text = clean_text(cells.first.text)
  next if row_text.empty?

  if cells.length == 1 && row_text !~ /•/
    current_director = row_text
    next
  end

  next unless current_director
  next unless row_text.include?('•')

  row_text.split('•').map { |segment| clean_text(segment) }.reject(&:empty?).each do |segment|
    match = segment.match(/\A(.+?)\s*\((\d{4})\)\z/)
    next unless match

    title = clean_text(match[1])
    year = match[2].to_i
    source_index += 1

    canon << {
      'slug' => "#{slugify(title)}-#{year}",
      'title' => title,
      'year' => year,
      'director' => current_director,
      'source_index' => source_index,
      'source' => '1001 Movies You Must See Before You Die Wiki: By Director'
    }
  end

  current_director = nil
end

canon.sort_by! { |movie| [movie['title'].downcase, movie['year'], movie['director'].downcase] }

File.write(OUTPUT_PATH, YAML.dump(canon, line_width: -1))

puts "Wrote #{canon.length} canonical movies to #{OUTPUT_PATH}"
