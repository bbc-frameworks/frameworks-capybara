require 'capybara-webkit'
class Capybara::Driver::Webkit
  def kookies
    kookies = []

    cookies.send(:cookies).each do |cookie|
     kookies.push({
        :name => cookie.name,
        :value => cookie.value,
        :domain => cookie.domain,
        :secure => cookie.secure,
        :expires => cookie.expires,
        :path => cookie.path
      })
    end
    kcookies
  end

  def cookie_named(name)
    kookies.find { |c| c[:name] == name }
  end
end

