require 'spec_helper'

describe Frameworks::EnvHelper do
  before do
    ENV.clear
    ENV['BROWSER'] = 'test' # mandatory data to prevent validation exception
  end

  describe 'set base url correctly' do
    include Frameworks::EnvHelper

    it 'should be able to set a local url' do
      ENV['ENVIRONMENT'] = 'sandbox'
      generate_base_urls
      @base_url.should eq('http://pal.sandbox.dev.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.sandbox.dev.bbc.co.uk')
      @static_base_url.should eq('http://static.sandbox.dev.bbc.co.uk')
      @m_base_url.should eq('http://m.sandbox.dev.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.sandbox.dev.bbc.co.uk')
    end

    it 'should be able to set a local system6 url' do
      ENV['ENVIRONMENT'] = 'sandbox6'
      generate_base_urls
      @base_url.should eq('http://sandbox.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.sandbox.bbc.co.uk')
      @static_base_url.should eq('http://static.sandbox.bbc.co.uk')
      @m_base_url.should eq('http://m.sandbox.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.sandbox.bbc.co.uk')
    end

    it 'should be able to set a base url' do
      ENV['ENVIRONMENT'] = 'foo'
      generate_base_urls
      @base_url.should eq('http://www.foo.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.foo.bbc.co.uk')
      @static_base_url.should eq('http://static.foo.bbci.co.uk')
      @open_base_url.should eq('http://open.foo.bbc.co.uk')
      @m_base_url.should eq('http://m.foo.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.foo.bbc.co.uk')
    end

    it 'should set correct static base for www.live.bbc.co.uk' do
      ENV['ENVIRONMENT'] = 'live'
      generate_base_urls
      @base_url.should eq('http://www.live.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.live.bbc.co.uk')
      @static_base_url.should eq('http://static.bbci.co.uk')
      @open_base_url.should eq('http://open.live.bbc.co.uk')
      @m_base_url.should eq('http://m.live.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.live.bbc.co.uk')
    end

    it 'should be able to set a base url and not be case sensitive' do
      ENV['ENVIRONMENT'] = 'fOo'
      generate_base_urls
      @base_url.should eq('http://www.foo.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.foo.bbc.co.uk')
      @static_base_url.should eq('http://static.foo.bbci.co.uk')
      @open_base_url.should eq('http://open.foo.bbc.co.uk')
      @m_base_url.should eq('http://m.foo.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.foo.bbc.co.uk')
    end

    it 'should set correct static base for www.live.bbc.co.uk and not be case sensitive' do
      ENV['ENVIRONMENT'] = 'LiVe'
      generate_base_urls
      @base_url.should eq('http://www.live.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.live.bbc.co.uk')
      @static_base_url.should eq('http://static.bbci.co.uk')
      @open_base_url.should eq('http://open.live.bbc.co.uk')
      @m_base_url.should eq('http://m.live.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.live.bbc.co.uk')
    end

    it "should be able to set a 'classic' live url and not be case sensitive" do
      ENV['ENVIRONMENT'] = 'Live'
      ENV['WWW_LIVE'] = 'false'
      generate_base_urls
      @base_url.should eq('http://www.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.bbc.co.uk')
      @static_base_url.should eq('http://static.bbci.co.uk')
      @open_base_url.should eq('http://open.bbc.co.uk')
      @m_base_url.should eq('http://m.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.bbc.co.uk')
    end

    it 'should be able to set pal url and not be case sensitive' do
      ENV['ENVIRONMENT'] = 'Live'
      generate_base_urls
      @base_url.should eq('http://www.live.bbc.co.uk')
      @pal_base_url.should eq('http://pal.live.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.live.bbc.co.uk')
      @static_base_url.should eq('http://static.bbci.co.uk')
      @open_base_url.should eq('http://open.live.bbc.co.uk')
      @m_base_url.should eq('http://m.live.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.live.bbc.co.uk')
    end

    it 'pal url should still have environment even if asking for classic live url' do
      ENV['ENVIRONMENT'] = 'Live'
      ENV['WWW_LIVE'] = 'false'
      generate_base_urls
      @base_url.should eq('http://www.bbc.co.uk')
      @pal_base_url.should eq('http://pal.live.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.bbc.co.uk')
      @static_base_url.should eq('http://static.bbci.co.uk')
      @open_base_url.should eq('http://open.bbc.co.uk')
      @m_base_url.should eq('http://m.bbc.co.uk')
      @mobile_base_url.should eq('http://mobile.bbc.co.uk')
    end

    it 'should be able to set scheme to ssl' do
      ENV['SCHEME'] = 'https'
      ENV['ENVIRONMENT'] = 'foo'
      generate_base_urls
      @base_url.should eq('https://www.foo.bbc.co.uk')
      @ssl_base_url.should eq('https://ssl.foo.bbc.co.uk')
      @static_base_url.should eq('https://static.foo.bbci.co.uk')
      @open_base_url.should eq('https://open.foo.bbc.co.uk')
    end

    it 'should be able to set proxy host and port correctly to use in tests using HTTP_PROXY env variable' do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['HTTP_PROXY'] = 'http://mycache.co.uk:8080'
      generate_base_urls
      @proxy_host.should eq('mycache.co.uk')
      @proxy_port.should eq('8080')
    end

    it 'should be able to set proxy host correctly to use in tests using http_proxy env variable' do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = 'http://mycache.co.uk:8080'
      generate_base_urls
      @proxy_host.should eq('mycache.co.uk')
      @proxy_port.should eq('8080')
    end

    it 'should be able to use 80 as default proxy port when none specified' do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = 'http://mycache.co.uk'
      generate_base_urls
      @proxy_host.should eq('mycache.co.uk')
      @proxy_port.should eq('80')
    end

    it "should be able to handle an environment variable which doesn't have the protocol" do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = 'mycache.co.uk'
      generate_base_urls
      @proxy_host.should eq('mycache.co.uk')
      @proxy_port.should eq('80')
    end

    it 'should be able to have an empty http_proxy environment variable' do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['http_proxy'] = ''
      generate_base_urls
      @proxy_host.should be_nil
      @proxy_port.should be_nil
    end

    it 'should be able to set a local url with expected domain' do
      ENV['ENVIRONMENT'] = 'sandbox'
      ENV['FW_BBC_DOMAIN'] = 'bbc.com'
      generate_base_urls
      @base_url.should eq('http://pal.sandbox.dev.bbc.com')
      @ssl_base_url.should eq('https://ssl.sandbox.dev.bbc.com')
      @static_base_url.should eq('http://static.sandbox.dev.bbc.com')
      @m_base_url.should eq('http://m.sandbox.dev.bbc.com')
      @mobile_base_url.should eq('http://mobile.sandbox.dev.bbc.com')
    end

    it 'should be able to set a local system6 url with expected domain' do
      ENV['ENVIRONMENT'] = 'sandbox6'
      ENV['FW_BBC_DOMAIN'] = 'bbc.com'
      generate_base_urls
      @base_url.should eq('http://sandbox.bbc.com')
      @ssl_base_url.should eq('https://ssl.sandbox.bbc.com')
      @static_base_url.should eq('http://static.sandbox.bbc.com')
      @m_base_url.should eq('http://m.sandbox.bbc.com')
      @mobile_base_url.should eq('http://mobile.sandbox.bbc.com')
    end

    it 'should be able to set a base url with expected domain' do
      ENV['ENVIRONMENT'] = 'foo'
      ENV['FW_BBC_DOMAIN'] = 'bbc.com'
      generate_base_urls
      @base_url.should eq('http://www.foo.bbc.com')
      @ssl_base_url.should eq('https://ssl.foo.bbc.com')
      @static_base_url.should eq('http://static.foo.bbci.co.uk')
      @open_base_url.should eq('http://open.foo.bbc.com')
      @m_base_url.should eq('http://m.foo.bbc.com')
      @mobile_base_url.should eq('http://mobile.foo.bbc.com')
    end

    it 'should set public facing live domain' do
      ENV['ENVIRONMENT'] = 'live'
      ENV['WWW_LIVE'] = 'false'
      ENV['FW_BBC_DOMAIN'] = 'bbc.com'
      generate_base_urls
      @base_url.should eq('http://www.bbc.com')
      @ssl_base_url.should eq('https://ssl.bbc.com')
      @static_base_url.should eq('http://static.bbci.co.uk')
      @open_base_url.should eq('http://open.bbc.com')
      @m_base_url.should eq('http://m.bbc.com')
      @mobile_base_url.should eq('http://mobile.bbc.com')
    end
  end

  describe 'independent mechanize agent' do
    include Frameworks::EnvHelper

    it 'should allow you to create an independent, configured mechanize object' do
      ENV['HTTP_PROXY'] = 'http://mycache.co.uk:80'
      agent = new_mechanize
      agent.should be_a_kind_of Mechanize
      agent.proxy_addr.should eq('mycache.co.uk')
    end

    it 'the proxy should be separately configurable' do
      agent = new_mechanize('http://mycache.co.uk:80')
      agent.should be_a_kind_of Mechanize
      agent.proxy_addr.should eq('mycache.co.uk')
    end

    it 'the proxy should be ignored if the no_proxy exclusion is set' do
      proxy_host = 'mycache.co.uk'
      proxy_port = '80'
      proxy_uri = 'http://' + proxy_host + ':' + proxy_port
      no_proxy = 'ignore_this_host'
      ENV['NO_PROXY'] = no_proxy
      agent = new_mechanize(proxy_uri)
      expect(agent).to be_a_kind_of Mechanize
      expect(agent.agent.http.proxy_uri.host).to eq(proxy_host)
      expect(agent.agent.http.proxy_uri.port).to eq(proxy_port.to_i)
      no_proxy_array = [no_proxy]
      expect(agent.agent.http.no_proxy).to eq(no_proxy_array)
    end

    it 'the proxy should be ignored if the no_proxy exclusion is set with multiple values' do
      proxy_host = 'mycache.co.uk'
      proxy_port = '80'
      proxy_uri = 'http://' + proxy_host + ':' + proxy_port
      no_proxy1 = 'ignore_this_host'
      no_proxy2 = '.and.this.domain'
      ENV['NO_PROXY'] = no_proxy1 + ', ' + no_proxy2
      agent = new_mechanize(proxy_uri)
      expect(agent).to be_a_kind_of Mechanize
      expect(agent.agent.http.proxy_uri.host).to eq(proxy_host)
      expect(agent.agent.http.proxy_uri.port).to eq(proxy_port.to_i)
      no_proxy_array = [no_proxy1, no_proxy2]
      expect(agent.agent.http.no_proxy).to eq(no_proxy_array)
    end
  end
end
