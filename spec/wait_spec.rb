require 'frameworks/wait'

describe FrameworksCapybara::Wait do
  let(:test) { Class.new { include FrameworksCapybara::Wait }.new }

  describe 'wait_for' do
    it "should exit silently if the block returns true" do
      test.wait_for { true }
    end

    it "should raise an exception if the default timeout expires" do
      start_time = Time.now
      expect { test.wait_for { Time.now > (start_time + (6 * 60)) } }.to raise_error
    end

    it "should raise an exception if the specified timeout expires" do
      start_time = Time.now
      expect {
        test.wait_for(timeout: 1) do
          Time.now > (start_time + (2 * 60))
        end
      }.to raise_error
    end
  end

  describe 'wait for an rspec assertion' do
    it 'should allow us to wait for assertions' do
      expect(test.wait_for_assertion('msg') { expect(true).to eql true }).to be true
    end

    it 'should raise rspec expectation error when condition is not met' do
      error = RSpec::Expectations::ExpectationNotMetError
      expect { test.wait_for_assertion('msg') { expect(true).to eql false } }.to raise_error(error)
    end
  end

  describe 'wait for an arbitrary assertion' do
    it 'should catch provided exception until block no longer raises it' do
      error = ZeroDivisionError
      expect(test.wait_for_no_exception('msg', error) { 1/1 == 1 }).to eql true
    end

    it 'should catch provided exception until block no longer raises it or timeout' do
      error = ZeroDivisionError
      expect { test.wait_for_no_exception('msg', error) { expect(1/0).to eql 1 } }.to raise_error(error)
    end
  end
end
