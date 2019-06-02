require "epathway_scraper"

base_url   = "https://epathway.yarraranges.vic.gov.au/ePathway/Production/Web"
main_url   = "#{base_url}/GeneralEnquiry"
splash_url = "#{base_url}/default.aspx"

agent = Mechanize.new

splash_page = agent.get( splash_url )

first_page = agent.get( "#{main_url}/EnquiryLists.aspx" )

search_form = first_page.forms.first

summary_page = agent.submit( search_form, search_form.buttons.first )

page_num = 1
while summary_page
  table = summary_page.root.at_css('table.ContentPanel')

  if table.nil?
    puts "For some reason the table is missing :-( Skip this page"
    next
  end

  EpathwayScraper::Table.extract_table_data_and_urls(table).each do |row|
    info = {
      'council_reference' => row[:content]["Our Reference"],
      'address' => row[:content]["Location"],
      'description' => row[:content]["Type of Application"],
      'info_url' => splash_url,
      'date_scraped' => Date.today.to_s
    }

    if row[:content]["Date Lodged"]
      info['date_received'] = Date.strptime(row[:content]["Date Lodged"], '%d/%m/%Y').to_s
    end

    EpathwayScraper.save(info)
  end

  page_num = page_num + 1

  # Fairly arbitrarily only read in the first 20 pages. Goes back roughly 6 months
  break if page_num > 20

  summary_page = agent.get( "#{main_url}/EnquirySummaryView.aspx", { :PageNumber => page_num } )
end
