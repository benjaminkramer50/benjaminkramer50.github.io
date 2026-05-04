#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'json'
require 'net/http'
require 'psych'
require 'yaml'

SOURCE_FILE = File.expand_path('../_data/movies.yml', __dir__)
TARGET_FILE = File.expand_path('../_data/movie_posters.yml', __dir__)
USER_AGENT = 'BenjaminsSiteBot/1.0 (benjamin-kramer.com)'

movies = YAML.load_file(SOURCE_FILE)

def http_get_json(uri, retries: 4, delay: 2.0)
  attempts = 0

  begin
    attempts += 1
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = USER_AGENT

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    case response.code.to_i
    when 200
      JSON.parse(response.body)
    when 429, 503
      raise "rate limited: #{response.code}"
    else
      nil
    end
  rescue StandardError
    raise if attempts > retries

    sleep(delay * attempts)
    retry
  end
end

def summary_uri(page_title)
  encoded = CGI.escape(page_title).gsub('+', '%20')
  URI("https://en.wikipedia.org/api/rest_v1/page/summary/#{encoded}")
end

def search_uri(query)
  encoded = CGI.escape(query).gsub('+', '%20')
  URI("https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=#{encoded}&format=json&origin=*")
end

def fetch_summary(page_title)
  data = http_get_json(summary_uri(page_title))
  return nil unless data.is_a?(Hash)

  image = data['thumbnail'] && data['thumbnail']['source']
  image ||= data['originalimage'] && data['originalimage']['source']

  if image
    {
      page_title: data['title'] || page_title,
      poster_url: image
    }
  end
end

def candidate_titles(title, year)
  slug_title = title.tr(' ', '_')
  [
    "#{slug_title}_(#{year}_film)",
    "#{slug_title}_(film)",
    slug_title,
    title
  ].uniq
end

def poster_for_movie(title, year)
  candidate_titles(title, year).each do |candidate|
    info = fetch_summary(candidate)
    return info if info
    sleep 1.5
  end

  query = [title, year, 'film'].compact.join(' ')
  search = http_get_json(search_uri(query))
  hits = search && search.dig('query', 'search')
  return nil unless hits

  hits.first(5).each do |hit|
    info = fetch_summary(hit['title'])
    return info if info
    sleep 1.5
  end

  nil
end

posters = {}

movies.each do |movie|
  next unless movie['title'] && movie['year']

  key = "#{movie['title'].downcase.gsub(/[^a-z0-9]+/, '-')}-#{movie['year']}"
  info = poster_for_movie(movie['title'], movie['year'])

  posters[key] = {
    'title' => movie['title'],
    'year' => movie['year']
  }

  if info
    posters[key]['page_title'] = info[:page_title]
    posters[key]['poster_url'] = info[:poster_url]
  end

  sleep 1.0
end

File.write(TARGET_FILE, Psych.dump(posters, line_width: -1))
puts "Wrote #{TARGET_FILE} (#{posters.size} entries)"
