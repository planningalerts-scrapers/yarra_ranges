require "epathway_scraper"

EpathwayScraper.scrape_and_save(
  "https://epathway.yarraranges.vic.gov.au/ePathway/Production",
  list_type: :all, max_pages: 20, state: "VIC"
)
