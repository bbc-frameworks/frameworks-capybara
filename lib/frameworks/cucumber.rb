require 'frameworks/capybara'
require 'w3c_validators'

module Frameworks
  # Generate base urls to use in Cucumber step defs
  module EnvHelper
    include W3CValidators
    # Generate base urls to use in Cucumber step defs
    def generate_base_urls
      environment = ENV['ENVIRONMENT'].downcase # be defensive

      prepare_host

      if environment == 'sandbox'
        @base_url = @sandbox + @bbc_domain
        @pal_base_url = @sandbox + @bbc_domain
        @ssl_base_url = @sslsandbox + @bbc_domain
        @static_base_url = @static_sandbox + @bbc_domain
        @mobile_base_url = @mobiledot_prefix + 'sandbox.dev' + @bbc_domain
        @m_base_url = @mdot_prefix + 'sandbox.dev' + @bbc_domain
      elsif environment == 'sandbox6'
        @base_url = @sandbox6 + @bbc_domain
        @pal_base_url = @sandbox6 + @bbc_domain
        @ssl_base_url = @sslsandbox6 + @bbc_domain
        @static_base_url = @static_sandbox6 + @bbc_domain
        @mobile_base_url = @mobiledot_prefix + 'sandbox' + @bbc_domain
        @m_base_url = @mdot_prefix + 'sandbox' + @bbc_domain
      elsif environment == 'live'
        @base_url = @www_prefix.chop + @bbc_domain
        @pal_base_url = @pal_prefix + environment + @bbc_domain
        @ssl_base_url = @ssl_prefix.chop + @bbc_domain
        @static_base_url = @static_prefix.chop + @bbci_domain
        @open_base_url = @open_prefix.chop + @bbc_domain
        @mobile_base_url = @mobiledot_prefix.chop + @bbc_domain
        @m_base_url = @mdot_prefix.chop + @bbc_domain
      else
        @base_url = @www_prefix + environment + @bbc_domain
        @pal_base_url = @pal_prefix + environment + @bbc_domain
        @ssl_base_url = @ssl_prefix + environment + @bbc_domain
        @static_base_url = @static_prefix + environment + @bbci_domain
        @static_base_url = @static_prefix.chop + @bbci_domain if environment == 'live'
        @open_base_url = @open_prefix + environment + @bbc_domain
        @mobile_base_url = @mobiledot_prefix + environment + @bbc_domain
        @m_base_url = @mdot_prefix + environment + @bbc_domain
      end

      proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
      proxy_parts = proxy.scan(%r{(?:http://)?([^\:]+)(?::(\d+))?}) if proxy && !proxy.empty?
      if proxy_parts && !proxy_parts.empty?
        @proxy_host = proxy_parts[0][0]
        @proxy_port = if proxy_parts[0][1]
                        proxy_parts[0][1]
                      else
                        '80'
                      end
      end
    end

    def validate_online(src, validator_args = nil)
      args = { proxy_host: @proxy_host, proxy_port: @proxy_port }
      args = args.merge(validator_args) unless validator_args.nil?
      @validator = MarkupValidator.new(args)

      @validator.set_doctype!(:xhtml)
      begin
        results = @validator.validate_text(src)

        unless results.errors.empty?
          results.errors.each do |err|
            puts err.to_s
          end
          raise 'W3C Validation failed.'
        end
      rescue SystemCallError => e
        puts "System error whilst performing request to W3C: #{e}"
      end
    end

    def prepare_host
      scheme = ENV['SCHEME'] == 'https' ? 'https' : 'http'
      @www_prefix = "#{scheme}://www."
      @pal_prefix = "#{scheme}://pal."
      @ssl_prefix = 'https://ssl.'
      @static_prefix = "#{scheme}://static."
      @open_prefix = "#{scheme}://open."
      @bbc_domain = '.' + (ENV['FW_BBC_DOMAIN'] || 'bbc.co.uk')
      @bbci_domain = '.bbci.co.uk'
      @sandbox = "#{scheme}://pal.sandbox.dev"
      @sandbox6 = "#{scheme}://sandbox"
      @mobiledot_prefix = "#{scheme}://mobile."
      @mdot_prefix = "#{scheme}://m."
      @sslsandbox = 'https://ssl.sandbox.dev'
      @sslsandbox6 = 'https://ssl.sandbox'
      @static_sandbox = "#{scheme}://static.sandbox.dev"
      @static_sandbox6 = "#{scheme}://static.sandbox"
    end

    def setup_mechanize(agent, http_proxy = nil)
      http_proxy = http_proxy || ENV['HTTP_PROXY'] || ENV['http_proxy']

      if ENV['FW_CERT_LOCATION']
        agent.cert = ENV['FW_CERT_LOCATION']
        agent.key = ENV['FW_CERT_LOCATION']
      end

      agent.ca_file = ENV['CA_CERT_LOCATION'] if ENV['CA_CERT_LOCATION']
      agent.set_proxy(http_proxy.scan(%r{http://(.*):80})[0][0].to_s, 80) if http_proxy && !http_proxy.empty?

      # The above proxy setting ignores any no_proxy variable setting:
      # added the following to circumvent this
      if http_proxy
        no_proxy = ENV['NO_PROXY'] || ENV['no_proxy']
        if no_proxy
          # The no_proxy query string argument must not contain spaces
          no_proxy_qs = no_proxy.gsub(/[, ]+/, ',')
          agent.agent.http.proxy = URI(http_proxy + '?no_proxy=' + no_proxy_qs)
        end
      end

      # This is necessary because Mech2 does not ship with root certs like Mech1 did and boxes may not have the OpenSSL set installed
      agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

      # This prevents Mechanize from raising a Mechanize::ResponseCodeError
      # when the HTTP Response Code is 404 or 503. This lets capybara continue the journey.
      agent.agent.allowed_error_codes = %w[404 503]
    end

    def new_mechanize(http_proxy = nil)
      require 'mechanize'
      agent = Mechanize.new
      setup_mechanize(agent, http_proxy)
      agent
    end
  end # EnvHelper
end # Frameworks

# Add module into world to ensure visibility of instance variables within Cucumber
World(Frameworks::EnvHelper)

Before do
  setup_mechanize(page.driver.browser.agent) if page.driver.class == Capybara::Mechanize::Driver
  generate_base_urls
end
