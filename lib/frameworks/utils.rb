# generic util methods
module FrameworksCapybara
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

    def switch_to_last_opened_window
      Capybara.page.switch_to_window(Capybara.page.windows.last)
      Capybara.page.windows.first.close
    end
  end
end
