require 'rspec'
require_relative '../lib/frameworks/utils'

describe FrameworksCapybara::Utils do
  describe 'generic util methods' do
    let(:test) { Class.new { include FrameworksCapybara::Utils }.new }
    it 'converts english to ruby method name' do
      expect(test.rubyize('Hello Matt')).to eql 'hello_matt'
    end
  end
end
