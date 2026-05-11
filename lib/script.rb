#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

owner, repo = ARGV

if owner.nil? || repo.nil?
  warn "Usage: ruby lib/script.rb <owner> <repo>"
  exit 1
end

url = URI("https://api.github.com/repos/#{owner}/#{repo}/commits?per_page=5")

request = Net::HTTP::Get.new(url)
request["User-Agent"] = "recent-commits-script"
request["Accept"] = "application/vnd.github+json"

begin
  response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
    http.request(request)
  end
rescue StandardError => e
  warn "Network error while contacting GitHub: #{e.message}"
  exit 1
end

case response.code
when "200"
  commits = JSON.parse(response.body)

  commits.each do |commit|
    short_sha = commit["sha"][0, 7]
    author = commit.dig("author", "login") || "(unknown)"
    date = commit.dig("commit", "author", "date").to_s[0, 10]
    message = commit.dig("commit", "message").to_s.split("\n").first.to_s
    puts "#{short_sha}  #{author}  #{date}  #{message}"
  end
when "404"
  warn "Repository not found: #{owner}/#{repo}"
  exit 1
when "403"
  warn "GitHub rate limit reached or access forbidden. Try again later."
  exit 1
else
  warn "Unexpected response from GitHub (#{response.code})."
  exit 1
end
