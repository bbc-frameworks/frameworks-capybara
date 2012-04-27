module Selenium
  module WebDriver
    module Firefox

      # @api private
      module Util
        module_function

        def app_data_path
          p "in patch"
          testpath = File.dirname(__FILE__)
          case Platform.os
          when :windows
            "#{ENV['APPDATA']}\\Mozilla\\Firefox"
          when :macosx
            #"#{Platform.home}/Library/Application Support/Firefox"
            testpath
          when :unix, :linux
            "#{Platform.home}/.mozilla/firefox"
          else
            raise "Unknown os: #{Platform.os}"
          end
        end

        def stringified?(str)
          str =~ /^".*"$/
        end

      end # Util
    end # Firefox
  end # WebDriver
end # Selenium

