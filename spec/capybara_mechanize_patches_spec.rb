require 'spec_helper'
require 'rspec/mocks/mock'
require 'uri'

describe Capybara::Mechanize::Browser do

  RSpec::Mocks::setup(self)

  it "shouldn't send referer if unknown" do

    agent = double()
    agent.stub('get' => true)
    agent.should_receive('get').with(
      "http://example.bbc.co.uk/test",
      {},
      nil,
      {}
    )

    driver = double("Capybara::Mechanize::Driver")
    
    browser = Capybara::Mechanize::Browser.new(driver)
    browser.stub('current_url' => "")
    browser.stub('agent' => agent)

    browser.process_remote_request(:get, 'http://example.bbc.co.uk/test', {}, {})
  end

  it "should not change behaviour for POST requests" do

    agent = double()
    agent.stub('post' => true)
    agent.should_receive('post').with("http://example.bbc.co.uk/test")

    driver = double("Capybara::Mechanize::Driver")
    
    browser = Capybara::Mechanize::Browser.new(driver)
    browser.stub('current_url' => "http://example.bbc.co.uk/blah")
    browser.stub('agent' => agent)

    browser.process_remote_request(:post, 'http://example.bbc.co.uk/test', {}, {})
  end

  it "should not send referer for requests from HTTPs to HTTP" do

    agent = double()
    agent.stub('get' => true)
    agent.should_receive('get').with(
      "http://example.bbc.co.uk/test",
      {},
      nil,
      {}
    )

    driver = double("Capybara::Mechanize::Driver")
    
    browser = Capybara::Mechanize::Browser.new(driver)
    browser.stub('current_url' => "https://example.bbc.co.uk/blah")
    browser.stub('agent' => agent)

    browser.process_remote_request(:get, 'http://example.bbc.co.uk/test', {}, {})
  end

  it "should send referer for requests from HTTP to HTTPs" do

    agent = double()
    agent.stub('get' => true)
    agent.should_receive('get').with(
      "https://example.bbc.co.uk/test",
      {},
      "http://example.bbc.co.uk/blah",
      {}
    )

    driver = double("Capybara::Mechanize::Driver")
    
    browser = Capybara::Mechanize::Browser.new(driver)
    browser.stub('current_url' => "http://example.bbc.co.uk/blah")
    browser.stub('agent' => agent)

    browser.process_remote_request(:get, 'https://example.bbc.co.uk/test', {}, {})
  end

  it "should send referer for requests from HTTP to HTTP" do

    agent = double()
    agent.stub('get' => true)
    agent.should_receive('get').with(
      "http://example.bbc.co.uk/test",
      {},
      "http://example.bbc.co.uk/blah",
      {}
    )

    driver = double("Capybara::Mechanize::Driver")
    
    browser = Capybara::Mechanize::Browser.new(driver)
    browser.stub('current_url' => "http://example.bbc.co.uk/blah")
    browser.stub('agent' => agent)

    browser.process_remote_request(:get, 'http://example.bbc.co.uk/test', {}, {})
  end

  it "should send referer for requests from HTTPs to HTTPs" do
    
    agent = double()
    agent.stub('get' => true)
    agent.should_receive('get').with(
      "https://example.bbc.co.uk/test",
      {},
      "https://example.bbc.co.uk/blah",
      {}
    )

    driver = double("Capybara::Mechanize::Driver")
    
    browser = Capybara::Mechanize::Browser.new(driver)
    browser.stub('current_url' => "https://example.bbc.co.uk/blah")
    browser.stub('agent' => agent)

    browser.process_remote_request(:get, 'https://example.bbc.co.uk/test', {}, {})
  end

end