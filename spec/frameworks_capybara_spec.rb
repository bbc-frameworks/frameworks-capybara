require 'spec_helper'
##
#Monkey Patch
#This is required because Capybara has module methods (singletons) which create
#a session and then re-use this whenever Capybara is referenced in the current process. 
#Therefore even creating new instances of CapybaraSetup will use the same session and driver instance
#...not picking up changes in the different tests below.  
#Hence the only option is to clean out the session before each test.
module Capybara
  class << self
    def delete_session
      @session_pool = {}
    end
  end
end

shared_examples_for "Selenium Driver Options Array" do
  it "should contain no nil values for unset options" do
    #TODO: Test for nil elements in options - there shouldn't be any that we insert
    #i.e. anything in our ENV options should not end up being nil in Selenium
    Capybara.current_session.driver.options[:environment].should == nil
    Capybara.current_session.driver.options[:proxy].should == nil
    Capybara.current_session.driver.options[:proxy_on].should == nil
    Capybara.current_session.driver.options[:platform].should == nil
    Capybara.current_session.driver.options[:browser_name].should == nil
    Capybara.current_session.driver.options[:version].should == nil
    Capybara.current_session.driver.options[:job_name].should == nil
    Capybara.current_session.driver.options[:chrome_switches].should == nil
    Capybara.current_session.driver.options[:firefox_prefs].should == nil
    Capybara.current_session.driver.options[:max_duration].should == nil
    Capybara.current_session.driver.options[:profile].should_not be_a_kind_of String
    Capybara.current_session.driver.options[:browser].should_not be_a_kind_of String
  end
end

describe CapybaraSetup do

  before(:each) do
    home = ENV['HOME']
    appdata = ENV['APPDATA']
    ENV.clear
    ENV['HOME'] = home #Want to clear some env variables but HOME is used by Webdriver, therefore need to preserve it
    ENV['APPDATA'] = appdata
  end

  describe "should validate options" do
    before(:each) do
      Capybara.delete_session
    end

    it "should require as a minimum ENVIRONMENT and BROWSER" do
      lambda {CapybaraSetup.new}.should raise_error(RuntimeError,'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and PROXY_URL (if required)')
    end

    it "should require as a minimum ENVIRONMENT, BROWSER and REMOTE_BROWSER if running a Remote Selenium Instance" do
      ENV['BROWSER'] = 'remote'
      ENV['ENVIRONMENT'] = 'test'
      lambda {CapybaraSetup.new}.should raise_error(RuntimeError,'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), PROXY_URL (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)')
    end

    it "should not error if ENVIRONMENT and BROWSER are provided" do
      ENV['BROWSER'] = 'headless'
      ENV['ENVIRONMENT'] = 'test'
      lambda {CapybaraSetup.new}.should_not raise_error
    end

    it "should not error if ENVIRONMENT, BROWSER and REMOTE_BROSWER are provided if running a Remote Selenium Instance" do
      ENV['BROWSER'] = 'remote'
      ENV['ENVIRONMENT'] = 'test'
      ENV['REMOTE_BROWSER'] = 'test'
      ENV['REMOTE_URL'] = 'test'
      lambda {CapybaraSetup.new}.should_not raise_error
    end
  end

  describe "should allow Capybara drivers to be created" do
    before do
      ENV['ENVIRONMENT'] = 'test'
    end

    describe "should allow Selenium driver to be created" do
      context "with minimal Selenium driver" do
        before do
          ENV['BROWSER'] = 'firefox'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :firefox
        end

        it_behaves_like "Selenium Driver Options Array"
      end

      context "with Selenium driver and default firefox profile (from profiles.ini)" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'default'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :firefox
          Capybara.current_session.driver.options[:profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@model).should include "default"
        end
        it_behaves_like "Selenium Driver Options Array"

      end

      context "with Selenium driver and programtically created profile" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'BBC_INTERNAL'
          ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
          ENV['PROXY_ON'] = 'false'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :firefox
          Capybara.current_session.driver.options[:profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.type'].should == 1
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.no_proxies_on'].should == '*.sandbox.dev.bbc.co.uk'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.http'].should == 'example.cache.co.uk'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.http_port'].should == 80
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl'].should == 'example.cache.co.uk'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl_port'].should == 80
        end
        it_behaves_like "Selenium Driver Options Array"
      end

      context "with Selenium driver and custom chrome options" do
        before do
          ENV['BROWSER'] = 'chrome'
          ENV['CHROME_SWITCHES'] = '--user-agent=Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.10'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :chrome
          Capybara.current_session.driver.options[:switches].should == ['--user-agent=Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.10']
        end
        it_behaves_like "Selenium Driver Options Array"
      end


      context "with Remote Selenium driver" do
        before do
          ENV['BROWSER'] = 'remote'
          ENV['REMOTE_BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'default'
          ENV['REMOTE_URL'] = 'http://example.com'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:url].should == 'http://example.com'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should == nil
          Capybara.current_session.driver.options[:desired_capabilities].should be_a_kind_of Selenium::WebDriver::Remote::Capabilities 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:browser_name].should == :firefox
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@model).should include 'default'
        end
        it_behaves_like "Selenium Driver Options Array"
      end

      context "with Remote Selenium driver and client proxy" do
        before do
          ENV['BROWSER'] = 'remote'
          ENV['REMOTE_BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'default'
          ENV['REMOTE_URL'] = 'http://example.com'
          ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:url].should == 'http://example.com'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should be_a_kind_of Selenium::WebDriver::Proxy
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).instance_variable_get(:@http).should == 'http://example.cache.co.uk:80'
        end
        it_behaves_like "Selenium Driver Options Array"
      end

      context "with Remote Selenium driver, programtically cretated Firefox profile using proxy but client not using proxy" do
        before do
          ENV['BROWSER'] = 'remote'
          ENV['REMOTE_BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'BBC_INTERNAL'
          ENV['REMOTE_URL'] = 'http://example.cache.co.uk:80'
          ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
          ENV['PROXY_ON'] = 'false'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.type'].should == 1
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.no_proxies_on'].should == '*.sandbox.dev.bbc.co.uk'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.http'].should == 'example.cache.co.uk'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.http_port'].should == 80
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl'].should == 'example.cache.co.uk'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl_port'].should == 80
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should == nil
        end
        it_behaves_like "Selenium Driver Options Array"
      end

      context "with Remote Selenium driver (specifying platform and browser version) and default Custom Capabilites (e.g. for Sauce Labs)" do
        before do
          ENV['BROWSER'] = 'remote'
          ENV['REMOTE_BROWSER'] = 'firefox'
          ENV['PLATFORM'] = 'windows'
          ENV['REMOTE_BROWSER_VERSION'] = '4'
          ENV['FIREFOX_PROFILE'] = 'default'
          ENV['REMOTE_URL'] = 'http://saucelabs.com'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:url].should == 'http://saucelabs.com'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should == nil
          Capybara.current_session.driver.options[:desired_capabilities].should be_a_kind_of Selenium::WebDriver::Remote::Capabilities 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@custom_capabilities)[:'job-name'].should == 'frameworks-unamed-job' 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@custom_capabilities)[:'max-duration'].should == 1800 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:browser_name].should == :firefox
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:version].should == '4' 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:platform].should == 'windows'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@model).should include 'default'
        end
        it_behaves_like "Selenium Driver Options Array"
      end

      context "with Selenium driver and additional firefox preferences" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'default'
          ENV['FIREFOX_PREFS'] = '{"javascript.enabled":false}'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :firefox
          Capybara.current_session.driver.options[:profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['javascript.enabled'].should == false
        end
        it_behaves_like "Selenium Driver Options Array"
      end
      

      context "with Selenium driver and new profile and custom prefs" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['CREATE_NEW_FF_PROFILE'] = 'true'
          ENV['FIREFOX_PREFS'] = '{"javascript.enabled":false}'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :firefox
          Capybara.current_session.driver.options[:profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['javascript.enabled'].should == false
        end
        it_behaves_like "Selenium Driver Options Array"
      end
      
      context "with Remote Selenium driver and specified Chrome Switches" do
        before do
          ENV['BROWSER'] = 'remote'
          ENV['REMOTE_BROWSER'] = 'chrome'
          ENV['REMOTE_URL'] = 'http://saucelabs.com'
          ENV['CHROME_SWITCHES'] = '--user-agent=Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.10'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:switches].should == nil
          Capybara.current_session.driver.options[:url].should == 'http://saucelabs.com'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should == nil
          Capybara.current_session.driver.options[:desired_capabilities].should be_a_kind_of Selenium::WebDriver::Remote::Capabilities 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:browser_name].should == :chrome
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)['chrome.switches'].should == ['--user-agent=Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.10'] 
        end
        it_behaves_like "Selenium Driver Options Array"
      end

      context "with Remote Selenium driver and specified Custom Capabilites (e.g. for Sauce Labs)" do
        before do
          ENV['BROWSER'] = 'remote'
          ENV['REMOTE_BROWSER'] = 'firefox'
          ENV['SAUCE_JOB_NAME'] = 'myjobname'
          ENV['SAUCE_MAX_DURATION'] = '2000'
          ENV['REMOTE_BROWSER_VERSION'] = '4'
          ENV['FIREFOX_PROFILE'] = 'default'
          ENV['REMOTE_URL'] = 'http://saucelabs.com'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:url].should == 'http://saucelabs.com'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should == nil
          Capybara.current_session.driver.options[:desired_capabilities].should be_a_kind_of Selenium::WebDriver::Remote::Capabilities 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@custom_capabilities)[:'job-name'].should == 'myjobname' 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@custom_capabilities)[:'max-duration'].should == 2000 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:browser_name].should == :firefox
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@model).should include 'default'
        end
        it_behaves_like "Selenium Driver Options Array"
      end


    end

    describe "should allow Mechanize driver to be created" do
      context "with minimal Mechanize driver" do
        before do
          ENV['BROWSER'] = 'mechanize'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :mechanize
          Capybara.current_session.driver.should be_a_kind_of Capybara::Mechanize::Driver
        end

        context "with maximal Mechanize driver" do
          before do
            ENV['BROWSER'] = 'mechanize'
            ENV['ENVIRONMENT'] = 'test'
            ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
          end

          it "should be initialized correctly" do
            Capybara.delete_session
            CapybaraSetup.new.driver.should == :mechanize
            Capybara.current_session.driver.should be_a_kind_of Capybara::Mechanize::Driver
            #note can no longer unit test this due to change in Capybara wiping brower instance
            #Capybara.current_session.driver.browser.agent.proxy_addr.should == 'example.cache.co.uk'
            #Capybara.current_session.driver.browser.agent.proxy_port.should == 80

          end
        end
      end

      describe "should allow Celerity driver to be created" do

        context "with minimal Celerity driver" do
          before do
            ENV['BROWSER'] = 'headless'
          end

          it "should be initialized correctly" do
            Capybara.delete_session
            CapybaraSetup.new.driver.should == :celerity
            Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Celerity
            Capybara.current_session.driver.options[:javascript_enabled].should == false
            Capybara.current_session.driver.options[:environment].should == nil
            Capybara.current_session.driver.options[:browser].should == nil
          end
        end

        context "with maximal Celerity driver" do
          before do
            ENV['BROWSER'] = 'headless'
            ENV['CELERITY_JS_ENABLED'] = 'true'
            ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
          end

          it "should be initialized correctly" do
            Capybara.delete_session
            CapybaraSetup.new.driver.should == :celerity
            Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Celerity
            Capybara.current_session.driver.options[:javascript_enabled].should == true
            Capybara.current_session.driver.options[:proxy].should == 'example.cache.co.uk:80'
            Capybara.current_session.driver.options[:environment].should == nil
            Capybara.current_session.driver.options[:browser].should == nil
          end
        end
      end
    end
  end
end
