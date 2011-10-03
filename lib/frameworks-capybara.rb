require 'frameworks/cucumber'
require 'frameworks/capybara'

CapybaraSetup.new unless ENV['CAPYBARA_DISABLED']
