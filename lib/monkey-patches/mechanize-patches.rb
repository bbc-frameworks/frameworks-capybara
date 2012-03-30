require 'mechanize'
#This patch is required Mechanize runs the clear before each new request
#and not after each response, operationaly this is fine, but because
#we check after response and it may be the last response we need it to clear here.
class Mechanize::CookieJar
  alias_method :old_add, :add
  def add(uri, cookie)
    cleanup
    old_add(uri, cookie)
  end
end
#This patch may still be required, think it is only not needed now because we don't run
#full facebook journey, only mock in idtests
=begin
# Fetches the URL passed in and returns a page.
  def get(uri, parameters = [], referer = nil, headers = {})
    method = :get

    if Hash === uri then
      options = uri
      location = Gem.location_of_caller.join ':'
      warn "#{location}: Mechanize#get with options hash is deprecated and will be removed October 2011"

      raise ArgumentError, "url must be specified" unless uri = options[:url]
      parameters = options[:params] || []
      referer    = options[:referer]
      headers    = options[:headers]
      method     = options[:verb] || method
    end

    #FRAMEWORKS-PATCH - CHANGE LOGIC in 'if' so that =~ becomes !~ in order for 
    #referer to be set correctly.
    referer ||=
      if uri.to_s !~ %r{\Ahttps?://}
        Page.new(nil, {'content-type'=>'text/html'})
      else
        current_page || Page.new(nil, {'content-type'=>'text/html'})
      end

    # FIXME: Huge hack so that using a URI as a referer works.  I need to
    # refactor everything to pass around URIs but still support
    # Mechanize::Page#base
    unless referer.is_a?(Mechanize::File)
      referer = referer.is_a?(String) ?
      Page.new(URI.parse(referer), {'content-type' => 'text/html'}) :
        Page.new(referer, {'content-type' => 'text/html'})
    end

    # fetch the page
    headers ||= {}
    page = @agent.fetch uri, method, headers, parameters, referer
    add_to_history(page)
    yield page if block_given?
    page
  end

end
=end

