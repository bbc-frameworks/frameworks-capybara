require 'mechanize'
class Mechanize
  def set_ssl_client_certification(clientcert, clientkey, cacert)
    @cert, @key, @ca_file = clientcert, clientkey, cacert
  end
end
