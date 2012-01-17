require 'mechanize'
class Mechanize
  def set_ssl_client_certification(clientcert, clientkey, cacert)
    @cert, @key = clientcert, clientkey
    @ca_file = cacert if cacert
  end
end
