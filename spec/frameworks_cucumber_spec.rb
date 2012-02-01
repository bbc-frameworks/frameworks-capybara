require 'spec_helper'

describe Frameworks::EnvHelper do

  before do
    ENV['BROWSER'] = 'test' #mandatory data to prevent validation exception
  end

  describe "set base url correctly" do
    include Frameworks::EnvHelper

    it "should be able to set a local url" do
      ENV['ENVIRONMENT'] = 'sandbox'
      generate_base_urls
      @base_url.should == 'http://pal.sandbox.dev.bbc.co.uk'
      @static_base_url.should == 'http://static.sandbox.dev.bbc.co.uk'
    end

    it "should be able to set a base url" do
      ENV['ENVIRONMENT'] = 'foo'
      generate_base_urls
      @base_url.should == 'http://www.foo.bbc.co.uk'
      @static_base_url.should == 'http://static.foo.bbc.co.uk'
      @open_base_url.should == 'http://open.foo.bbc.co.uk'
    end

    it "should set correct static base for www.live.bbc.co.uk" do
      ENV['ENVIRONMENT'] = 'live'
      generate_base_urls
      @base_url.should == 'http://www.live.bbc.co.uk'
      @static_base_url.should == 'http://static.bbc.co.uk'
      @open_base_url.should == 'http://open.live.bbc.co.uk'
    end

    it "should be able to set a 'classic' live url" do
      ENV['ENVIRONMENT'] = 'live'
      ENV['WWW_LIVE'] = 'false' 
      generate_base_urls
      @base_url.should == 'http://www.bbc.co.uk'
      @static_base_url.should == 'http://static.bbc.co.uk'
      @open_base_url.should == 'http://open.bbc.co.uk'
    end

    it "should be able to set scheme to ssl" do
      ENV['SCHEME'] = 'https'
      ENV['ENVIRONMENT'] = 'foo'
      generate_base_urls
      @base_url.should == 'https://www.foo.bbc.co.uk'
      @static_base_url.should == 'https://static.foo.bbc.co.uk'
      @open_base_url.should == 'https://open.foo.bbc.co.uk'
    end
  end
end
