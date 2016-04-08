require 'rubygems'
require 'bundler/setup'
require 'cucumber/configuration'
require 'cucumber/rb_support/rb_language'
require 'cucumber/runtime'
require 'rspec'
require 'capybara'

dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../lib"
c = Cucumber::Configuration.new
Cucumber::RbSupport::RbLanguage.new(Cucumber::Runtime.new, c) #Need to load Cucumber runtime, so World is available 

require 'frameworks/capybara'
require 'frameworks/cucumber'
require 'unit_test_monkeypatches.rb'
