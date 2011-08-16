require 'mechanize'
class Mechanize
  def set_ssl_client_certification(clientcert, clientkey)
    @cert, @key = clientcert, clientkey
  end
end
