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

# This patch prevents Mechanize from raising a Mechanize::ResponseCodeError
# when the HTTP Response Code is in `allowed_error_codes`.
# https://github.com/tenderlove/mechanize/pull/248
class Mechanize::HTTP::Agent
  attr_accessor :allowed_error_codes

  alias_method :old_initialize, :initialize
  def initialize
    @allowed_error_codes      = []
    old_initialize
  end

  def fetch uri, method = :get, headers = {}, params = [],
            referer = current_page, redirects = 0
    referer_uri = referer ? referer.uri : nil

    uri = resolve uri, referer

    uri, params = resolve_parameters uri, method, params

    request = http_request uri, method, params

    connection = connection_for uri

    request_auth             request, uri

    disable_keep_alive       request
    enable_gzip              request

    request_language_charset request
    request_cookies          request, uri
    request_host             request, uri
    request_referer          request, uri, referer_uri
    request_user_agent       request
    request_add_headers      request, headers

    pre_connect              request

    # Consult robots.txt
    if robots && uri.is_a?(URI::HTTP)
      robots_allowed?(uri) or raise Mechanize::RobotsDisallowedError.new(uri)
    end

    # Add If-Modified-Since if page is in history
    page = visited_page(uri)

    if (page = visited_page(uri)) and page.response['Last-Modified']
      request['If-Modified-Since'] = page.response['Last-Modified']
    end if(@conditional_requests)

    # Specify timeouts if given
    connection.open_timeout = @open_timeout if @open_timeout
    connection.read_timeout = @read_timeout if @read_timeout

    request_log request

    response_body_io = nil

    # Send the request
    begin
      response = connection.request(uri, request) { |res|
        response_log res

        response_body_io = response_read res, request, uri

        res
      }
    rescue Mechanize::ChunkedTerminationError => e
      raise unless @ignore_bad_chunking

      response = e.response
      response_body_io = e.body_io
    end

    hook_content_encoding response, uri, response_body_io

    response_body_io = response_content_encoding response, response_body_io if
      request.response_body_permitted?

    post_connect uri, response, response_body_io

    page = response_parse response, response_body_io, uri

    response_cookies response, uri, page

    meta = response_follow_meta_refresh response, uri, page, redirects

    return meta if meta

    case response
    when Net::HTTPSuccess
      if robots && page.is_a?(Mechanize::Page)
        page.parser.noindex? and raise Mechanize::RobotsDisallowedError.new(uri)
      end

      page
    when Mechanize::FileResponse
      page
    when Net::HTTPNotModified
      log.debug("Got cached page") if log
      visited_page(uri) || page
    when Net::HTTPRedirection
      response_redirect response, method, page, redirects, headers, referer
    when Net::HTTPUnauthorized
      response_authenticate(response, page, uri, request, headers, params,
                            referer)
    else
      # BEGIN PATCH
      if @allowed_error_codes.any? {|code| code.to_s == page.code} then
        if robots && page.is_a?(Mechanize::Page)
          page.parser.noindex? and raise Mechanize::RobotsDisallowedError.new(uri)
        end

        page
      else
        raise Mechanize::ResponseCodeError.new(page, 'unhandled response')
      end
      # END PATCH
    end
  end
end