require 'frameworks/capybara'
require 'monkey-patches/cucumber-patches'

module Frameworks
  module EnvHelper

    WWW_PREFIX = 'http://www.'
    STATIC_PREFIX = 'http://static.'
    OPEN_PREFIX = 'http://open.'
    BBC_DOMAIN = '.bbc.co.uk'
    STATIC_BBC_DOMAIN = '.bbci.co.uk'
    SANDBOX = 'http://pal.sandbox.dev'
    STATIC_SANDBOX = 'http://static.sandbox.dev'

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
        @base_url = "http://#{ENV[ENVIRONMENT]}" 
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

