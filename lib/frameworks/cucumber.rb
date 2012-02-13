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
      set_scheme
      if(ENV['ENVIRONMENT']=='sandbox')
        @base_url = @sandbox + @bbc_domain 
        @static_base_url = @static_sandbox + @bbc_domain
      elsif (ENV['ENVIRONMENT']=='live' && ENV['WWW_LIVE']=='false')
        @base_url = @www_prefix.chop + @bbc_domain
        @static_base_url = @static_prefix.chop + @bbc_domain
        @open_base_url = @open_prefix.chop + @bbc_domain
      elsif (ENV['ENVIRONMENT'].split('.')[0].include? 'pal') #address specific box
        @base_url = "#{scheme}://#{ENV['ENVIRONMENT']}" 
      else
        @base_url = @www_prefix + ENV['ENVIRONMENT'] + @bbc_domain
        @static_base_url = @static_prefix + ENV['ENVIRONMENT'] + @bbc_domain
        @static_base_url = @static_prefix.chop + @bbc_domain if ENV['ENVIRONMENT'] == 'live'
        @open_base_url = @open_prefix + ENV['ENVIRONMENT'] + @bbc_domain
      end
      proxy = ENV['http_proxy'] || ENV['HTTP_PROXY'] 
      @proxy_host = ENV['http_proxy'].scan(/http:\/\/(.*):80/).to_s if proxy
    end

    def validate_online(src)

      @validator = MarkupValidator.new({:proxy_host => @proxy_host,:proxy_port => 80})

      @validator.set_doctype!(:xhtml)
      results = @validator.validate_text(src)

      if results.errors.length > 0
        results.errors.each do |err|
          puts err.to_s
        end
        raise "W3C Validation of " + url + " failed."
      end
    end


    def set_scheme  
      ENV['SCHEME']=='https' ? scheme = 'https' : scheme = 'http'
      @www_prefix = "#{scheme}://www."
      @static_prefix = "#{scheme}://static."
      @open_prefix = "#{scheme}://open."
      @bbc_domain = '.bbc.co.uk'
      @sandbox = "#{scheme}://pal.sandbox.dev"
      @static_sandbox = "#{scheme}://static.sandbox.dev"
    end

  end #EnvHelper
end #Frameworks


#Add module into world to ensure visibility of instance variables within Cucumber
World(Frameworks::EnvHelper)

#Call generate method in Before hook
Before do
  generate_base_urls
end

