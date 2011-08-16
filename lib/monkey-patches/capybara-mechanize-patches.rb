require 'capybara/mechanize/cucumber' 
require 'uri'

class Capybara::Driver::Mechanize
  def process_remote_request(method, url, *options)
    if remote?(url)
      remote_uri = URI.parse(url)
    
      @scheme = remote_uri.scheme if remote_uri.scheme 

      if remote_uri.host.nil?
        #TODO: Ascertain whether this is really true...
        if(method == :post && url == "" && @prev_url) #patch
          #require 'uri'
          #url = "http://#{URI.parse(@prev_url).host}#{URI.parse(@prev_url).path}"
          #p url
          url = @prev_url #patch
        else
          remote_host = @last_remote_host || Capybara.app_host || Capybara.default_host
          url = File.join(remote_host, url)
          #url = "http://#{url}" unless url.include?("http")
          url = "#{@scheme}://#{url}" unless url.match(/^http.*/)
        end
      else
        @last_remote_host = "#{remote_uri.host}:#{remote_uri.port}"
      end
      @prev_url = url #patch
      reset_cache
      @agent.send *( [method, url] + options)

      @last_request_remote = true
    end
  end
end
