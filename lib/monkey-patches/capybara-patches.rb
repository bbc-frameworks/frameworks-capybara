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

    DTD_REFS = {
      "-//W3C//DTD XHTML 1.0 Strict//EN" => {:dtd => "#{File.dirname( __FILE__)}/../../schemas/xhtml1-strict.dtd", :type => :strict},
      "-//W3C//DTD XHTML 1.0 Transitional//EN" => {:dtd => "#{File.dirname( __FILE__)}/../../schemas/xhtml1-transitional.dtd", :type => :transitional}, 
      "-//W3C//DTD XHTML+RDFa 1.0//EN" => {:dtd => "#{File.dirname( __FILE__)}/../../schemas/xhtml-rdfa-1.dtd", :type => :rdfa}}
      #I highly recomment NOT using this method
      def validate(source)
        doctype = source.scan(/\"(.*?)\"/)[0].to_s 

        if(DTD_REFS[doctype])
          dtd = DTD_REFS[doctype][:dtd]
          type = DTD_REFS[doctype][:type]
        end

        raise "RDFA Validation not currently supported due to issues in Nokogiri" if type == :rdfa

        if(RUBY_PLATFORM == 'java') #this works
          source = source.gsub(/PUBLIC \"-\/\/W3C\/\/DTD XHTML.*?\/\/EN\" \"http:\/\/www.w3.org.*?\"/, "SYSTEM \"#{dtd}\"")
          doc = Nokogiri::XML(source) { |cfg|
            cfg.noent.dtdload.dtdvalid
          }
          doc = Nokogiri::XML(source)
          errors = doc.validate
        else #this doesn't - nokogiri issues
          require 'open-uri'
          doc = Nokogiri::XML(open(driver.current_url, :proxy => ENV['HTTP_PROXY'])) do |config|
            config.strict.noent
          end
          #xsd = Nokogiri::XML::Schema(File.read("#{File.dirname( __FILE__)}/../../schemas/xhtml1-strict.xsd"))
          xsd = Nokogiri::XML::Schema(open('http://www.w3.org/2002/08/xhtml/xhtml1-strict.xsd', :proxy => ENV['HTTP_PROXY']))
          errors = xsd.validate(doc)
        end
        raise "Page (#{current_url}) failed XHTML vaidation (or Nokogiri Freaked out...please manually check against W3C), errors:#{errors.to_s}" unless errors == []
      end
  end
end


