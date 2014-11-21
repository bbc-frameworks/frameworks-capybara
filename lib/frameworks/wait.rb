require 'time'

class Wait
  ##
  # Execute a block until it returns true.
  # Optionally pass a timeout (by default 5 seconds).
  # 
  # wait = Wait.new
  # wait.until {
  #   (Random.rand(2) % 2)
  # }
  # 
  # wait.until(:timeout => 4) {
  #   (Random.rand(2) % 2)
  # }
  # 
  def Wait.until(options={:timeout => 5})
    timeout = Time.new + options[:timeout].to_f

    while (Time.new < timeout)
      return if (yield)
    end
    raise 'Timeout exceeded for wait until.'
  end
end