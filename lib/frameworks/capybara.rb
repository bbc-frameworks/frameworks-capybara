require 'capybara/cucumber'
require 'monkey-patches/webdriver-patches'
require 'monkey-patches/capybara-patches'
require 'monkey-patches/capybara-mechanize-patches'
require 'monkey-patches/mechanize-patches'
require 'monkey-patches/send-keys'
require 'monkey-patches/net-http-persistent-patches'
require 'selenium-webdriver'
require 'capybara/mechanize/cucumber' 
require 'capybara/celerity'

class CapybaraSetup

  attr_reader :driver

  def initialize

    http_proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']

    capybara_opts = {:environment => ENV['ENVIRONMENT'],
      :proxy => http_proxy,
      :profile => ENV['FIREFOX_PROFILE'],
      :browser => ENV['BROWSER'],
      :javascript_enabled => ENV['CELERITY_JS_ENABLED'],
      :proxy_on => ENV['PROXY_ON'],
      :url => ENV['REMOTE_URL'],
      :chrome_switches => ENV['CHROME_SWITCHES'],
      :firefox_prefs => ENV['FIREFOX_PREFS']}

    selenium_remote_opts = {:platform => ENV['PLATFORM'],
      :browser_name => ENV['REMOTE_BROWSER'],
      :version => ENV['REMOTE_BROWSER_VERSION'],
      :url => ENV['REMOTE_URL']}

    custom_opts = {:job_name => ENV['SAUCE_JOB_NAME'],
      :max_duration => ENV['SAUCE_MAX_DURATION']}

    validate_env_vars(capybara_opts.merge(selenium_remote_opts)) #validate environment variables set using cucumber.yml or passed via command line

    @proxy_host =  capybara_opts[:proxy].gsub(/http:\/\//,'').gsub(/:80.*/,'') unless capybara_opts[:proxy].nil?
    capybara_opts[:browser] = capybara_opts[:browser].intern #update :browser value to be a symbol, required for Selenium
    selenium_remote_opts[:browser_name] = selenium_remote_opts[:browser_name].intern if selenium_remote_opts[:browser_name]#update :browser value to be a symbol, required for Selenium

    Capybara.run_server = false #Disable rack server

    [capybara_opts, selenium_remote_opts, custom_opts].each do |opts| #delete nil options and environment (which is only used for validation)

      opts.delete_if {|k,v| (v.nil? or k == :environment)}
    end

    case capybara_opts[:browser] 
    when :headless then
      @driver = register_celerity_driver(capybara_opts)
    when :mechanize then
      @driver = register_mechanize_driver(capybara_opts)
    else
      @driver = register_selenium_driver(capybara_opts, selenium_remote_opts, custom_opts)
    end

    Capybara.default_driver = @driver
  end

  private

  def validate_env_vars(opts)

    msg1 = 'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and HTTP_PROXY (if required)'
    msg2 = 'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), HTTP_PROXY (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)'

    [:environment, :browser].each do |item|
      !opts.has_key?(item) or opts[item]==nil ? raise(msg1) : '' 
    end

    if opts[:browser]=='remote'
      [:url, :browser_name].each do |item|
        !opts.has_key?(item) or opts[item]==nil ? raise(msg2) : '' 
      end
    end
  end

  def register_selenium_driver(opts,remote_opts,custom_opts)
    Capybara.register_driver :selenium do |app|

      if opts[:firefox_prefs] || opts[:profile]
        opts[:profile] = create_profile(opts[:profile], opts[:firefox_prefs])
      end

      opts[:switches] = [opts.delete(:chrome_switches)] if(opts[:chrome_switches])

      if opts[:browser] == :remote
        client = Selenium::WebDriver::Remote::Http::Default.new
        client.proxy = set_client_proxy(opts)

        remote_opts[:firefox_profile] = opts.delete :profile if opts[:profile]
        remote_opts['chrome.switches'] = opts.delete :switches if opts[:switches]
        caps = Selenium::WebDriver::Remote::Capabilities.new(remote_opts)

        add_custom_caps(caps, custom_opts) if remote_opts[:url].include? 'saucelabs' #set sauce specific parameters - will this scupper other on sauce remote jobs? 

        opts[:desired_capabilities] = caps
        opts[:http_client] = client
      end

      clean_opts(opts, :proxy, :proxy_on, :firefox_prefs)
      Capybara::Selenium::Driver.new(app,opts)
    end   
    :selenium
  end

  def add_custom_caps(caps, custom_opts)
    sauce_time_limit = custom_opts.delete(:max_duration).to_i #note nil.to_i == 0 
    caps.custom_capabilities({:'job-name' => (custom_opts[:job_name] or 'frameworks-unamed-job'), :'max-duration' => ((sauce_time_limit if sauce_time_limit != 0) or 1800)}) 
  end

  def set_client_proxy(opts)
    Selenium::WebDriver::Proxy.new(:http => opts[:proxy]) if opts[:proxy] && opts[:proxy_on] != 'false' #set proxy on client connection if required, note you may use ENV['HTTP_PROXY'] for setting in browser (ff profile) but not for client conection, hence allow for PROXY_ON=false
  end

  def create_profile(profile_name = nil, additional_prefs = nil)
    additional_prefs = JSON.parse(additional_prefs) if additional_prefs
    if(additional_prefs && !profile_name)
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.native_events = true
    elsif(profile_name == 'BBC_INTERNAL')
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile["network.proxy.type"] = 1
      profile["network.proxy.no_proxies_on"] = "*.sandbox.dev.bbc.co.uk"
      profile["network.proxy.http"] = @proxy_host 
      profile["network.proxy.ssl"] = @proxy_host 
      profile["network.proxy.http_port"] = 80
      profile["network.proxy.ssl_port"] = 80
      profile.native_events = true
    else
      profile = Selenium::WebDriver::Firefox::Profile.from_name profile_name
      profile.native_events = true
    end

    if additional_prefs
      additional_prefs.each do |k, v|
        profile[k] = v
      end
    end

    profile
  end

  def register_celerity_driver(opts)
    Capybara.register_driver :celerity do |app|
      opts.delete :browser #delete browser from options as value with  be 'headless'
      opts[:javascript_enabled] == 'true' ? opts[:javascript_enabled] = true : opts[:javascript_enabled] = false
      opts[:proxy] = "#{@proxy_host}:80" unless opts[:proxy].nil?
      Capybara::Driver::Celerity.new(app,opts)
    end
    :celerity
  end

  def register_mechanize_driver(opts)
    Capybara.register_driver :mechanize do |app|
      Capybara.app_host = "http://www.bbc.co.uk"
      Capybara::Mechanize::Driver.new(app)
    end
    :mechanize
  end


  def clean_opts(opts, *args)
    args.each do |arg|
      opts.delete arg
    end
  end

end
