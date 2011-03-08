require 'selenium-webdriver'

class CapybaraSetup

  attr_accessor :driver

  def initialize
    #validate environment variables set using cucumber.yml or passed via command line
    validate_env_vars

    #Disable rack server
    Capybara.run_server = false

    case ENV['BROWSER']
    when 'headless' then
      @driver = register_celerity_driver(false,ENV['PROXY_URL'])
    when 'remote' then
      @driver = register_remote_driver(ENV['PROXY_URL'], ENV['PLATFORM'],ENV['BROWSER_VM'],ENV['REMOTE_URL'], ENV['FIREFOX_PROFILE'])
    else
      @driver = register_selenium_driver
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
      env_vars_remote = [ENV['PLATFORM'],ENV['REMOTE_URL'], ENV['BROWSER_VM']]
      env_vars_remote.each{ |var|
        if(var==nil)
          abort 'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, BROWSER_VM (browser to use on remote machine) and PROXY_URL (if required)'
        end
      }
    end
  end

  def register_remote_driver(proxy, platform, browser, remote_url, profile)
    Capybara.register_driver :remote do |app|
      #create remote driver client instance
      client = Selenium::WebDriver::Remote::Http::Default.new

      #set proxy on client connection if required
      if(proxy)
        client.proxy = Selenium::WebDriver::Proxy.new(:http => proxy)
      end

      caps = Selenium::WebDriver::Remote::Capabilities.new({:platform => platform, :browser_name => browser, :proxy => Selenium::WebDriver::Proxy.new(:http => proxy)})

      Capybara::Driver::Selenium.new(app,
                                     :browser => :remote,
                                     :http_client => client,
                                     :url => remote_url,
                                     :desired_capabilities => caps)
    end   
    :remote

  end

  def register_celerity_driver (js_enabled, proxy)
    Capybara.register_driver :celerity do |app|
      Capybara::Driver::Celerity.new(app, {:javascript_enabled=>js_enabled,:proxy=>proxy})
    end
    :celerity
  end

  def register_selenium_driver
    Capybara.register_driver :selenium do |app|
      #need to convert string to label to set browser for Selenium - hence .intern
      Capybara::Driver::Selenium.new(app,:browser => ENV['BROWSER'].intern)
    end
    :selenium
  end
end

