require "epathway_scraper"

base_url   = "https://epathway.yarraranges.vic.gov.au/ePathway/Production/Web"
main_url   = "#{base_url}/GeneralEnquiry"
splash_url = "#{base_url}/default.aspx"

scraper = EpathwayScraper::Scraper.new(
  "https://epathway.yarraranges.vic.gov.au/ePathway/Production"
)

splash_page = scraper.agent.get( scraper.base_url )

first_page = scraper.agent.get( "#{main_url}/EnquiryLists.aspx" )

search_form = first_page.forms.first

summary_page = scraper.agent.submit( search_form, search_form.buttons.first )

page_num = 1
while summary_page
  EpathwayScraper::Page::Index.scrape_index_page(summary_page, scraper.base_url, scraper.agent) do |record|
    EpathwayScraper.save(record)
  end

  page_num = page_num + 1

  # Fairly arbitrarily only read in the first 20 pages. Goes back roughly 6 months
  break if page_num > 20

  summary_page = scraper.agent.get( "#{main_url}/EnquirySummaryView.aspx", { :PageNumber => page_num } )
end
