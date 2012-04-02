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
        @static_base_url = @static_sandbox + @bbc_domain
      elsif (environment =='live' && ENV['WWW_LIVE']=='false')
        @base_url = @www_prefix.chop + @bbc_domain
        @static_base_url = @static_prefix.chop + @bbci_domain
        @open_base_url = @open_prefix.chop + @bbc_domain
      elsif (environment.split('.')[0].include? 'pal') #address specific box
        @base_url = "#{scheme}://#{ENV['ENVIRONMENT']}" 
      else
        @base_url = @www_prefix + environment + @bbc_domain
        @static_base_url = @static_prefix + environment + @bbci_domain
        @static_base_url = @static_prefix.chop + @bbci_domain if environment == 'live'
        @open_base_url = @open_prefix + environment + @bbc_domain
      end
      proxy = ENV['http_proxy'] || ENV['HTTP_PROXY'] 
      @proxy_host = proxy.scan(/http:\/\/(.*):80/).to_s if proxy
    end

    def validate_online(src)

      @validator = MarkupValidator.new({:proxy_host => @proxy_host,:proxy_port => 80})

      @validator.set_doctype!(:xhtml)
      results = @validator.validate_text(src)

      if results.errors.length > 0
        results.errors.each do |err|
          puts err.to_s
        end
        raise "W3C Validation of " + current_url + " failed."
      end
    end


    def set_scheme  
      ENV['SCHEME']=='https' ? scheme = 'https' : scheme = 'http'
      @www_prefix = "#{scheme}://www."
      @static_prefix = "#{scheme}://static."
      @open_prefix = "#{scheme}://open."
      @bbc_domain = '.bbc.co.uk'
      @bbci_domain = '.bbci.co.uk'
      @sandbox = "#{scheme}://pal.sandbox.dev"
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
  if page.driver.class == Capybara::Mechanize::Driver
    page.driver.browser.agent.cert, driver.browser.agent.key = ENV['FW_CERT_LOCATION'], ENV['FW_CERT_LOCATION'] if ENV['FW_CERT_LOCATION']
    page.driver.browser.agent.ca_file = ENV['CA_CERT_LOCATION'] if ENV['CA_CERT_LOCATION']
    page.driver.browser.agent.set_proxy('www-cache.reith.bbc.co.uk',80) if ENV['PROXY_URL']
  end

  generate_base_urls
end

