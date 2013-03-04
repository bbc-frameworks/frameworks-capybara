require 'spec_helper'

describe Frameworks::EnvHelper do

  before do
    ENV.clear
    ENV['BROWSER'] = 'test' #mandatory data to prevent validation exception
  end

  describe "set base url correctly" do
    include Frameworks::EnvHelper

    it "should be able to set a local url" do
      ENV['ENVIRONMENT'] = 'sandbox'
      generate_base_urls
      @base_url.should == 'http://pal.sandbox.dev.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.sandbox.dev.bbc.co.uk'
      @static_base_url.should == 'http://static.sandbox.dev.bbc.co.uk'
      @m_base_url.should == 'http://m.sandbox.dev.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.sandbox.dev.bbc.co.uk'
    end

    it "should be able to set a local system6 url" do
      ENV['ENVIRONMENT'] = 'sandbox6'
      generate_base_urls
      @base_url.should == 'http://sandbox.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.sandbox.bbc.co.uk'
      @static_base_url.should == 'http://static.sandbox.bbc.co.uk'
      @m_base_url.should == 'http://m.sandbox.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.sandbox.bbc.co.uk'
    end

    it "should be able to set a base url" do
      ENV['ENVIRONMENT'] = 'foo'
      generate_base_urls
      @base_url.should == 'http://www.foo.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.foo.bbc.co.uk'
      @static_base_url.should == 'http://static.foo.bbci.co.uk'
      @open_base_url.should == 'http://open.foo.bbc.co.uk'
      @m_base_url.should == 'http://m.foo.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.foo.bbc.co.uk'
    end

    it "should set correct static base for www.live.bbc.co.uk" do
      ENV['ENVIRONMENT'] = 'live'
      generate_base_urls
      @base_url.should == 'http://www.live.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.live.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.live.bbc.co.uk'
      @m_base_url.should == 'http://m.live.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.live.bbc.co.uk'
    end

    it "should be able to set a base url and not be case sensitive" do
      ENV['ENVIRONMENT'] = 'fOo'
      generate_base_urls
      @base_url.should == 'http://www.foo.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.foo.bbc.co.uk'
      @static_base_url.should == 'http://static.foo.bbci.co.uk'
      @open_base_url.should == 'http://open.foo.bbc.co.uk'
      @m_base_url.should == 'http://m.foo.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.foo.bbc.co.uk'
    end

    it "should set correct static base for www.live.bbc.co.uk and not be case sensitive" do
      ENV['ENVIRONMENT'] = 'LiVe'
      generate_base_urls
      @base_url.should == 'http://www.live.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.live.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.live.bbc.co.uk'
      @m_base_url.should == 'http://m.live.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.live.bbc.co.uk'
    end


    it "should be able to set a 'classic' live url and not be case sensitive" do
      ENV['ENVIRONMENT'] = 'Live'
      ENV['WWW_LIVE'] = 'false' 
      generate_base_urls
      @base_url.should == 'http://www.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.bbc.co.uk'
      @m_base_url.should == 'http://m.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.bbc.co.uk'
    end

    it "should be able to set pal url and not be case sensitive" do
      ENV['ENVIRONMENT'] = 'Live'
      generate_base_urls
      @base_url.should == 'http://www.live.bbc.co.uk'
      @pal_base_url.should == 'http://pal.live.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.live.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.live.bbc.co.uk'
      @m_base_url.should == 'http://m.live.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.live.bbc.co.uk'
    end

    it "pal url should still have environment even if asking for classic live url" do
      ENV['ENVIRONMENT'] = 'Live'
      ENV['WWW_LIVE'] = 'false' 
      generate_base_urls
      @base_url.should == 'http://www.bbc.co.uk'
      @pal_base_url.should == 'http://pal.live.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.bbc.co.uk'
      @static_base_url.should == 'http://static.bbci.co.uk'
      @open_base_url.should == 'http://open.bbc.co.uk'
      @m_base_url.should == 'http://m.bbc.co.uk'
      @mobile_base_url.should == 'http://mobile.bbc.co.uk'
    end



    it "should be able to set scheme to ssl" do
      ENV['SCHEME'] = 'https'
      ENV['ENVIRONMENT'] = 'foo'
      generate_base_urls
      @base_url.should == 'https://www.foo.bbc.co.uk'
      @ssl_base_url.should == 'https://ssl.foo.bbc.co.uk'
      @static_base_url.should == 'https://static.foo.bbci.co.uk'
      @open_base_url.should == 'https://open.foo.bbc.co.uk'
    end

    it "should be able to set proxy host and port correctly to use in tests using HTTP_PROXY env variable" do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['HTTP_PROXY'] = 'http://mycache.co.uk:8080'
      generate_base_urls
      @proxy_host.should == "mycache.co.uk"
      @proxy_port.should == "8080"
    end

    it "should be able to set proxy host correctly to use in tests using http_proxy env variable" do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = 'http://mycache.co.uk:8080'
      generate_base_urls
      @proxy_host.should == "mycache.co.uk"
      @proxy_port.should == "8080"
    end

    it "should be able to use 80 as default proxy port when none specified" do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = 'http://mycache.co.uk'
      generate_base_urls
      @proxy_host.should == "mycache.co.uk"
      @proxy_port.should == "80"
    end

    it "should be able to handle an environment variable which doesn't have the protocol" do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = 'mycache.co.uk'
      generate_base_urls
      @proxy_host.should == "mycache.co.uk"
      @proxy_port.should == "80"
    end

    it "should be able to have an empty http_proxy environment variable" do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = ''
      generate_base_urls
      @proxy_host.should be_nil
      @proxy_port.should be_nil
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

    describe "independent mechanize agent" do
    include Frameworks::EnvHelper

    it "should allow you to create an independent, configured mechanize object" do
      ENV['HTTP_PROXY'] = 'http://mycache.co.uk:80'
      agent = new_mechanize
      agent.should be_a_kind_of Mechanize
      agent.proxy_addr.should == 'mycache.co.uk'
    end

    it "the proxy should be separately configurable" do
      agent = new_mechanize(http_proxy='http://mycache.co.uk:80')
      agent.should be_a_kind_of Mechanize
      agent.proxy_addr.should == 'mycache.co.uk'
    end

  end
end
