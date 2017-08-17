# This patch overrides the normal mechanism for searching for Firefox profiles
# causing named profiles to be created in the local directory (rather than be referenced)
# for unit/integration testing purposes
module Selenium
  module WebDriver
    module Firefox
      # @api private
      module Util
        module_function

        def app_data_path
          File.dirname(__FILE__)
        end
      end # Util
    end # Firefox
  end # WebDriver
end # Selenium
