require "json"
require "net/http"
require "socket"
require "uri"

class Envirobly::Api
  HOST = ENV["ENVIROBLY_API_HOST"] || "envirobly.com"
  USER_AGENT = "Envirobly CLI v#{Envirobly::VERSION}"
  CONTENT_TYPE = "application/json"

  def initialize
    @access_token = Envirobly::AccessToken.new
  end

  def validate_shape(params)
    post_as_json(api_v1_shape_validations_url, params:, headers: authorization_headers).tap do |response|
      unless response.success?
        $stderr.puts "Validation request responded with #{response.code}. Aborting."
        exit 1
      end
    end
  end

  def create_deployment(params)
    post_as_json(api_v1_deployments_url, params:, headers: authorization_headers)
  end

  def list_accounts
    get_as_json api_v1_accounts_url, headers: authorization_headers
  end

  def list_regions
    get_as_json api_v1_regions_url, headers: authorization_headers
  end

  MAX_RETRIES = 30
  SHORT_RETRY_INTERVAL = 2.seconds
  LONG_RETRY_INTERVAL = 6.seconds
  def get_deployment_with_delay_and_retry(url, tries = 1)
    sleep SHORT_RETRY_INTERVAL * tries
    response = get_as_json URI(url)

    if response.success?
      response
    elsif MAX_RETRIES <= tries
      $stderr.puts "Max retries exhausted while waiting for deployment credentials. Aborting."
      exit 1
    else
      if tries > 3
        sleep LONG_RETRY_INTERVAL
      else
        sleep SHORT_RETRY_INTERVAL
      end

      get_deployment_with_delay_and_retry(url, tries + 1)
    end
  end

  def get_as_json(url, headers: {})
    request(url, type: Net::HTTP::Get, headers:)
  end

  def post_as_json(url, params: {}, headers: {})
    request(url, type: Net::HTTP::Post, headers:) do |request|
      request.body = params.to_json
    end
  end

  def put_as_json(url, params: {}, headers: {})
    request(url, type: Net::HTTP::Put, headers:) do |request|
      request.body = params.to_json
    end
  end

  private
    def api_v1_shape_validations_url
      api_url_for "v1/shape_validations"
    end

    def api_v1_deployments_url
      api_url_for "v1/deployments"
    end

    def api_v1_accounts_url
      api_url_for "v1/accounts"
    end

    def api_v1_regions_url
      api_url_for "v1/regions"
    end

    def api_url_for(path)
      URI::HTTPS.build(host: HOST, path: "/api/#{path}")
    end

    def request(url, type:, headers: {})
      uri = URI(url)
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 10

      headers = default_headers.merge headers
      request = type.new(uri, headers)
      request.content_type = CONTENT_TYPE

      yield request if block_given?

      http.request(request).tap do |response|
        def response.object
          @json_parsed_body ||= JSON.parse(body)
        end

        def response.success?
          (200..299).include?(code.to_i)
        end
      end
    end

    def default_headers
      { "User-Agent" => USER_AGENT, "X-Cli-Host" => Socket.gethostname }
    end

    def authorization_headers
      { "Authorization" => @access_token.as_http_bearer }
    end
end
