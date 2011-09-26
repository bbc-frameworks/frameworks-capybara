require 'spec_helper'


describe CapybaraSetup do

  before do
    ENV['BROWSER'] = 'Firefox'
    CapybaraSetup.new
  end

  it "should be initialized" do 
    @driver.should_not == nil
  end
end

