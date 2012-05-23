require 'frameworks/capybara'
require 'w3c_validators'
require 'monkey-patches/cucumber-patches'

if(ENV['XVFB']=='true')
  puts "You have chosen to use XVFB - ensure you have yum installed Xvfb Xorg and firefox"
  require 'headless'
  headless = Headless.new
  headless.start
  at_exit do
    headless.destroy
  end
end

module Frameworks
  module EnvHelper
    include W3CValidators
    #Generate base urls to use in Cucumber step defs
    def generate_base_urls 
      environment = ENV['ENVIRONMENT'].downcase #be defensive

      set_scheme

      if(environment =='sandbox')
        @base_url = @sandbox + @bbc_domain 
        @ssl_base_url = @sslsandbox + @bbc_domain
        @static_base_url = @static_sandbox + @bbc_domain
      elsif (environment =='live' && ENV['WWW_LIVE']=='false')
        @base_url = @www_prefix.chop + @bbc_domain
        @ssl_base_url = @ssl_prefix.chop + @bbc_domain
        @static_base_url = @static_prefix.chop + @bbci_domain
        @open_base_url = @open_prefix.chop + @bbc_domain
      elsif (environment.split('.')[0].include? 'pal') #address specific box
        @base_url = "#{scheme}://#{ENV['ENVIRONMENT']}" 
      else
        @base_url = @www_prefix + environment + @bbc_domain
        @ssl_base_url = @ssl_prefix + environment + @bbc_domain
        @static_base_url = @static_prefix + environment + @bbci_domain
        @static_base_url = @static_prefix.chop + @bbci_domain if environment == 'live'
        @open_base_url = @open_prefix + environment + @bbc_domain
      end

      proxy = ENV['http_proxy'] || ENV['HTTP_PROXY'] 
      @proxy_host = proxy.scan(/http:\/\/(.*):80/)[0][0] if proxy
    end

    def validate_online(src)

      @validator = MarkupValidator.new({:proxy_host => @proxy_host,:proxy_port => 80})

      @validator.set_doctype!(:xhtml)
      begin

        results = @validator.validate_text(src)

        if results.errors.length > 0
          results.errors.each do |err|
            puts err.to_s
          end
          raise "W3C Validation of " + current_url + " failed."
        end

      rescue Net::HTTPFatalError => e
        puts "WARNING - OUTGOING NETWORK ERROR FROM FORGE TO W3C - Validation Not Performed"
      end
    end

    def set_scheme  
      ENV['SCHEME']=='https' ? scheme = 'https' : scheme = 'http'
      @www_prefix = "#{scheme}://www."
      @ssl_prefix = "https://ssl."
      @static_prefix = "#{scheme}://static."
      @open_prefix = "#{scheme}://open."
      @bbc_domain = '.bbc.co.uk'
      @bbci_domain = '.bbci.co.uk'
      @sandbox = "#{scheme}://pal.sandbox.dev"
      @sslsandbox = "https://ssl.sandbox.dev"
      @static_sandbox = "#{scheme}://static.sandbox.dev"
    end

  end #EnvHelper
end #Frameworks


#Add module into world to ensure visibility of instance variables within Cucumber
World(Frameworks::EnvHelper)

#Call generate method in Before hook
Before do
  #This is ugly but unavoidable since Capybara::RackTest::Driver.reset_host! does @browser = nil and wipes all brower level settings
  #it was either this or a monkey patch - need to think about pushing a softer reset change to capybara-mechanize to override this
  http_proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
  if page.driver.class == Capybara::Mechanize::Driver

    if ENV['FW_CERT_LOCATION']
      page.driver.browser.agent.cert, page.driver.browser.agent.key = 
        ENV['FW_CERT_LOCATION'],
        ENV['FW_CERT_LOCATION'] 
    end

    page.driver.browser.agent.ca_file = ENV['CA_CERT_LOCATION'] if ENV['CA_CERT_LOCATION']

    #TODO: Fix proxy logic globally...use system proxy instead of PROXY_URL
    page.driver.browser.agent.set_proxy(http_proxy.scan(/http:\/\/(.*):80/).to_s,80) if http_proxy

    #This is necessary because Mech2 does not ship with root certs like Mech1 did and boxes may not have the OpenSSL set installed
    page.driver.browser.agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  generate_base_urls
end

