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

describe CapybaraSetup do

  before do
    home = ENV['HOME']
    ENV.clear
    ENV['HOME'] = home #Want to clear some env variables but HOME is used by Webdriver, therefore need to preserve it
    Capybara.delete_session
  end

  describe "should validate options" do
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
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
          Capybara.current_session.driver.options[:browser].should == :firefox
        end
      end

      context "with Selenium driver and default firefox profile (from profiles.ini)" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'default'
        end

        it "should be initialized correctly" do 
          Selenium::WebDriver::Firefox::ProfilesIni.new
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
          Capybara.current_session.driver.options[:browser].should == :firefox
          Capybara.current_session.driver.options[:profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@model).should include "default"
        end
      end

      context "with Selenium driver and programtically cretated profile" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'BBC_INTERNAL'
          ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
        end

        it "should be initialized correctly" do 
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
          Capybara.current_session.driver.options[:browser].should == :firefox
          Capybara.current_session.driver.options[:profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.type'].should == '1'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.no_proxies_on'].should == '"*.sandbox.dev.bbc.co.uk"'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.http'].should == '"example.cache.co.uk"'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.http_port'].should == '80'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl'].should == '"example.cache.co.uk"'
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl_port'].should == '80'
        end
      end


      context "with Remote Selenium driver" do
        before do
          ENV['BROWSER'] = 'remote'
          ENV['REMOTE_BROWSER'] = 'firefox'
          ENV['FIREFOX_PROFILE'] = 'default'
          ENV['REMOTE_URL'] = 'http://example.com'
        end

        it "should be initialized correctly" do 
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:url].should == 'http://example.com'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should == nil
          Capybara.current_session.driver.options[:desired_capabilities].should be_a_kind_of Selenium::WebDriver::Remote::Capabilities 
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:browser_name].should == :firefox
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@model).should include 'default'
        end
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
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:url].should == 'http://example.com'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should be_a_kind_of Selenium::WebDriver::Proxy
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).instance_variable_get(:@http).should == 'http://example.cache.co.uk:80'
        end
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
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.type'].should == '1'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.no_proxies_on'].should == '"*.sandbox.dev.bbc.co.uk"'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.http'].should == '"example.cache.co.uk"'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.http_port'].should == '80'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl'].should == '"example.cache.co.uk"'
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.ssl_port'].should == '80'
          Capybara.current_session.driver.options[:http_client].should be_a_kind_of Selenium::WebDriver::Remote::Http::Default 
          Capybara.current_session.driver.options[:http_client].instance_variable_get(:@proxy).should == nil
        end
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
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
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
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Selenium
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
      end
    end

    describe "should allow Mechanize driver to be created" do
      context "with minimal Mechanize driver" do
        before do
          ENV['BROWSER'] = 'mechanize'
        end

        it "should be initialized correctly" do 
          CapybaraSetup.new.driver.should == :mechanize
          Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Mechanize
        end
        context "with maximal Mechanize driver" do
          before do
            ENV['BROWSER'] = 'mechanize'
            ENV['ENVIRONMENT'] = 'test'
            ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
          end

          it "should be initialized correctly" do
            CapybaraSetup.new.driver.should == :mechanize
            Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Mechanize
            Capybara.current_session.driver.agent.proxy_addr.should == 'example.cache.co.uk'
            Capybara.current_session.driver.agent.proxy_port.should == 80
          end
        end
      end

      describe "should allow Celerity driver to be created" do
        context "with minimal Celerity driver" do
          before do
            ENV['BROWSER'] = 'headless'
          end

          it "should be initialized correctly" do
            CapybaraSetup.new.driver.should == :celerity
            Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Celerity
            Capybara.current_session.driver.options[:javascript_enabled].should == false
          end
        end

        context "with maximal Celerity driver" do
          before do
            ENV['BROWSER'] = 'headless'
            ENV['CELERITY_JS_ENABLED'] = 'true'
            ENV['PROXY_URL'] = 'http://example.cache.co.uk:80'
          end

          it "should be initialized correctly" do
            CapybaraSetup.new.driver.should == :celerity
            Capybara.current_session.driver.should be_a_kind_of Capybara::Driver::Celerity
            Capybara.current_session.driver.options[:javascript_enabled].should == true
            Capybara.current_session.driver.options[:proxy].should == 'example.cache.co.uk:80'
          end
        end
      end
    end
  end
end
