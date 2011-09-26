#require 'capybara/mechanize/cucumber' 
if Object.const_defined?(:Cucumber) && Object.respond_to?(:World)
  require 'capybara/mechanize/cucumber'
end

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
  
  def cookies
    cookies = []
    
    agent.cookie_jar.jar.each do |domain|
      domain[1].each do |path|
        path[1].each do |cookie|
          cookies.push({
            :name => cookie[1].name,
            :value => cookie[1].value,
            :domain => cookie[1].domain,
            :secure => cookie[1].secure,
            :expires => cookie[1].expires,
            :path => cookie[1].path
          })
        end
      end
    end
    cookies
  end
  
  def cookie_named(name)
    cookies.find { |c| c[:name] == name }
  end
  
  def delete_cookie(cookie_name)
    agent.cookie_jar.jar.each do |domain|
      domain[1].each do |path|
        path[1].each do |cookie|
          if cookie[0] == cookie_name
            agent.cookie_jar.jar[domain[0]][path[0]].delete(cookie[0])
          end
        end
      end
    end
  end
  
  def delete_all_cookies
    agent.cookie_jar.clear!
  end
  
 FakeURI = Struct.new(:host)
 def add_cookie(attribs)
    c = Mechanize::Cookie.new(attribs[:name],attribs[:value])
    # remember: mechanize always removes leading '.' from domains
    c.domain = attribs[:domain].sub!(/^./, '')
    c.path = '/'
    c.expires = attribs[:expires]
    c.secure = attribs[:secure]
    agent.cookie_jar.add(FakeURI.new(c.domain),c)
  end
end
