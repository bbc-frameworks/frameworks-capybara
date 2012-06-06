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

#Workaround for http://code.google.com/p/selenium/issues/detail?id=4007
module Selenium
  module WebDriver
    module Remote
      module Http
        class Default
          def new_http_client
            if @proxy
              unless @proxy.respond_to?(:http) && url = @proxy.http
                raise Error::WebDriverError, "expected HTTP proxy, got #{@proxy.inspect}"
              end

              proxy = URI.parse(url)

              clazz = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password)
              clazz.new(server_url.host, server_url.port)
            else
              Net::HTTP.new server_url.host, server_url.port
            end
          end
        end
      end
    end
  end
end
