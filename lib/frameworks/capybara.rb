if Object.const_defined?(:Cucumber) && Object.respond_to?(:World)
  require 'capybara/cucumber'
  require 'capybara/mechanize/cucumber' 
end

#require 'capybara/cucumber'
require 'monkey-patches/webdriver-patches'
require 'monkey-patches/capybara-patches'
require 'monkey-patches/capybara-mechanize-patches'
require 'monkey-patches/mechanize-patches'
require 'monkey-patches/send-keys'
require 'selenium-webdriver'
#require 'capybara/mechanize/cucumber' 

class CapybaraSetup

  ERROR_MSG1 = 'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and PROXY_URL'
  ERROR_MSG2 = 'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), PROXY_URL (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)'


  attr_accessor :driver

  def initialize

    capybara_opts = {:environment => ENV['ENVIRONMENT'], :proxy => ENV['PROXY_URL'], :remote_browser_proxy_url => ENV['REMOTE_BROWSER_PROXY_URL'], :platform => ENV['PLATFORM'], :browser_name => ENV['REMOTE_BROWSER'], :version => ENV['REMOTE_BROWSER_VERSION'], :url => ENV['REMOTE_URL'], :profile => ENV['FIREFOX_PROFILE'], :browser => ENV['BROWSER'], :javascript_enabled => ENV['CELERITY_JS_ENABLED'], :job_name => ENV['SAUCE_JOB_NAME'], :max_duration => ENV['SAUCE_MAX_DURATION'], :proxy_on => ENV['PROXY_ON']}

    validate_env_vars(capybara_opts) #validate environment variables set using cucumber.yml or passed via command line

    @proxy_host =  capybara_opts[:proxy].gsub(/http:\/\//,'').gsub(/:80/,'') unless capybara_opts[:proxy].nil?
    capybara_opts[:browser] = capybara_opts[:browser].intern #update :browser value to be a symbol, required for Selenium
    capybara_opts[:browser_name] = capybara_opts[:browser_name].intern if capybara_opts[:browser_name]

    Capybara.run_server = false #Disable rack server

    capybara_opts.delete_if {|k,v| v.nil?}

    case capybara_opts[:browser] 
    when :headless then
      @driver = register_celerity_driver(capybara_opts)
    when :mechanize then
      @driver = register_mechanize_driver(capybara_opts)
    else
      @driver = register_selenium_driver(capybara_opts)
    end

    Capybara.default_driver = @driver

    if capybara_opts[:browser] == :mechanize
      Capybara.current_session.driver.agent.set_proxy(@proxy_host, 80) if capybara_opts[:proxy]
      Capybara.current_session.driver.agent.set_ssl_client_certification(ENV['CERT_LOCATION'], ENV['CERT_LOCATION'], ENV['CA_CERT_LOCATION']) if ENV['CERT_LOCATION']
    end
  end

  private

  def validate_env_vars(opts)
    [:environment, :browser].each do |item|
      opts.has_key?(item) && opts[item]==nil ? abort(ERROR_MSG1) : ''
    end

    opts.delete(:environment) #delete environment, only add to opts for conveniance when validating 


    if opts[:browser]=='remote'
      [:remote_url, :browser_name].each do |item|
        opts.has_key?(item) && opts[item]==nil ? abort(ERROR_MSG2) : '' 
      end
    end
  end

  def register_selenium_driver(opts)
    Capybara.register_driver :selenium do |app|

      if(opts[:profile] == 'BBC_INTERNAL')
        profile = Selenium::WebDriver::Firefox::Profile.new
        profile["network.proxy.type"] = 1
        profile["network.proxy.no_proxies_on"] = "*.sandbox.dev.bbc.co.uk"
        profile["network.proxy.http"] = @proxy_host 
        profile["network.proxy.ssl"] = @proxy_host 
        profile["network.proxy.http_port"] = 80
        profile["network.proxy.ssl_port"] = 80
        profile.native_events = true
        opts[:profile] = profile
      elsif(opts[:profile])
        profile = Selenium::WebDriver::Firefox::Profile.from_name opts[:profile]
        profile.native_events = true
        opts[:profile] = profile
      end

      if opts[:browser] == :remote
        client = Selenium::WebDriver::Remote::Http::Default.new

        #set proxy on client connection if required, note you may use ENV['PROXY_URL'] for setting in browser (ff profile) but not for client conection, hence allow for PROXY_ON=false
        if opts[:proxy] && opts[:proxy_on] != 'false'
          client.proxy = Selenium::WebDriver::Proxy.new(:http => opts[:proxy])
        end
        opts.delete_if {|k,v| [:proxy, :proxy_on].include? k} 

        #TODO: temp workaround - needs refactoring
        cap_opts = opts.clone
        cap_opts[:firefox_profile] = cap_opts.delete :profile
        cap_opts.delete :browser
        caps = Selenium::WebDriver::Remote::Capabilities.new(cap_opts)
        caps.custom_capabilities({:'job-name' => opts.delete(:job_name) || 'frameworks-unamed-job', :'max-duration' => opts.delete(:max_duration) || 1800}) if opts[:url].include? 'saucelabs' #set sauce specific parameters - will this scupper other on sauce remote jobs? 

        opts.delete_if {|k,v| [:browser_name, :platform, :profile, :version].include? k}  #remove options that would have been added to caps

        opts[:desired_capabilities] = caps
        opts[:http_client] = client
      else
        opts.delete_if {|k,v| [:proxy, :proxy_on].include? k} #may want to pass env variables that are not relevant for in browser 'non-remote' tests e.g. proxy, so delete these before setting up driver
      end
      Capybara::Driver::Selenium.new(app,opts)
    end   
    :selenium
  end

  def register_celerity_driver (opts)
    Capybara.register_driver :celerity do |app|
      opts.delete :browser #delete browser from options as value with  be 'headless'
      opts[:javascript_enabled] == 'true' ? opts[:javascript_enabled] = true : opts[:javascript_enabled] = false
      opts[:proxy] = "#{@proxy_host}:80" unless opts[:proxy].nil?
      Capybara::Driver::Celerity.new(app,opts)
    end
    :celerity
  end

  def register_mechanize_driver (opts)
    Capybara.register_driver :mechanize do |app|
      opts.delete :browser #delete browser from options as value with  be 'headless'
      Capybara.app_host = "http://www.int.bbc.co.uk"
      Capybara::Driver::Mechanize.new(app)
    end
    :mechanize
  end

end
