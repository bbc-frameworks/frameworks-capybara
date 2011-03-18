require 'selenium-webdriver'

class CapybaraSetup

  ERROR_MSG1 = 'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and PROXY_URL'
  ERROR_MSG2 = 'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), PROXY_URL (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)'


  attr_accessor :driver

  def initialize

    capybara_opts = {:environment => ENV['ENVIRONMENT'], :proxy => ENV['PROXY_URL'], :remote_browser_proxy_url => ENV['REMOTE_BROWSER_PROXY_URL'], :platform => ENV['PLATFORM'], :browser_name => ENV['REMOTE_BROWSER'], :version => ENV['REMOTE_BROWSER_VERSION'], :url => ENV['REMOTE_URL'], :profile => ENV['FIREFOX_PROFILE'], :browser => ENV['BROWSER'], :javascript_enabled => ENV['CELERITY_JS_ENABLED']}

    #validate environment variables set using cucumber.yml or passed via command line
    validate_env_vars(capybara_opts)

    #update :browser value to be a symbol, required for Selenium
    capybara_opts[:browser] = capybara_opts[:browser].intern
capybara_opts[:browser_name] = capybara_opts[:browser_name].intern
    #Disable rack server
    Capybara.run_server = false

    #remove nil options
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

    #delete environment, only add to opts for conveniance when validating 
    opts.delete(:environment)

    if(opts[:browser]=='remote')
      [:platform, :remote_url, :browser_name].each do |item|
        opts.has_key?(item) && opts[item]==nil ? abort(ERROR_MSG2) : '' 
      end
    end
  end

  def register_selenium_driver(opts)
    Capybara.register_driver :selenium do |app|

      if(opts[:browser] == :remote)
        #create remote driver client instance
        client = Selenium::WebDriver::Remote::Http::Default.new

        #set proxy on client connection if required
        if(opts[:proxy])
          client.proxy = Selenium::WebDriver::Proxy.new(:http => opts[:proxy])
          opts.delete :proxy
        end

        #set proxy for remote browser (only supported for ff at present)
        if(opts[:remote_browser_proxy_url])
          opts[:proxy] = Selenium::WebDriver::Proxy.new(:http => opts[:remote_browser_proxy_url])
          opts.delete :remote_browser_proxy_url
        end
p opts
        #note, we should probably not be passing all the options to the capabilities, fragile
        caps = Selenium::WebDriver::Remote::Capabilities.new(opts)
        #remove options that would have been added to caps
        opts.delete_if {|k,v| [:browser_name, :platform, :profile, :version].include? k}
        opts[:desired_capabilities] = caps
        opts[:http_client] = client
      end
      Capybara::Driver::Selenium.new(app,opts)
    end   
    :selenium
  end

  def register_celerity_driver (opts)
    Capybara.register_driver :celerity do |app|
      #delete browser from options as value with  be 'headless'
      opts.delete :browser
      #remove http:// from proxy URL for Celerity
      if(opts[:proxy])
        opts[:proxy] = opts[:proxy].gsub(/http:\/\//,'')
      end
      Capybara::Driver::Celerity.new(app,opts)
    end
    :celerity
  end
end
