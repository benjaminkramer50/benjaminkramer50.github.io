#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'nokogiri'
require 'open-uri'
require 'yaml'

SOURCE_URL = 'https://1001movies.fandom.com/api.php?action=parse&page=By_Director&prop=text&format=json&redirects=1'
OUTPUT_PATH = File.expand_path('../_data/movie_canon.yml', __dir__)
SOURCE_LABEL = '1001 Movies You Must See Before You Die Wiki: By Director'

DIRECTOR_OVERRIDES = {
  'a-dog-s-life-1962' => 'Gualtiero Jacopetti & Paolo Cavara',
  'a-matter-of-life-and-death-1946' => 'Michael Powell & Emeric Pressburger',
  'a-night-at-the-opera-1935' => 'Sam Wood',
  'a-tale-of-the-wind-1988' => 'Joris Ivens',
  'aileen-life-and-death-of-a-serial-killer-2003' => 'Nick Broomfield & Joan Churchill',
  'airplane-1980' => 'Jim Abrahams & David Zucker',
  'animal-farm-1954' => 'John Halas & Joy Batchelor',
  'avengers-infinity-war-2018' => 'Anthony Russo & Joe Russo',
  'beauty-and-the-beast-1946' => 'Jean Cocteau & René Clément',
  'black-narcissus-1946' => 'Michael Powell & Emeric Pressburger',
  'caravaggio-1986' => 'Derek Jarman',
  'christ-stopped-at-eboli-1979' => 'Francesco Rosi',
  'cinema-paradiso-1988' => 'Giuseppe Tornatore',
  'city-of-god-2002' => 'Fernando Meirelles & Kátia Lund',
  'dance-girl-dance-1940' => 'Dorothy Arzner',
  'el-norte-1983' => 'Gregory Nava',
  'fantasia-1940' => 'James Algar & Samuel Armstrong',
  'foolish-wives-1922' => 'Erich von Stroheim',
  'gimme-shelter-1970' => 'Albert Maysles & David Maysles',
  'glory-1989' => 'Edward Zwick',
  'gone-with-the-wind-1939' => 'Victor Fleming',
  'greed-1924' => 'Erich von Stroheim',
  'hearts-of-darkness-a-filmmaker-s-apocalypse-1991' => 'Fax Bahr, George Hickenlooper & Eleanor Coppola',
  'i-know-where-i-m-going-1945' => 'Michael Powell & Emeric Pressburger',
  'inglourious-basterds-2009' => 'Quentin Tarantino',
  'king-kong-1933' => 'Merian C. Cooper & Ernest B. Schoedsack',
  'little-miss-sunshine-2006' => 'Jonathan Dayton & Valerie Faris',
  'lock-stock-and-two-smoking-barrels-1998' => 'Guy Ritchie',
  'meshes-of-the-afternoon-1943' => 'Maya Deren & Alexander Hammid',
  'monty-python-and-the-holy-grail-1975' => 'Terry Gilliam & Terry Jones',
  'mutiny-on-the-bounty-1935' => 'Frank Lloyd',
  'october-ten-days-that-shook-the-world-1927' => 'Sergei M. Eisenstein & Grigori Aleksandrov',
  'on-the-town-1949' => 'Gene Kelly & Stanley Donen',
  'our-hospitality-1923' => 'Buster Keaton & John G. Blystone',
  'passenger-1963' => 'Andrzej Munk & Witold Lesiewicz',
  'performance-1970' => 'Donald Cammell & Nicolas Roeg',
  'red-river-1948' => 'Howard Hawks & Arthur Rosson',
  'scarface-the-shame-of-a-nation-1932' => 'Howard Hawks & Richard Rosson',
  'shaft-1971' => 'Gordon Parks',
  'singin-in-the-rain-1952' => 'Gene Kelly & Stanley Donen',
  'slumdog-millionaire-2008' => 'Danny Boyle & Loveleen Tandan',
  'smoke-1995' => 'Wayne Wang & Paul Auster',
  'snow-white-and-the-seven-dwarfs-1937' => 'David Hand',
  'steamboat-bill-jr-1928' => 'Charles Reisner & Buster Keaton',
  'straight-outta-compton-2015' => 'F. Gary Gray',
  'the-adventures-of-prince-achmed-1926' => 'Lotte Reiniger',
  'the-adventures-of-robin-hood-1938' => 'Michael Curtiz & William Keighley',
  'the-big-parade-1925' => 'King Vidor',
  'the-blair-witch-project-1999' => 'Daniel Myrick & Eduardo Sánchez',
  'the-general-1927' => 'Buster Keaton & Clyde Bruckman',
  'the-kid-brother-1927' => 'Ted Wilde & J. A. Howe',
  'the-life-and-death-of-colonel-blimp-1943' => 'Michael Powell & Emeric Pressburger',
  'the-lion-king-1994' => 'Roger Allers & Rob Minkoff',
  'the-magnificent-ambersons-1942' => 'Orson Welles',
  'the-phantom-of-the-opera-1925' => 'Rupert Julian',
  'the-red-shoes-1948' => 'Michael Powell & Emeric Pressburger',
  'the-wizard-of-oz-1939' => 'Victor Fleming',
  'there-s-something-about-mary-1998' => 'Peter Farrelly & Bobby Farrelly',
  'too-early-too-late-1981' => 'Danièle Huillet & Jean-Marie Straub',
  'vij-1967' => 'Konstantin Ershov & Georgiy Kropachyov',
  'west-side-story-1961' => 'Robert Wise & Jerome Robbins',
  'yol-1982' => 'Şerif Gören & Yılmaz Güney'
}.freeze

def slugify(text)
  text.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-+|-+$/, '')
end

def clean_text(text)
  text.to_s.gsub("\u00a0", ' ').gsub(/\s+/, ' ').strip
end

def fetch_json(url)
  URI.open(url, 'User-Agent' => 'Mozilla/5.0').read
end

def merged_director(slug, entries)
  return DIRECTOR_OVERRIDES[slug] if DIRECTOR_OVERRIDES.key?(slug)

  directors = entries.map { |entry| entry['director'] }.uniq
  combined = directors.find { |director| director.match?(/\s[&,]\s/) }
  combined || directors.join(' & ')
end

def deduplicate_movies(canon)
  canon
    .group_by { |movie| movie['slug'] }
    .map do |slug, entries|
      first = entries.min_by { |entry| entry['source_index'] }
      first.merge(
        'director' => merged_director(slug, entries),
        'source_index' => entries.map { |entry| entry['source_index'] }.min
      )
    end
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
      'source' => SOURCE_LABEL
    }
  end

  current_director = nil
end

canon = deduplicate_movies(canon)
canon.sort_by! { |movie| [movie['title'].downcase, movie['year'], movie['director'].downcase] }

duplicate_slugs = canon.group_by { |movie| movie['slug'] }.select { |_slug, entries| entries.length > 1 }
abort "Duplicate movie slugs remain: #{duplicate_slugs.keys.join(', ')}" unless duplicate_slugs.empty?

File.write(OUTPUT_PATH, YAML.dump(canon, line_width: -1))

puts "Wrote #{canon.length} canonical movies to #{OUTPUT_PATH}"
