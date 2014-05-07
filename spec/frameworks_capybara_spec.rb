require 'spec_helper'
require 'securerandom'
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
      lambda {CapybaraSetup.new}.should raise_error(RuntimeError,'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and HTTP_PROXY (if required)')
    end

    it "should require as a minimum ENVIRONMENT, BROWSER and REMOTE_BROWSER if running a Remote Selenium Instance" do
      ENV['BROWSER'] = 'remote'
      ENV['ENVIRONMENT'] = 'test'
      lambda {CapybaraSetup.new}.should raise_error(RuntimeError,'Please ensure the following environment variables are set PLATFORM, REMOTE_URL, REMOTE_BROWSER (browser to use on remote machine), HTTP_PROXY (if required), REMOTE_BROWSER_PROXY (if required) and BROWSER_VERSION (if required)')
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
          ENV['HTTP_PROXY'] = 'http://example.cache.co.uk:80/'
          ENV['PROXY_ON'] = 'false'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :firefox
          Capybara.current_session.driver.options[:profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.type'].should == 1
          Capybara.current_session.driver.options[:profile].instance_variable_get(:@additional_prefs)['network.proxy.no_proxies_on'].should == '*.sandbox.dev.bbc.co.uk,*.sandbox.bbc.co.uk'
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
          ENV['HTTP_PROXY'] = 'http://example.cache.co.uk:80'
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
          ENV['HTTP_PROXY'] = 'http://example.cache.co.uk:80'
          ENV['PROXY_ON'] = 'false'
        end

        it "should be initialized correctly" do 
          Capybara.delete_session
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.should be_a_kind_of Capybara::Selenium::Driver
          Capybara.current_session.driver.options[:browser].should == :remote
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].should be_a_kind_of Selenium::WebDriver::Firefox::Profile
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.type'].should == 1
          Capybara.current_session.driver.options[:desired_capabilities].instance_variable_get(:@capabilities)[:firefox_profile].instance_variable_get(:@additional_prefs)['network.proxy.no_proxies_on'].should == '*.sandbox.dev.bbc.co.uk,*.sandbox.bbc.co.uk'
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

      context "with Selenium driver and hardcoded bbc internal profile and additional firefox preferences" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['HTTP_PROXY'] = 'http://example.cache.co.uk:80'
          ENV['FIREFOX_PROFILE'] = 'BBC_INTERNAL'
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
            ENV['HTTP_PROXY'] = 'http://example.cache.co.uk:80'
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
            ENV['HTTP_PROXY'] = 'http://example.cache.co.uk:80'
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

        context "with maximal Celerity driver" do
          before do
            ENV['BROWSER'] = 'headless'
            ENV['CELERITY_JS_ENABLED'] = 'true'
            ENV['http_proxy'] = 'http://example.cache.co.uk:80'
          end

          it "should cope with http_proxy and HTTP_PROXY " do
            Capybara.delete_session
            Capybara.current_session.driver.options[:proxy].should == 'example.cache.co.uk:80'
          end
        end

        context "integration tests for update_firefox_profile_with_certificates() method" do
          before do
            def write_random_data(file_path) 
              file_data = SecureRandom.hex
              File.open(file_path, "w") { |a_file|
                a_file.write(file_data)
              }
              file_data
            end

            def compare_file_data(profile_path, file_name, expected_data)
              profile_file = profile_path + File::SEPARATOR + file_name
              actual_data = nil
              File.open(profile_file, "r") { |a_file|
                actual_data = a_file.read
              }
              expected_data.should == actual_data 
            end

            ENV['BROWSER'] = 'firefox'
            ENV['ENVIRONMENT'] = 'test'
            ENV['HTTP_PROXY'] = 'http://example.cache.co.uk:80'
            @cert_dir = Dir.mktmpdir
            @cert8_db = @cert_dir + File::SEPARATOR + 'cert8.db'
            @key3_db = @cert_dir + File::SEPARATOR + 'key3.db'
            @secmod_db = @cert_dir + File::SEPARATOR + 'secmod.db'
          end

          after do
            FileUtils.remove_entry @cert_dir
          end

          it "should raise an exception if the cert8.db file is missing in the source directory" do
            profile = Selenium::WebDriver::Firefox::Profile.new

            key3_data = write_random_data(@key3_db)
            secmod_data = write_random_data(@secmod_db)
           
            an_exception = nil
            begin 
              CapybaraSetup.new.instance_exec(profile, @cert_dir) { |profile, certificate_path|
                update_firefox_profile_with_certificates(profile, certificate_path) 
              }
            rescue RuntimeError => e
              an_exception = e
            end

            an_exception.should_not be_nil
          end

          it "should raise an exception if the key3.db file is missing in the source directory" do
            profile = Selenium::WebDriver::Firefox::Profile.new

            cert8_data = write_random_data(@cert8_db)
            secmod_data = write_random_data(@secmod_db)
           
            an_exception = nil
            begin 
              CapybaraSetup.new.instance_exec(profile, @cert_dir) { |profile, certificate_path|
                update_firefox_profile_with_certificates(profile, certificate_path) 
              }
            rescue RuntimeError => e
              an_exception = e
            end

            an_exception.should_not be_nil
          end
          
          it "should raise an exception if the secmod.db file is missing in the source directory" do
            profile = Selenium::WebDriver::Firefox::Profile.new

            cert8_data = write_random_data(@cert8_db)
            key3_data = write_random_data(@key3_db)
  
            an_exception = nil
            begin 
              CapybaraSetup.new.instance_exec(profile, @cert_dir) { |profile, certificate_path|
                update_firefox_profile_with_certificates(profile, certificate_path) 
              }
            rescue RuntimeError => e
              an_exception = e
            end

            an_exception.should_not be_nil
          end

          it "should update a firefox profile with valid references to certificate db files" do
       
            profile = Selenium::WebDriver::Firefox::Profile.new

            cert8_data = write_random_data(@cert8_db)
            key3_data = write_random_data(@key3_db)
            secmod_data = write_random_data(@secmod_db)

            setup = CapybaraSetup.new
            result = setup.instance_exec(profile, @cert_dir) { |profile, certificate_path|
              update_firefox_profile_with_certificates(profile, certificate_path) 
            }
            profile_path = result.layout_on_disk
            compare_file_data(profile_path, 'cert8.db', cert8_data)
            compare_file_data(profile_path, 'key3.db', key3_data)
            compare_file_data(profile_path, 'secmod.db', secmod_data)
          end

          it "should update a firefox profile with references to certificate db files with prefixes" do
       
            profile = Selenium::WebDriver::Firefox::Profile.new
            cert_prefix = 'a'
            @cert8_db = @cert_dir + File::SEPARATOR + cert_prefix + 'cert8.db'
            @key3_db = @cert_dir + File::SEPARATOR + cert_prefix + 'key3.db'
            @secmod_db = @cert_dir + File::SEPARATOR + cert_prefix + 'secmod.db'
 
            cert8_data = write_random_data(@cert8_db)
            key3_data = write_random_data(@key3_db)
            secmod_data = write_random_data(@secmod_db)

            setup = CapybaraSetup.new
            result = setup.instance_exec(profile, @cert_dir, cert_prefix) { |profile, certificate_path, certificate_prefix, result|
              update_firefox_profile_with_certificates(profile, certificate_path, certificate_prefix) 
            }
            profile_path = result.layout_on_disk
            compare_file_data(profile_path, 'cert8.db', cert8_data)
            compare_file_data(profile_path, 'key3.db', key3_data)
            compare_file_data(profile_path, 'secmod.db', secmod_data)
          end

        end

      end

      describe "The BBC-INTERNAL firefox profile should be set up with the correct proxy settings whether working behind a proxy or not" do

        context "no proxy settings provided" do
          before do
            ENV['BROWSER'] = 'firefox'
            ENV['ENVIRONMENT'] = 'test'
          end

          it "should create the firefox profile settings correctly" do
            setup = CapybaraSetup.new
            profile = setup.instance_exec('BBC_INTERNAL', nil) { |profile_name, additional_prefs|
              create_profile(profile_name, additional_prefs)
            }

            profile.instance_variable_get('@additional_prefs')['network.proxy.type'].should be_nil
            profile.instance_variable_get('@additional_prefs')['network.proxy.http'].should be_nil
            profile.instance_variable_get('@additional_prefs')['network.proxy.http_port'].should be_nil
          end
        end

        context "proxy settings provided" do
          before do
            @proxy_host = 'example.cache.co.uk'
            @proxy_port = 6789
            ENV['BROWSER'] = 'firefox'
            ENV['ENVIRONMENT'] = 'test'
            ENV['HTTP_PROXY'] = "http://#{@proxy_host}:#{@proxy_port}"
          end

          it "should create the firefox profile correctly" do
            setup = CapybaraSetup.new
            profile = setup.instance_exec('BBC_INTERNAL', nil) { |profile_name, additional_prefs|
              create_profile(profile_name, additional_prefs)
            }

            profile.instance_variable_get('@additional_prefs')['network.proxy.type'].should == 1    
            profile.instance_variable_get('@additional_prefs')['network.proxy.http'].should == @proxy_host
            profile.instance_variable_get('@additional_prefs')['network.proxy.http_port'].should == @proxy_port
          end
        end
      end
    end
  end
end
