class RakeHelpers
  INVOKE_CUCUMBER = "bin/cucumber -r features"

  class << self
    def install
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

    def list_profiles
      puts 'Available profiles:' 
      f =  File.open('config/cucumber.yml', 'r')
      linenum = 0
      @profiles = {}
      f.readlines.each do |line|
        line.scan(/.*?: /) do |match|
          linenum += 1
          puts color(linenum.to_s + '. ', :color => :yellow) + color(match.gsub(':',''), :color => :green)
          @profiles[linenum.to_s] = match.gsub(':','')
        end
      end
    end

    def update
      system('bundle update') 
    end

    def run_feature(feature, profile='default')
      system("#{INVOKE_CUCUMBER} -p #{profile} features/#{feature}.feature")
    end

    def run_profile(profile='default')
      system("#{INVOKE_CUCUMBER} -p #{profile}")
    end


    def start_app
      $: << File.dirname( __FILE__)
      require 'lib/spec/test_app'
      Rack::Handler::WEBrick.run TestApp, :Port => 8070
    end

    def run_local
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
      list_profiles
      puts 'Above is a list of the available profiles, please enter the number of the profile you wish to run: '
      profile = STDIN.gets.chomp
      #TODO: Add some input validation?
      puts "The profile chosen is: #{color(@profiles[profile], :color => :red)}"
      puts 'Preparing to bundle required gems...'
      install
      puts 'Preparing to run tests...'
      run_profile(@profiles[profile])
    end
  end
end
