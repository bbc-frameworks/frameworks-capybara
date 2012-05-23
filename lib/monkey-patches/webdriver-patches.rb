require 'selenium-webdriver'

#Monkey Patch's - Use with care!
#Path to allow true custom capabilities
#e.g. job name for sauce labs
module Selenium
  module WebDriver
    module Remote
      class Capabilities

        def custom_capabilities(opts)
          @custom_capabilities = opts
        end

        #hopefuly this alias approach will mean we capture changes in the webdriver method
        alias_method :old_as_json, :as_json
        def as_json(opts = nil)

          hash = old_as_json
          if @custom_capabilities 
            @custom_capabilities.each do |key, value|
              hash[key] = value
            end
          end
          hash
        end
      end

      class Options
        def delete_cookies_in_domain(domain)
          delete_all_cookies #proxy to this method as WebDriver only deletes
          #by domain
        end
      end
    end
  end
end


