require 'capybara-webkit'
class Capybara::Driver::Webkit
  def get_cookies
    scookies = []

    cookies.send(:cookies).each do |cookie|
     scookies.push({
        :name => cookie.name,
        :value => cookie.value,
        :domain => cookie.domain,
        :secure => cookie.secure,
        :expires => cookie.expires,
        :path => cookie.path
      })
    end
    p '--cookies--'
    p scookies
    p '--cookies--'
    scookies
  end

  def cookie_named(name)
    get_cookies.find { |c| c[:name] == name }
  end
end

