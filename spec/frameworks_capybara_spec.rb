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

shared_examples_for "driver" do
  it "should exist" do
  end
end

describe CapybaraSetup do

  before do
    ENV.clear
    Capybara.delete_session
    ENV['HOME'] = '/home/matt' #TODO: home is used by sel-webdriver to locate app specific settings e.g. Firefox profile location, see Selenium::Webdriver::Common::Platform - not sure how this gets set when running via normal route as clearly we don't normally have to set this.
  end

  describe "should validate options" do
    it "should require as a minimum ENVIRONMENT and BROWSER" do
      lambda {CapybaraSetup.new}.should raise_error(RuntimeError,'Please ensure following environment variables are set ENVIRONMENT [int|test|stage|live], BROWSER[headless|ie|chrome|firefox] and PROXY_URL')
    end

    it "should not error if ENVIRONMENT and BROWSER are provided" do
      ENV['BROWSER'] = 'headless'
      ENV['ENVIRONMENT'] = 'test'
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
