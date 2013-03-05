require 'capybara/mechanize/cucumber' 
require 'uri'
class Capybara::Mechanize::Browser
  #patch to remove catching all Mechanize exceptions (which are nice and specific) and throwing a useless RuntimeError
  #patch to add Referer (Mechanize@0.3.0 won't add Referer for urls starting with http(s)://.)
  def process_remote_request(method, url, attributes, headers)
    if remote?(url)
      uri = URI.parse(url)
      uri = resolve_relative_url(url) if uri.host.nil?
      @last_remote_uri = uri
      url = uri.to_s

      referer = nil
      referer = Capybara::page.current_url unless Capybara::page.current_url.empty?

      reset_cache!
      args = []
      args << attributes unless attributes.empty?
      args << headers unless headers.empty?

      if method == :get
        agent.send(method, url, attributes, referer, headers)
      else
        agent.send(method, url, *args)
      end

      @last_request_remote = true
    end
  end
end

class Capybara::Mechanize::Driver
  #Patch for friendly cookie handling api
  def cookies
    cookies = []

    browser.agent.cookie_jar.jar.each do |domain|
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
    browser.agent.cookie_jar.jar.each do |domain|
      domain[1].each do |path|
        path[1].each do |cookie|
          if cookie[0] == cookie_name
            browser.agent.cookie_jar.jar[domain[0]][path[0]].delete(cookie[0])
          end
        end
      end
    end
  end

  def delete_all_cookies
    browser.agent.cookie_jar.clear!
  end

  def delete_cookies_in_domain(domain)
    cookies.each do |cookie|
      delete_cookie(cookie[:name]) if cookie[:domain].include?(domain)
    end
  end

  FakeURI = Struct.new(:host)
  def add_cookie(attribs)
    c = Mechanize::Cookie.new(attribs[:name],attribs[:value])
    # remember: mechanize always removes leading '.' from domains
    c.domain = attribs[:domain]
    c.path = '/'
    c.expires = attribs[:expires]
    c.secure = attribs[:secure]
    browser.agent.cookie_jar.add(FakeURI.new(c.domain),c)
  end
end
