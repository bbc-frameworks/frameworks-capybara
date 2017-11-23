# generic util methods
module FrameworksCapybara
  # generic util methods
  module Utils
    def rubyize(english_string)
      english_string.tr(' ', '_').downcase
    end

    def loweralpha(str)
      str.downcase.scan(/[a-z]/).join
    end

    def clean_id_cookies
      Capybara.current_session.delete_cookie 'IDENTITIY'
      Capybara.current_session.delete_cookie 'IDENTITIY_ENV'
    end

    def set_cookie_for_uk
      page.execute_script 'document.cookie="ckns_orb_fig_cache={%22uk%22:1%2C%22ck%22:1%2C%22ad%22:0%2C%22ap%22:0%2C%22tb%22:0%2C%22mb%22:0%2C%22eu%22:1}; path=/; domain=.bbc.co.uk";'
      visit current_url
    end

    def browser
      if Capybara.current_driver == :selenium
        Capybara.current_session.driver.browser.manage
                .instance_variable_get('@bridge')
                .instance_variable_get('@capabilities')[:browser_name]
      else
        Capybara.current_driver
      end
    end

    def check_expected_page_items(page, table)
      table.raw.flatten.each do |table_item|
        page_method = "have_#{rubyize(table_item)}"
        expect(page).to send page_method
      end
    end

    def check_expected_link_text(parent_body, table)
      table.raw.flatten.each do |link_text|
        expect(parent_body.has_link?(link_text)).to eq true
      end
    end

    def check_expected_section_items(sections, table)
      sections.each do |section|
        table.raw.flatten.each do |section_item|
          section_method = "have_#{rubyize(section_item)}"
          expect(section).to send(section_method) unless section_item.include? '(optional)'
        end
      end
    end

    def check_expected_section_item(section, table)
      table.raw.flatten.each do |section_item|
        section_method = "have_#{rubyize(section_item)}"
        expect(section).to send(section_method) unless section_item.include? '(optional)'
      end
    end

    def check_expected_section_translation(section, table)
      table.rows_hash.each do |key, value|
        element = key.downcase.tr(' ', '_').tr(',', '')
        expect(section.send(element).text).to eql value
      end
    end

    def check_expected_section_translation_includes(section, table)
      table.rows_hash.each do |key, value|
        element = key.downcase.tr(' ', '_').tr(',', '')
        expect(section.send(element).text).to include value
      end
    end

    def check_expected_element_translation(page, table)
      table.rows_hash.each do |key, value|
        element = key.downcase.tr(' ', '_').tr(',', '')
        expect(page.send(element).text).to eql value
      end
    end

    def switch_to_last_opened_window
      Capybara.page.switch_to_window(Capybara.page.windows.last)
      Capybara.page.windows.first.close
    end

    def wait_until_page_is_fully_loaded
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop until (value = Capybara.page.evaluate_script('document.readyState').eql?('complete'))
        value
      end
    end

    def scroll_to_element(element)
      page.execute_script("arguments[0].scrollIntoView(true);", element)
    end

    def save_and_link_screenshot
      FileUtils.mkdir_p('reports') unless File.directory?('reports')
      current_time = Time.new.strftime('%Y-%m-%d-%H-%M-%S')
      Capybara.current_session.driver.save_screenshot("./reports/Screenshot_#{current_time}.png")
      embed "./reports/Screenshot_#{current_time}.png", 'image/png', "Actual screenshot of the error at #{current_url}"
    end

    def get_console_logs(type)
    case type
    when 'errors'
      errors = page.driver.browser.manage.logs.get(:browser).select {|e| e.level == "SEVERE"}.map(&:message).to_a
       if errors.present?
         puts "Below are the errors found."
         raise StandardError, errors.join("\n\n")
       else
         puts "No Error found in console"
       end
     when 'warnings'
       warnings = page.driver.browser.manage.logs.get(:browser).select {|e| e.level != "SEVERE"}.map(&:message).to_a
       if warnings.present?
         puts "Below are the warnings found."
         raise StandardError, warnings.join("\n\n")
       else
         puts "No warnings found in console"
       end
     when 'errors_and_warnings'
       errors = page.driver.browser.manage.logs.get(:browser).map(&:message).join("\n\n")
       if errors.present?
         puts "Below are the errors/warnings found."
         raise StandardError, errors
       else
         puts "No Error/warnings found in console"
       end
    end
    end
  end
end
