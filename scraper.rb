require 'bundler'
Bundler.require

require 'csv'

class EroScraper
  include Capybara::DSL

  def initialize
    Capybara.app = self
    Capybara.current_driver = :mechanize
    Capybara.run_server = false
    Capybara.app_host = "http://ero.govt.nz"
  end

  def scrape!(year)
    visit 'http://ero.govt.nz/Early-Childhood-School-Reports/Early-Childhood-Reports?&sfilter[report/school_name]=&dfilter[report/date][year]=' + year.to_s

    CSV.open("early_childhood_#{year}.csv", 'wb') do |csv|

      csv << ['name', 'link', 'assessment', 'download_report']

      get_list.each do |school|
        result = check_school_assessment school
        puts result
        csv << result
      end

    end

  end

  private

  def check_school_assessment(school)
    visit school[:link]
    assessment = begin
                   find('.main-finding-block .highlight').text
                 rescue Capybara::ElementNotFound
                   nil
                 end

    report_download_link = begin
                             find('a.download-report-button')['href']
                           rescue Capybara::ElementNotFound
                             nil
                           end

    [school[:name], school[:link], assessment, 'http://ero.govt.nz' + report_download_link]
  end

  def get_list
    results = []

    next_button = true

    while next_button
      all('.results ul a').each do |a|
        # puts "Fetching #{a.text}"
        results << { name: a.text, link: a['href'] }
        # puts "\"#{a.text}\",\"http://ero.govt.nz#{a['href']}\""
      end

      next_button = first('span.button.next')
      next_button.first(:xpath,".//..").click if next_button
    end

    results
  end
end
