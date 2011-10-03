require 'spec_helper'

describe Frameworks::EnvHelper do
  it "should set base url correctly" do
    before do
      ENV['BROWSER'] = 'test'
    end
    it "should be able to set the test environment" do
      ENV['ENVIRONMENT'] = 'test'
      
    end
  end
end
