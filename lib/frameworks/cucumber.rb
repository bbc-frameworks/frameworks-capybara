require 'frameworks/capybara'
require 'w3c_validators'
require 'monkey-patches/cucumber-patches'

#This is hackish but means we only run once in cucumber and not every scenario
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

      prepare_host

      if(environment =='sandbox')
        @base_url = @sandbox + @bbc_domain 
        @pal_base_url = @sandbox + @bbc_domain 
        @ssl_base_url = @sslsandbox + @bbc_domain
        @static_base_url = @static_sandbox + @bbc_domain
        @mobile_base_url = @mobiledot_prefix + "sandbox.dev" + @bbc_domain
        @m_base_url = @mdot_prefix + "sandbox.dev" + @bbc_domain
      elsif(environment =='sandbox6')
        @base_url = @sandbox6 + @bbc_domain 
        @pal_base_url = @sandbox6 + @bbc_domain 
        @ssl_base_url = @sslsandbox6 + @bbc_domain
        @static_base_url = @static_sandbox6 + @bbc_domain
        @mobile_base_url = @mobiledot_prefix + "sandbox" + @bbc_domain
        @m_base_url = @mdot_prefix + "sandbox" + @bbc_domain
      elsif (environment =='live' && ENV['WWW_LIVE']=='false')
        @base_url = @www_prefix.chop + @bbc_domain
        @pal_base_url = @pal_prefix + environment + @bbc_domain
        @ssl_base_url = @ssl_prefix.chop + @bbc_domain
        @static_base_url = @static_prefix.chop + @bbci_domain
        @open_base_url = @open_prefix.chop + @bbc_domain
        @mobile_base_url = @mobiledot_prefix.chop + @bbc_domain
        @m_base_url = @mdot_prefix.chop + @bbc_domain
      else
        @base_url = @www_prefix + environment + @bbc_domain
        @pal_base_url = @pal_prefix + environment + @bbc_domain
        @ssl_base_url = @ssl_prefix + environment + @bbc_domain
        @static_base_url = @static_prefix + environment + @bbci_domain
        @static_base_url = @static_prefix.chop + @bbci_domain if environment == 'live'
        @open_base_url = @open_prefix + environment + @bbc_domain
        @mobile_base_url = @mobiledot_prefix + environment + @bbc_domain
        @m_base_url = @mdot_prefix + environment + @bbc_domain
      end

      proxy = ENV['http_proxy'] || ENV['HTTP_PROXY'] 
      proxy_parts = proxy.scan(/(?:http:\/\/)?([^\:]+)(?::(\d+))?/) if proxy && !proxy.empty?
      if proxy_parts && !proxy_parts.empty?
          @proxy_host = proxy_parts[0][0]
          if proxy_parts[0][1]
              @proxy_port = proxy_parts[0][1]
          else
              @proxy_port = "80"
          end
      end
    end

    def validate_online(src, validator_args = nil)

      args = {:proxy_host => @proxy_host,:proxy_port => @proxy_port} 
      if(validator_args != nil)
         args = args.merge(validator_args)
      end    
      @validator = MarkupValidator.new(args)

      @validator.set_doctype!(:xhtml)
      begin

        results = @validator.validate_text(src)

        if results.errors.length > 0
          results.errors.each do |err|
            puts err.to_s
          end
          raise "W3C Validation failed."
        end

      rescue SystemCallError => e
        puts "System error whilst performing request to W3C: #{e}"  
      end
    end

    def prepare_host
      ENV['SCHEME']=='https' ? scheme = 'https' : scheme = 'http'
      @www_prefix = "#{scheme}://www."
      @pal_prefix = "#{scheme}://pal."
      @ssl_prefix = "https://ssl."
      @static_prefix = "#{scheme}://static."
      @open_prefix = "#{scheme}://open."
      @bbc_domain = '.' + (ENV['FW_BBC_DOMAIN'] || 'bbc.co.uk')
      @bbci_domain = '.bbci.co.uk'
      @sandbox = "#{scheme}://pal.sandbox.dev"
      @sandbox6 = "#{scheme}://sandbox"
      @mobiledot_prefix = "#{scheme}://mobile."
      @mdot_prefix = "#{scheme}://m."
      @sslsandbox = "https://ssl.sandbox.dev"
      @sslsandbox6 = "https://ssl.sandbox"
      @static_sandbox = "#{scheme}://static.sandbox.dev"
      @static_sandbox6 = "#{scheme}://static.sandbox"      
    end

    def setup_mechanize(agent, http_proxy=nil)
      http_proxy = http_proxy || ENV['HTTP_PROXY'] || ENV['http_proxy']

      if ENV['FW_CERT_LOCATION']
        agent.cert, agent.key = ENV['FW_CERT_LOCATION'], ENV['FW_CERT_LOCATION'] 
      end

      agent.ca_file = ENV['CA_CERT_LOCATION'] if ENV['CA_CERT_LOCATION']
      agent.set_proxy(http_proxy.scan(/http:\/\/(.*):80/)[0][0].to_s,80) if http_proxy && !http_proxy.empty?

      #This is necessary because Mech2 does not ship with root certs like Mech1 did and boxes may not have the OpenSSL set installed
      agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

      # This prevents Mechanize from raising a Mechanize::ResponseCodeError
      # when the HTTP Response Code is 404 or 503. This lets capybara continue the journey.
      agent.agent.allowed_error_codes = ['404', '503']
    end

    def new_mechanize(http_proxy=nil)
      require 'mechanize'
      agent = Mechanize.new
      setup_mechanize(agent, http_proxy)
      agent
    end

  end #EnvHelper
end #Frameworks


#Add module into world to ensure visibility of instance variables within Cucumber
World(Frameworks::EnvHelper)

#Call generate method in Before hook
Before do
  #This is ugly but unavoidable since Capybara::RackTest::Driver.reset_host! does @browser = nil and wipes all brower level settings
  #it was either this or a monkey patch - need to think about pushing a softer reset change to capybara-mechanize to override this
  setup_mechanize(page.driver.browser.agent) if page.driver.class == Capybara::Mechanize::Driver

  generate_base_urls
end

