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
      @static_base_url.should == 'http://static.foo.bbci.co.uk'
      @open_base_url.should == 'http://open.foo.bbc.co.uk'
    end

    it "should set correct static base for www.live.bbc.co.uk" do
      ENV['ENVIRONMENT'] = 'live'
      generate_base_urls
      @base_url.should == 'http://www.live.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.live.bbc.co.uk'
    end

    it "should be able to set a base url and not be case sensitive" do
      ENV['ENVIRONMENT'] = 'fOo'
      generate_base_urls
      @base_url.should == 'http://www.foo.bbc.co.uk'
      @static_base_url.should == 'http://static.foo.bbci.co.uk'
      @open_base_url.should == 'http://open.foo.bbc.co.uk'
    end

    it "should set correct static base for www.live.bbc.co.uk and not be case sensitive" do
      ENV['ENVIRONMENT'] = 'LiVe'
      generate_base_urls
      @base_url.should == 'http://www.live.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.live.bbc.co.uk'
    end


    it "should be able to set a 'classic' live url" do
      ENV['ENVIRONMENT'] = 'live'
      ENV['WWW_LIVE'] = 'false' 
      generate_base_urls
      @base_url.should == 'http://www.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.bbc.co.uk'
    end

    it "should be able to set scheme to ssl" do
      ENV['SCHEME'] = 'https'
      ENV['ENVIRONMENT'] = 'foo'
      generate_base_urls
      @base_url.should == 'https://www.foo.bbc.co.uk'
      @static_base_url.should == 'https://static.foo.bbci.co.uk'
      @open_base_url.should == 'https://open.foo.bbc.co.uk'
    end

    it "should be able to set proxy host correctly to use in tests using HTTP_PROXY env variable" do
      ENV['HTTP_PROXY'] = 'http://mycache.co.uk:80'
      generate_base_urls
      @proxy_host.should == "mycache.co.uk"
    end

    it "should be able to set proxy host correctly to use in tests using http_proxy env variable" do
      ENV['http_proxy'] = 'http://mycache.co.uk:80'
      generate_base_urls
      @proxy_host.should == "mycache.co.uk"
    end

=begin
#don't want to push proxy addr online
    it "should be able to validate xhtml online" do
      @proxy_host = ''
      xhtml = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"><head><title>a</title></head><body><p>a</p></body></html>'
      validate_online(xhtml)
    end
=end
  end
end
