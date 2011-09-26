dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../lib"
 
require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'capybara'
require 'frameworks/capybara'
