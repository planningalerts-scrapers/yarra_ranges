require 'scraperwiki'
require 'mechanize'
require 'date'

base_url   = "https://epathway.yarraranges.vic.gov.au/ePathway/Production/Web"
main_url   = "#{base_url}/GeneralEnquiry"
splash_url = "#{base_url}/default.aspx"

agent = Mechanize.new do |a|
  a.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

puts "Setting up session by visiting splash page..."
splash_page = agent.get( splash_url )
puts "Splash page: '#{splash_page.title.strip}'"

puts "Loading search form so that we can submit it..."
first_page = agent.get( "#{main_url}/EnquiryLists.aspx" )
puts "Search page: '#{first_page.title.strip}'"

search_form = first_page.forms.first

puts "Submitting search form."
puts "The form will result in all applications since the beginning of time, however, they should be sorted in reverse chronological order. This means we can scrape indefinetaly until we hit one we've seen before."

summary_page = agent.submit( search_form, search_form.buttons.first )
puts "Summary page: '#{summary_page.title.strip}'"

data     = []
page_num = 1

now             = Date.today.to_s
comment_address = 'mailto:mail@yarraranges.vic.gov.au'

# Only figure out the header stuff the first time...
headers               = nil
idx_council_reference = nil
idx_description       = nil
idx_date_received     = nil
idx_address           = nil

while summary_page
  puts "Processing: Page #{page_num}..."

  table = summary_page.root.at_css('table.ContentPanel')

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

  applications = data.each do |application|

    # p application

    info = {}
    info['council_reference'] = application[ idx_council_reference ]
    info['address']           = application[ idx_address           ]
    info['description']       = application[ idx_description       ]
    info['info_url']          = splash_url # There is a direct link but you need a session to access it :(
    if idx_date_received
      info['date_received']     = Date.strptime( application[ idx_date_received ], '%d/%m/%Y' ).to_s
    end
    info['date_scraped']      = now
    info['comment_url']       = comment_address

    # p info

    ScraperWiki.save_sqlite( ['council_reference'], info )

  end

  page_num = page_num + 1
  summary_page = agent.get( "#{main_url}/EnquirySummaryView.aspx", { :PageNumber => page_num } )
end

puts "Finished."
