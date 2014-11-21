require 'frameworks/wait'

describe Wait do
  it "should exit silently if the block returns true" do
    Wait.until(){
    	true
    }
  end

  it "should raise an exception if the default timeout expires" do
    start_time = Time.now
    expect {
      Wait.until(){
      	Time.now > (start_time + (6 * 60))
      }
    }.to raise_error
  end

  it "should raise an exception if the specified timeout expires" do
    start_time = Time.now
    expect {
      Wait.until(options={:timeout => 1}) do
        Time.now > (start_time + (2 * 60))
      end
    }.to raise_error
  end
end