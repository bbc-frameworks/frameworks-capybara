require 'show_me_the_cookies'
require 'capybara'
require 'frameworks/logger'

# monkey patches live here - beware!
module Capybara
  # override behaviour of visit to surpress bbc survey
  class Session
    include ShowMeTheCookies
    include FrameworksCapybara::Logger

    alias old_visit visit
    def visit(url)
      Capybara.current_driver
      old_visit url
      return if [:mechanize, :poltergeist].include?(Capybara.current_driver)
      surpress_cookies_prompt
      # reload_if_survey_appears
    end

    def surpress_cookies_prompt
      create_cookie('ckns_policy_exp', '9999999999999')
      create_cookie('ckns_policy', '111')
    end

    def reload_if_survey_appears
      reload = false
      within_frame('edr_l_first') do
        if has_selector?('#layer_wrap', wait: 1)
          log.info 'Found survey, will now reload the page'
          reload = true
        end
      end
      visit current_url if reload
    end
  end
end
