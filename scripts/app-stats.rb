# Prints a Markdown snapshot of JASDA's App Store performance (downloads,
# proceeds, ratings, search rank). Usage and setup: docs/metrics/README.md.

require "date"
require "json"
require "net/http"
require "spaceship"
require "zlib"

APP_ID = "6797626109".freeze
COUNTRIES = %w[gb us].freeze
KEYWORDS = ["dice", "dice roller", "roll dice", "dice app", "simple dice", "board game dice"].freeze
# Sales report product types: https://developer.apple.com/help/app-store-connect/reference/product-type-identifiers
DOWNLOAD_TYPES = %w[1 1F 1T F1].freeze
REDOWNLOAD_TYPES = %w[3 3F 3T F3].freeze

def get_json(url)
  JSON.parse(Net::HTTP.get(URI(url)))
end

# One day's SALES/SUMMARY report rows for this app, or [] when Apple has no
# report for that day (it returns 404 when nothing was sold or downloaded).
def sales_rows(token, vendor, date)
  uri = URI("https://api.appstoreconnect.apple.com/v1/salesReports")
  uri.query = URI.encode_www_form(
    "filter[frequency]" => "DAILY", "filter[reportType]" => "SALES",
    "filter[reportSubType]" => "SUMMARY", "filter[vendorNumber]" => vendor,
    "filter[reportDate]" => date.iso8601, "filter[version]" => "1_1"
  )
  response = Net::HTTP.get_response(uri, "Authorization" => "Bearer #{token.text}", "Accept" => "application/a-gzip")
  return [] if response.is_a?(Net::HTTPNotFound)
  raise "Sales report for #{date}: HTTP #{response.code} #{response.body[0, 300]}" unless response.is_a?(Net::HTTPSuccess)

  header, *rows = Zlib.gunzip(response.body).lines.map { |line| line.chomp.split("\t") }
  rows.map { |row| header.zip(row).to_h }.select { |row| row["Apple Identifier"] == APP_ID }
end

days = Integer(ARGV.fetch(0, "28"))
token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch("ASC_KEY_ID"), issuer_id: ENV.fetch("ASC_ISSUER_ID"), filepath: ENV.fetch("ASC_KEY_PATH")
)
vendor = ENV.fetch("ASC_VENDOR_NUMBER")
# Daily reports land the following day (Pacific time), so end yesterday.
dates = (1..days).map { |ago| Date.today - ago }.reverse
rows = dates.flat_map { |date| sales_rows(token, vendor, date).map { |row| row.merge("date" => date) } }

units = ->(set, types) { set.select { |row| types.include?(row["Product Type Identifier"]) }.sum { |row| row["Units"].to_i } }

puts "# JASDA App Store snapshot — #{Date.today.iso8601}"
puts
puts "## Sales and Trends (#{dates.first} to #{dates.last}, #{days} days)"
puts
downloads = units.(rows, DOWNLOAD_TYPES)
puts "- First-time downloads: **#{downloads}** (#{(downloads.to_f / days).round(1)}/day)"
puts "- Re-downloads: #{units.(rows, REDOWNLOAD_TYPES)}"
proceeds = rows.group_by { |row| row["Currency of Proceeds"] }
               .transform_values { |set| set.sum { |row| row["Developer Proceeds"].to_f * row["Units"].to_i }.round(2) }
               .reject { |_, total| total.zero? }
puts "- Proceeds: #{proceeds.empty? ? "none" : proceeds.map { |currency, total| "#{total} #{currency}" }.join(", ")}"
puts
puts "| Country | Downloads |"
puts "| --- | ---: |"
rows.group_by { |row| row["Country Code"] }
    .map { |country, set| [country, units.(set, DOWNLOAD_TYPES)] }
    .reject { |_, count| count.zero? }.sort_by { |_, count| -count }.first(15)
    .each { |country, count| puts "| #{country} | #{count} |" }
puts
puts "| Week ending (Sun) | Downloads |"
puts "| --- | ---: |"
rows.group_by { |row| row["date"] + ((7 - row["date"].wday) % 7) }.sort
    .each { |week, set| puts "| #{week} | #{units.(set, DOWNLOAD_TYPES)} |" }

puts
puts "## Public listing"
puts
puts "| Store | Version | Price | Rating | Ratings |"
puts "| --- | --- | --- | ---: | ---: |"
COUNTRIES.each do |country|
  app = get_json("https://itunes.apple.com/lookup?id=#{APP_ID}&country=#{country}")["results"].first
  next puts("| #{country.upcase} | not listed | | | |") unless app

  puts "| #{country.upcase} | #{app["version"]} | #{app["formattedPrice"]} | #{app["averageUserRating"]&.round(2)} | #{app["userRatingCount"]} |"
end

puts
puts "## Search rank (iTunes Search API — an approximation of App Store search)"
puts
puts "| Keyword | #{COUNTRIES.map(&:upcase).join(" | ")} |"
puts "| --- |#{" ---: |" * COUNTRIES.size}"
KEYWORDS.each do |keyword|
  ranks = COUNTRIES.map do |country|
    results = get_json("https://itunes.apple.com/search?#{URI.encode_www_form(term: keyword, country: country, entity: "software", limit: 200)}")["results"]
    index = results.index { |app| app["trackId"].to_s == APP_ID }
    index ? "##{index + 1}" : ">200"
  end
  puts "| #{keyword} | #{ranks.join(" | ")} |"
end
