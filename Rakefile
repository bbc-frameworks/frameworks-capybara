require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "frameworks-capybara"
  gem.homepage = "http://github.com/mcrmfc/frameworks-capybara"
  gem.license = "MIT"
  gem.summary = %Q{gem to aid setup of Capybara for testing bbc sites}
  gem.description = %Q{gem to aid setup of Capybara for testing bbc sites}
  gem.email = "mcrobbins@gmail.com"
  gem.authors = ["mcrmfc"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'capybara', '>=0'
  gem.add_runtime_dependency 'capybara-mechanize', '>=0'
  gem.add_runtime_dependency 'w3c_validators', '>=0'
  gem.add_runtime_dependency 'headless', '>=0'
  gem.add_development_dependency 'rspec', '>=2.6.0'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "frameworks-capybara #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
