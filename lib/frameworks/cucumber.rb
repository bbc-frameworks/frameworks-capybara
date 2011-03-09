require 'frameworks/capybara'

module Frameworks
  module EnvHelper
    WWW_PREFIX = 'http://www.'
    BBC_DOMAIN = '.bbc.co.uk'
    SANDBOX = 'http://pal.sandbox.dev'

    def generate_base_url 
      if(ENV['ENVIRONMENT']=='sandbox')
        @base_url = SANDBOX + BBC_DOMAIN 
      else
        @base_url = WWW_PREFIX + ENV['ENVIRONMENT'] + BBC_DOMAIN
      end
    end

  end
end

#Set Capybara Driver - using frameworks-capybara gem 
Capybara.default_driver = CapybaraSetup.new.driver

World(Frameworks::EnvHelper)

Before do
 generate_base_url
end

