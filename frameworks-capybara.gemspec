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
  s.rubygems_version = "1.3.6"
  s.summary = "Gem to ease the pain of managing capybara driver config and provide a home for common utils and patches"

  s.files         = `git ls-files`.split("\n")

  s.add_runtime_dependency("capybara", [">=1.0.0"])
  s.add_runtime_dependency("capybara-mechanize", [">=0.3.0"])
  s.add_runtime_dependency("capybara-webkit")
  s.add_runtime_dependency("json")
  s.add_runtime_dependency("headless")
  s.add_runtime_dependency("capybara-celerity")
  s.add_runtime_dependency("w3c_validators")
  s.add_runtime_dependency("cucumber", [">= 0.10.5"])
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec", [">=1.0.0"])
end
