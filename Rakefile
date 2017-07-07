require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

Bundler::GemHelper.install_tasks

desc 'Run all examples'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
end
task default: [:spec]
