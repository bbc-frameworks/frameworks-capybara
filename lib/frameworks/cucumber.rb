require 'frameworks/capybara'
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

    ENV['SCHEME']=='https' ? scheme = 'https' : scheme = 'http'

    WWW_PREFIX = "#{scheme}://www."
    STATIC_PREFIX = "#{scheme}://static."
    OPEN_PREFIX = "#{scheme}://open."
    BBC_DOMAIN = '.bbc.co.uk'
    STATIC_BBC_DOMAIN = '.bbc.co.uk'
    SANDBOX = "#{scheme}://pal.sandbox.dev"
    STATIC_SANDBOX = "#{scheme}://static.sandbox.dev"

    #Generate base urls to use in Cucumber step defs
    def generate_base_urls 
      if(ENV['ENVIRONMENT']=='sandbox')
        @base_url = SANDBOX + BBC_DOMAIN 
        @static_base_url = STATIC_SANDBOX + BBC_DOMAIN
      elsif (ENV['ENVIRONMENT']=='live' && ENV['WWW_LIVE']=='false')
        @base_url = WWW_PREFIX + BBC_DOMAIN
        @static_base_url = STATIC_PREFIX + BBC_DOMAIN
        @open_base_url = OPEN_PREFIX + BBC_DOMAIN
      elsif (ENV['ENVIRONMENT'].split('.')[0].include? 'pal') #address specific box
        @base_url = "#{scheme}://#{ENV['ENVIRONMENT']}" 
      else
        @base_url = WWW_PREFIX + ENV['ENVIRONMENT'] + BBC_DOMAIN
        @static_base_url = STATIC_PREFIX + ENV['ENVIRONMENT'] + BBC_DOMAIN
        @open_base_url = OPEN_PREFIX + ENV['ENVIRONMENT'] + BBC_DOMAIN
      end
    end

  end #EnvHelper
end #Frameworks

CapybaraSetup.new unless ENV['CAPYBARA_DISABLED']

#Add module into world to ensure visibility of instance variables within Cucumber
World(Frameworks::EnvHelper)

#Call generate method in Before hook
Before do
  generate_base_urls
end

