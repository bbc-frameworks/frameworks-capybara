require 'spec_helper'
require 'rspec/mocks/mock'
require 'uri'

describe Capybara::Mechanize::Browser do

  RSpec::Mocks::setup(self)

  it "should send referer for GET requests" do

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
end