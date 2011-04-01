require 'monkey-patches/webdriver-patches'
require 'monkey-patches/capybara-patches'
require 'selenium-webdriver'

class CapybaraSetup

  ERROR_MSG1 = 'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and PROXY_URL'
  ERROR_MSG2 = 'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), PROXY_URL (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)'


  attr_accessor :driver

  def initialize

    capybara_opts = {:environment => ENV['ENVIRONMENT'], :proxy => ENV['PROXY_URL'], :remote_browser_proxy_url => ENV['REMOTE_BROWSER_PROXY_URL'], :platform => ENV['PLATFORM'], :browser_name => ENV['REMOTE_BROWSER'], :version => ENV['REMOTE_BROWSER_VERSION'], :url => ENV['REMOTE_URL'], :profile => ENV['FIREFOX_PROFILE'], :browser => ENV['BROWSER'], :javascript_enabled => ENV['CELERITY_JS_ENABLED'], :job_name => ENV['SAUCE_JOB_NAME']}

    validate_env_vars(capybara_opts) #validate environment variables set using cucumber.yml or passed via command line


    capybara_opts[:browser] = capybara_opts[:browser].intern #update :browser value to be a symbol, required for Selenium
    capybara_opts[:browser_name] = capybara_opts[:browser_name].intern if capybara_opts[:browser_name]

    Capybara.run_server = false #Disable rack server

    capybara_opts.delete_if {|k,v| v.nil?}

    case capybara_opts[:browser] 
    when :headless then
      @driver = register_celerity_driver(capybara_opts)
    else
      @driver = register_selenium_driver(capybara_opts)
    end
  end

  private

  def validate_env_vars(opts)
    [:environment, :browser].each do |item|
      opts.has_key?(item) && opts[item]==nil ? abort(ERROR_MSG1) : ''
    end

    opts.delete(:environment) #delete environment, only add to opts for conveniance when validating 


    if opts[:browser]=='remote'
      [:platform, :remote_url, :browser_name].each do |item|
        opts.has_key?(item) && opts[item]==nil ? abort(ERROR_MSG2) : '' 
      end
    end
  end

  def register_selenium_driver(opts)
    Capybara.register_driver :selenium do |app|

      if opts[:browser] == :remote
        client = Selenium::WebDriver::Remote::Http::Default.new

        #set proxy on client connection if required
        if opts[:proxy]
          client.proxy = Selenium::WebDriver::Proxy.new(:http => opts[:proxy])
          opts.delete :proxy
        end

        #set proxy for remote browser (only supported for ff at present)
        if opts[:remote_browser_proxy_url]
          opts[:proxy] = Selenium::WebDriver::Proxy.new(:http => opts[:remote_browser_proxy_url])
          opts.delete :remote_browser_proxy_url
        end

        #TODO: temp workaround - needs refactoring
        cap_opts = opts.clone
        cap_opts.delete :profile
        cap_opts.delete :browser

        caps = Selenium::WebDriver::Remote::Capabilities.new(cap_opts)

        if opts[:job_name] then caps.custom_capabilities({:'job-name' => opts.delete(:job_name)}) end #set custom job name for sauce-labs 

        opts.delete_if {|k,v| [:browser_name, :platform, :profile, :version].include? k}  #remove options that would have been added to caps

        opts[:desired_capabilities] = caps
        opts[:http_client] = client
      else
        opts.delete_if {|k,v| [:proxy].include? k} #may want to pass env variables that are not relevant for in browser 'non-remote' tests e.g. proxy, so delete these before setting up driver
      end
      Capybara::Driver::Selenium.new(app,opts)
    end   
    :selenium
  end

  def register_celerity_driver (opts)
    Capybara.register_driver :celerity do |app|
      opts.delete :browser #delete browser from options as value with  be 'headless'
      opts[:javascript_enabled] == 'true' ? opts[:javascript_enabled] = true : opts[:javascript_enabled] = false
      if opts[:proxy]
        opts[:proxy] = opts[:proxy].gsub(/http:\/\//,'')
      end
      Capybara::Driver::Celerity.new(app,opts)
    end
    :celerity
  end
end
