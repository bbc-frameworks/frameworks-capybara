require 'selenium-webdriver'
require 'capybara/cucumber'

#Monkey Patch's - Use with care!
#
class Capybara::Driver::Selenium::Node
  def style(prop)
    native.style(prop)
  end
end

class Capybara::Node::Element
  def style(prop)
    base.style(prop)
  end
end

class Capybara::Driver::Node
  def style(prop)
    raise NotImplementedError
  end
end

