require 'frameworks/cucumber'
require 'frameworks/capybara'
require 'frameworks/wait'
require 'frameworks/utils'
require 'frameworks/logger'

CapybaraSetup.new unless ENV['CAPYBARA_DISABLED']
