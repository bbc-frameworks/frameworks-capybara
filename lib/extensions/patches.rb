require 'show_me_the_cookies'
require 'capybara'
require 'frameworks/logger'
# monkey patches live here - beware!
module Capybara
  # override behaviour of visit to surpress bbc survey
  class Session
    include ShowMeTheCookies
    include FrameworksCapybara::Logger

    alias_method :old_visit, :visit
    def visit(url)
      old_visit url
      surpress_cookies_prompt unless Capybara.current_driver == :mechanize
      reload_if_survey_appears unless Capybara.current_driver == :mechanize
    end

    def surpress_cookies_prompt
      create_cookie('ckns_policy_exp', '9999999999999')
      create_cookie('ckns_policy', '111')
    end

    def reload_if_survey_appears
      reload = false
      within_frame('edr_l_first') do
        if has_selector?('#layer_wrap', wait: 1)
          log.info 'Found survey, will now reload page - only true x browser solution for now'
          reload = true
        end
      end
      visit current_url if reload
    end
  end
end
