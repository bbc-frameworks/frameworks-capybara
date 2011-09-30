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

    describe "should allow Selenium driver to be created" do
      context "with minimal Selenium driver" do
        before do
          ENV['BROWSER'] = 'firefox'
          ENV['ENVIRONMENT'] = 'test'
        end

        it "should be initialized correctly" do 
          CapybaraSetup.new.driver.should == :selenium
          Capybara.current_session.driver.kind_of? Capybara::Driver::Selenium
          Capybara.current_session.driver.options[:browser].should == :firefox
        end
      end
    end

    describe "should allow Mechanize driver to be created" do
      context "with minimal Mechanize driver" do
        before do
          ENV['BROWSER'] = 'mechanize'
          ENV['ENVIRONMENT'] = 'test'
        end

        it "should be initialized correctly" do 
          CapybaraSetup.new.driver.should == :mechanize
          Capybara.current_session.driver.kind_of? Capybara::Driver::Mechanize
        end
      end

      describe "should allow Celerity driver to be created" do
        context "with minimal Celerity driver" do
          before do
            ENV['BROWSER'] = 'headless'
            ENV['ENVIRONMENT'] = 'test'
          end

          it "should be initialized correctly" do
            CapybaraSetup.new.driver.should == :celerity
            Capybara.current_session.driver.kind_of? Capybara::Driver::Celerity
            Capybara.current_session.driver.options[:javascript_enabled].should == false
          end
        end

        context "with maximal Celerity driver" do
          before do
            ENV['BROWSER'] = 'headless'
            ENV['ENVIRONMENT'] = 'test'
            ENV['CELERITY_JS_ENABLED'] = 'true'
          end

          it "should be initialized correctly" do
            CapybaraSetup.new.driver.should == :celerity
            Capybara.current_session.driver.kind_of? Capybara::Driver::Celerity
            Capybara.current_session.driver.options[:javascript_enabled].should == true
          end
        end
      end
    end
  end
end
