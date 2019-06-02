require "epathway_scraper"

base_url   = "https://epathway.yarraranges.vic.gov.au/ePathway/Production/Web"
main_url   = "#{base_url}/GeneralEnquiry"
splash_url = "#{base_url}/default.aspx"

agent = Mechanize.new

splash_page = agent.get( splash_url )

first_page = agent.get( "#{main_url}/EnquiryLists.aspx" )

search_form = first_page.forms.first

summary_page = agent.submit( search_form, search_form.buttons.first )

data     = []
page_num = 1

# Only figure out the header stuff the first time...
headers               = nil
idx_council_reference = nil
idx_description       = nil
idx_date_received     = nil
idx_address           = nil

while summary_page
  table = summary_page.root.at_css('table.ContentPanel')

  if table.nil?
    puts "For some reason the table is missing :-( Skip this page"
    next
  end

  unless headers
    headers = table.css('th').collect { |th| th.inner_text.strip }
    # puts headers.inspect
    # ["Our Reference", "Type of Application", "Date Lodged", "Location", "Details of application or permit", "Decision (where applicable)"]
    idx_council_reference = headers.index("Our Reference")
    idx_description       = headers.index('Type of Application')
    idx_date_received     = headers.index('Date Lodged')
    idx_address           = headers.index('Location')
  end

  data = table.css('.ContentPanel, .AlternateContentPanel').collect do |tr|
    tr.css('td').collect { |td| td.inner_text.strip }
  end

  data.each do |application|
    info = {
      'council_reference' => application[idx_council_reference],
      'address' => application[idx_address],
      'description' => application[idx_description],
      'info_url' => splash_url,
      'date_scraped' => Date.today.to_s
    }

    if idx_date_received
      info['date_received'] = Date.strptime(application[idx_date_received], '%d/%m/%Y').to_s
    end

    EpathwayScraper.save(info)
  end

  page_num = page_num + 1

  # Fairly arbitrarily only read in the first 20 pages. Goes back roughly 6 months
  break if page_num > 20

  summary_page = agent.get( "#{main_url}/EnquirySummaryView.aspx", { :PageNumber => page_num } )
end
