require 'frameworks/cucumber'
require 'frameworks/capybara'
require 'frameworks/wait'

CapybaraSetup.new unless ENV['CAPYBARA_DISABLED']
