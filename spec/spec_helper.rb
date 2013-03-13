require 'rubygems'
require 'bundler/setup'
require 'gherkin'
require 'cucumber/language_support/language_methods'
require 'cucumber/rb_support/rb_language'
require 'cucumber/runtime'
require 'rspec'
require 'capybara'

dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../lib"
Cucumber::RbSupport::RbLanguage.new(Cucumber::Runtime.new) #Need to load Cucumber runtime, so World is available 

require 'frameworks/capybara'
require 'frameworks/cucumber'
require 'monkey-patches/capybara-mechanize-patches'
require 'unit_test_monkeypatches.rb'
