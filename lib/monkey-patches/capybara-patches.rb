require 'selenium-webdriver'
require 'capybara/cucumber'


##
#Monkey Patch's - Use with care!
#
class Capybara::Selenium::Node
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

class Capybara::Selenium::Driver
  def cookies
    browser.manage.all_cookies
  end

  def cookie_named(name)
    browser.manage.cookie_named(name)
  end

  def delete_cookie(cookie)
    browser.manage.delete_cookie(cookie)
  end

  def delete_all_cookies
    browser.manage.delete_all_cookies
  end

  def add_cookie(attribs)
    browser.manage.add_cookie(attribs)
  end
end

module Capybara
  class Session
    ##
    # Get all cookies
    #
    # @return [Array<Hash>] list of cookies
    #
    def cookies    
      driver.cookies
    end

    ##
    # Get the cookie with the given name
    #
    # @param [String] name the name of the cookie
    # @return [Hash, nil] the cookie, or nil if it wasn't found.
    #
    def cookie_named(name)    
      driver.cookie_named(name)
    end

    def delete_cookie(cookie)
      driver.delete_cookie(cookie)
    end

    def delete_all_cookies
      driver.delete_all_cookies
    end

    def add_cookie(attribs)
      driver.add_cookie(attribs)
    end

  end

end
