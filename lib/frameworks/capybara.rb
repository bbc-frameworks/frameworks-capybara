require 'capybara'
require 'capybara/cucumber'
require 'capybara/mechanize'
require 'capybara/poltergeist'
require 'selenium-webdriver'
require 'extensions/capybara-extensions'
require 'extensions/capybara-mechanize-extensions'
require 'extensions/patches'

class CapybaraSetup

  attr_reader :driver

  def initialize

    http_proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
    browser_cli_args = ENV['BROWSER_CLI_ARGS'].split(/\s+/).compact if ENV['BROWSER_CLI_ARGS']

    capybara_opts = {:environment => ENV['ENVIRONMENT'],
      :http_proxy => http_proxy,
      :profile => ENV['FIREFOX_PROFILE'],
      :browser => ENV['BROWSER'],
      :webdriver_proxy_on => ENV['PROXY_ON'],
      :url => ENV['REMOTE_URL'],
      :chrome_switches => ENV['CHROME_SWITCHES'],
      :firefox_prefs => ENV['FIREFOX_PREFS'],
      :args => browser_cli_args
    }

    selenium_remote_opts = {:os => ENV['PLATFORM'],
      :os_version => ENV['PLATFORM_VERSION'],
      :browser_name => ENV['REMOTE_BROWSER'],
      :browser_version => ENV['REMOTE_BROWSER_VERSION'],
      :url => ENV['REMOTE_URL']
    }

    custom_opts = {:job_name => ENV['SAUCE_JOB_NAME'],
      :max_duration => ENV['SAUCE_MAX_DURATION'],
      :firefox_cert_path => ENV['FIREFOX_CERT_PATH'],
      :firefox_cert_prefix => ENV['FIREFOX_CERT_PREFIX'],
      :browserstack_build => ENV['BS_BUILD'],
      :browserstack_debug => ENV['BS_DEBUG'] || 'true', # BrowserStack debug mode on by default
      :browserstack_device => ENV['BS_DEVICE'],
      :browserstack_device_orientation => ENV['BS_DEVICE_ORIENTATION'],
      :browserstack_project => ENV['BS_PROJECT'],
      :browserstack_resolution => ENV['BS_RESOLUTION'],
      :appium_platform => ENV['APPIUM_PLATFORM'],
      :appium_device => ENV['APPIUM_DEVICE'],
      :appium_browser => ENV['APPIUM_BROWSER'],
      :appium_udid => ENV['APPIUM_UDID']
    }

    validate_env_vars(capybara_opts.merge(selenium_remote_opts), custom_opts) #validate environment variables set using cucumber.yml or passed via command line

    if(capybara_opts[:http_proxy])
      proxy_uri = URI(capybara_opts[:http_proxy])
      @proxy_host = proxy_uri.host
      @proxy_port = proxy_uri.port
    end
    capybara_opts[:browser] = capybara_opts[:browser].intern #update :browser value to be a symbol, required for Selenium
    selenium_remote_opts[:browser_name] = selenium_remote_opts[:browser_name].intern if selenium_remote_opts[:browser_name]#update :browser value to be a symbol, required for Selenium

    Capybara.run_server = false #Disable rack server

    [capybara_opts, selenium_remote_opts, custom_opts].each do |opts| #delete nil options and environment (which is only used for validation)

      opts.delete_if {|k,v| (v.nil? or k == :environment)}
    end

    # always register in case we are using a configuration that swaps between drivers
    mech_driver = register_mechanize_driver(capybara_opts)
    poltergeist_driver = register_poltergeist_driver(capybara_opts)
    case capybara_opts[:browser]
    when :mechanize then
      @driver = mech_driver
    when :poltergeist then
      @driver = poltergeist_driver
    else
      @driver = register_selenium_driver(capybara_opts, selenium_remote_opts, custom_opts)
    end

    Capybara.default_driver = @driver
  end

  private

  def validate_env_vars(opts, custom_opts)
    msg1 = 'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and HTTP_PROXY (if required)'
    msg2 = 'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), HTTP_PROXY (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)'

    [:environment, :browser].each { |item| !opts.has_key?(item) or opts[item]==nil ? raise(msg1) : '' }

    if custom_opts[:appium_platform]
      [:url].each { |item| !opts.has_key?(item) or opts[item]==nil ? raise(msg2) : '' }
    elsif opts[:browser]=='remote'
      [:url, :browser_name].each { |item| !opts.has_key?(item) or opts[item]==nil ? raise(msg2) : '' }
    end
  end

  # WARNING: This modifies the Firefox profile passed in the parameters
  def update_firefox_profile_with_certificates(profile, certificate_path, certificate_prefix = '')
    profile_path = profile.layout_on_disk

    # Create links to the certificate files in the profile directory
    ['cert8.db', 'key3.db', 'secmod.db'].each do |cert_file|
      source_file = "#{certificate_prefix}#{cert_file}"
      source_path = "#{certificate_path}" + File::SEPARATOR + source_file
      dest_path = profile_path + File::SEPARATOR + cert_file
      if(! File.exist?(source_path))
        raise "Firefox cert db file #{source_path} does not exist."
      end
      FileUtils.cp(source_path, dest_path)
    end

    # Force the certificates to get pulled into the profile
    profile = Selenium::WebDriver::Firefox::Profile.new(profile_path)

    # Avoid Firefox certificate alerts
    profile["security.default_personal_cert"] = 'Select Automatically'

    return profile
  end

  def register_selenium_driver(opts,remote_opts,custom_opts)
    Capybara.register_driver :selenium do |app|

      if opts[:firefox_prefs] || opts[:profile]
        opts[:profile] = create_profile(opts[:profile], opts[:firefox_prefs])

        if custom_opts[:firefox_cert_path]
          opts[:profile] = update_firefox_profile_with_certificates(opts[:profile], custom_opts[:firefox_cert_path], custom_opts[:firefox_cert_prefix])
        end
      end

      opts[:switches] = [opts.delete(:chrome_switches)] if(opts[:chrome_switches])

      if opts[:browser] == :remote
        client = Selenium::WebDriver::Remote::Http::Default.new
        client.proxy = set_client_proxy(opts)

        remote_opts[:firefox_profile] = opts.delete :profile if opts[:profile]
        remote_opts['chrome.switches'] = opts.delete :switches if opts[:switches]
        caps = Selenium::WebDriver::Remote::Capabilities.new(remote_opts)

        add_custom_caps(caps, custom_opts) if remote_opts[:url].include? 'saucelabs' #set sauce specific parameters - will this scupper other on sauce remote jobs?

        add_browserstack_caps(caps, custom_opts) if remote_opts[:url].include? 'browserstack' #set browserstack specific parameters

        add_appium_caps(caps, custom_opts) if custom_opts.keys.join.include?('appium')  #set appium specific parameters

        opts[:desired_capabilities] = caps
        opts[:http_client] = client
      end

      clean_opts(opts, :http_proxy, :webdriver_proxy_on, :firefox_prefs)
      Capybara::Selenium::Driver.new(app,opts)
    end
    :selenium
  end

  def add_custom_caps(caps, custom_opts)
    sauce_time_limit = custom_opts.delete(:max_duration).to_i #note nil.to_i == 0
    # This no longer works with the latest selenium-webdriver release
    #caps.custom_capabilities({:'job-name' => (custom_opts[:job_name] or 'frameworks-unamed-job'), :'max-duration' => ((sauce_time_limit if sauce_time_limit != 0) or 1800)})
  end

  def add_browserstack_caps(caps, custom_opts)
    caps[:'build'] = custom_opts[:browserstack_build] if custom_opts[:browserstack_build]
    caps[:'browserstack.debug'] = custom_opts[:browserstack_debug] if custom_opts[:browserstack_debug]
    caps[:'device'] = custom_opts[:browserstack_device] if custom_opts[:browserstack_device]
    caps[:'deviceOrientation'] = custom_opts[:browserstack_device_orientation] if custom_opts[:browserstack_device_orientation]
    caps[:'project'] = custom_opts[:browserstack_project] if custom_opts[:browserstack_project]
    caps[:'resolution'] = custom_opts[:browserstack_resolution] if custom_opts[:browserstack_resolution]
  end

  def add_appium_caps(caps, custom_opts)
    caps[:platformName] = custom_opts[:appium_platform] if custom_opts[:appium_platform]
    caps[:deviceName] = custom_opts[:appium_device] if custom_opts[:appium_device]
    caps[:browserName] = custom_opts[:appium_browser] if custom_opts[:appium_browser]
    caps[:udid] = custom_opts[:appium_udid] if custom_opts[:appium_udid]
  end

  def set_client_proxy(opts)
    Selenium::WebDriver::Proxy.new(:http => opts[:http_proxy]) if opts[:http_proxy] && opts[:webdriver_proxy_on] != 'false' #set proxy on client connection if required, note you may use ENV['HTTP_PROXY'] for setting in browser (ff profile) but not for client conection, hence allow for PROXY_ON=false
  end

  def create_profile(profile_name = nil, additional_prefs = nil)
    additional_prefs = JSON.parse(additional_prefs) if additional_prefs
    if(additional_prefs && !profile_name)
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.native_events = true
    elsif(profile_name == 'BBC_INTERNAL')
      profile = Selenium::WebDriver::Firefox::Profile.new
      if(@proxy_host && @proxy_port)
        profile["network.proxy.type"] = 1
        profile["network.proxy.no_proxies_on"] = "*.sandbox.dev.bbc.co.uk,*.sandbox.bbc.co.uk"
        profile["network.proxy.http"] = @proxy_host
        profile["network.proxy.ssl"] = @proxy_host
        profile["network.proxy.http_port"] = @proxy_port
        profile["network.proxy.ssl_port"] = @proxy_port
      end
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

  def register_mechanize_driver(opts)
    # Mechanize needs a Rack application: create a dummy one
    app = Proc.new do |env|
      ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
    end
    Capybara.app = app
    Capybara.run_server = false
    Capybara.register_driver :mechanize do |app|
      Capybara.app_host = "http://www.bbc.co.uk"
      Capybara::Mechanize::Driver.new(app)
    end
    :mechanize
  end


  def register_poltergeist_driver(opts)
    ## Poltergiest needs a Rack application: create a dummy one
    app = Proc.new do |env|
      ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
    end
    phantom_opts = %w(--ssl-protocol=tlsv1 --ignore-ssl-errors=yes)
    phantom_opts.push "--proxy=#{@proxy_host}:#{@proxy_port}" if @proxy_host && @proxy_port
    Capybara.app = app
    Capybara.run_server = false
    options = {
      js_errors: false,
      timeout:   120,
      window_size: [1200, 1000],
      phantomjs_options: phantom_opts,
      default_wait_time: 30
    }
    Capybara.register_driver :poltergeist do |app|
      Capybara.app_host = "http://www.bbc.co.uk"
      Capybara::Poltergeist::Driver.new(app, options)
    end
    :poltergeist
  end

  def clean_opts(opts, *args)
    args.each do |arg|
      opts.delete arg
    end
  end

end
