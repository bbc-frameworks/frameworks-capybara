INVOKE_CUCUMBER = "bin/cucumber"

task :install do
  system('bundle install --no-cache --binstubs --path vendor/bundle') 
end

def color(text, options = {})
  #ANSI color codes
  case options[:color]
  when :red
    text = "\033[31m#{text}\033[0m"
  when :green
    text = "\033[32m#{text}\033[0m"
  when :yellow
    text = "\033[33m#{text}\033[0m"
  end
  text
end

task :list_profiles do
  puts 'Available profiles:' 
  f =  File.open('config/cucumber.yml', 'r')
  linenum = 0
  @profiles = {}
  f.read.each do |line|
    line.scan(/.*?: /) do |match|
      linenum += 1
      puts color(linenum.to_s + '. ', :color => :yellow) + color(match.gsub(':',''), :color => :green)
      @profiles[linenum.to_s] = match.gsub(':','')
    end
  end
end

task :update do
  system('bundle update') 
end

task :run_feature, :feature, :profile do |t, args|
  args.with_defaults(:profile => 'default')
  system("#{INVOKE_CUCUMBER} -p #{args[:profile]} features/#{args[:feature]}.feature")
end

task :run_profile, :profile do |t, args|
  args.with_defaults(:profile => 'default')
  system("#{INVOKE_CUCUMBER} -p #{args[:profile]}")
end


task :start_app do
  $: << File.dirname( __FILE__)
  require 'lib/spec/test_app'
  Rack::Handler::WEBrick.run TestApp, :Port => 8070
end

task :run_local do
  if(RUBY_PLATFORM == 'java')
    abort color("This script only works if you are running on MRI ('normal') Ruby....sorry....", :color => :red) 
  end
  puts color('*********************************************',:color => :green)
  puts color('*                                           *',:color => :green)
  puts color('* Cucumber Acceptance Tests                 *',:color => :green)
  puts color('* Pre-Requisites:                           *',:color => :green)
  puts color('* ruby 1.8.7, bundler, rake                 *',:color => :green)
  puts color('*                                           *',:color => :green)
  puts color('*********************************************',:color => :green)
  Rake::Task[:list_profiles].invoke
  puts 'Above is a list of the available profiles, please enter the number of the profile you wish to run: '
  profile = STDIN.gets.chomp
  #TODO: Add some input validation?
  puts "The profile chosen is: #{color(@profiles[profile], :color => :red)}"
  puts 'Preparing to bundle required gems...'
  Rake::Task[:install].invoke
  puts 'Preparing to run tests...'
  Rake::Task[:run_profile].invoke(@profiles[profile])
end
