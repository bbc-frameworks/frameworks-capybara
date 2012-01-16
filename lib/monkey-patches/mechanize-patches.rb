require 'mechanize'
class Mechanize
  def set_ssl_client_certification(clientcert, clientkey, cacert)
    @cert, @key = clientcert, clientkey
    @ca_file = cacert if cacert
  end

  class CookieJar
    #hopefuly this alias approach will mean we capture changes in the mechanize method 
    alias_method :old_add, :add
    def add(uri, cookie)
      uri.host = uri.host.gsub(/:.*/,"") #if host contains a port remove it so cookie validation works e.g. sandbox:6081
      old_add(uri, cookie)
    end
  end

end

