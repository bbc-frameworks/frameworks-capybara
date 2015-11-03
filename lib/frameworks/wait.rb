require 'time'

module FrameworksCapybara
  module Wait
    ##
    # Execute a block until it returns true.
    # Optionally pass a timeout (by default 5 seconds).
    #
    # wait_for { (Random.rand(2) % 2) }
    #
    # wait_for(:timeout => 4) { (Random.rand(2) % 2) }
    #
    def wait_for(options={:timeout => 5})
      timeout = Time.new + options[:timeout].to_f

      while (Time.new < timeout)
        return if (yield)
      end
      raise 'Timeout exceeded for wait until.'
    end

    ##
    # Execute a block containing RSpec assertion, catch failures and wait till it passes
    # Pass an exception message to be outputted on failure and a block
    # Optionally pass a timeout, sleep interval
    #
    # wait_for_assertion('Cannot find foo on page') do
    #   expect(page).to have_content 'foo'
    # end
    #
    def wait_for_assertion(exception_message, timeout = Capybara.default_max_wait_time, sleep_interval = 0.5, &block)
      wait_for_no_exception(exception_message,
                            RSpec::Expectations::ExpectationNotMetError,
                            timeout, sleep_interval, &block)
    end

    ##
    # Execute a block and catch a specific exception until timeout or no exception
    # Pass an exception message to be outputted on failure and a block
    # Optionally pass a timeout, sleep interval
    #
    # wait_for_no_exception('Author image not visible', SitePrism::TimeOutWaitingForElementVisibility) do
    #   article.wait_until_author_image_visible
    # end
    #
    def wait_for_no_exception(exception_message, exception, timeout = Capybara.default_max_wait_time, sleep_interval = 1, &block)
      fail 'You need to provide a block' unless block_given?
      test_exception = 'check did not return within timeout window.'
      begin
        Timeout.timeout(timeout) do
          loop do
            begin
              block.call
              return true
            rescue exception => assertion_exception
              puts "#{exception_message} - rescuing: #{exception.to_s} and trying to call block again!"
              test_exception = assertion_exception
              sleep sleep_interval
            end
          end
        end
      rescue TimeoutError
        puts '********************************************************************'
        puts "Timed out after waiting for #{timeout} seconds."
        puts exception_message
        puts "#{test_exception}"
        puts '********************************************************************'
        raise test_exception
      rescue => standard_error
        puts '********************************************************************'
        puts "Got an unexpected exception type: #{standard_error.class}"
        puts "#{standard_error}"
        puts 'Check your code for puts!'
        puts '********************************************************************'
        raise standard_error
      end
    end
  end
end
