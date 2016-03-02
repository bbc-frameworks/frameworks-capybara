require 'rspec'
require_relative '../lib/frameworks/logger'

describe FrameworksCapybara::Logger do
  describe 'log levels' do
    let(:test) { Class.new { include FrameworksCapybara::Logger }.new }

    it 'sets a default log level of debug' do
      expect(test.log_level).to eql :debug
    end

    it 'allows_log_level to be overwritten uppercase' do
      ENV['LOG_LEVEL'] = 'WARN'
      expect(test.log_level).to eql :warn
    end

    it 'allows_log_level to be overwritten lowercase' do
      ENV['LOG_LEVEL'] = 'info'
      expect(test.log_level).to eql :info
    end

    it 'ignores invalid log levels' do
      ENV['LOG_LEVEL'] = 'FOOBAR'
      expect(test.log_level).to eql :debug
    end
  end
end
