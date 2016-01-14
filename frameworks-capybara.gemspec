# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'version'

Gem::Specification.new do |s|
  s.name = "frameworks-capybara"
  s.version = FrameworksCapybara::VERSION

  s.authors = ["matt robbins"]
  s.email = ["mcrobbins@gmail.com"]
  s.description = "Gem to ease the pain of managing capybara driver config and provide a home for common utils and patches"

  s.files = Dir.glob("{features,lib,bin,config,vendor,.bundle}/**/*") +  %w(Gemfile Gemfile.lock)

  s.require_paths = ["lib"]
  s.rubygems_version = "2.4.2"
  s.summary = "Gem to ease the pain of managing capybara driver config and provide a home for common utils and patches"

  s.files         = `git ls-files`.split("\n")

  s.add_runtime_dependency("selenium-webdriver")
  s.add_runtime_dependency("capybara", '~> 2.5')
  s.add_runtime_dependency("mechanize")
  s.add_runtime_dependency("capybara-mechanize")
  s.add_runtime_dependency("poltergeist")
  s.add_runtime_dependency("json")
  s.add_runtime_dependency("cucumber")
  s.add_runtime_dependency("logging")
  s.add_runtime_dependency("show_me_the_cookies")
  s.add_runtime_dependency("w3c_validators")
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
end
