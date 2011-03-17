require 'selenium-webdriver'

class CapybaraSetup

  attr_accessor :driver

  def initialize
    #validate environment variables set using cucumber.yml or passed via command line
    validate_env_vars

    #Disable rack server
    Capybara.run_server = false

    capybara_opts = {:proxy => ENV['PROXY_URL'], :platform => ENV['PLATFORM'], :browser_name => ENV['REMOTE_BROWSER'], :version => ENV['BROWSER_VERSION'], :url => ENV['REMOTE_URL'], :profile => ENV['FIREFOX_PROFILE'], :browser => ENV['BROWSER'].intern, :javascript_enabled => ENV['CELERITY_JS_ENABLED']}

    #remove nil options
    capybara_opts.delete_if {|k,v| v.nil?}

    case ENV['BROWSER']
    when 'headless' then
      @driver = register_celerity_driver(capybara_opts)
    else
      @driver = register_selenium_driver(capybara_opts)
    end
  end

  private

  def validate_env_vars
    #v basic check for correct env variables
    env_vars = [ENV['ENVIRONMENT'],ENV['BROWSER']]

      
    env_vars.each { |var|
      if(var==nil)
        abort 'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and PROXY_URL'
      end
    }

    #if running  remote test check for correct env variables
    if(ENV['BROWSER']=='remote')
      env_vars_remote = [ENV['PLATFORM'],ENV['REMOTE_URL'], ENV['REMOTE_BROWSER']]
      env_vars_remote.each{ |var|
        if(var==nil)
          abort 'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), PROXY_URL (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)'
        end
      }
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
        if(ENV['REMOTE_BROWSER_PROXY'])
          opts[:proxy] = Selenium::WebDriver::Proxy.new(:http => ENV['REMOTE_BROWSER_PROXY'])
        end
        
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

