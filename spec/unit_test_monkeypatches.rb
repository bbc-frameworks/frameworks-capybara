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

