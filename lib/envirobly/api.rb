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

  def create_deployment(params)
    post_as_json(api_v1_deployments_url, params:, headers: authorization_headers).tap do |response|
      unless response.code.to_i == 200
        $stderr.puts "Deployment creation request responded with #{response.code}. Aborting."
        exit 1
      end
    end
  end

  RETRY_INTERVAL_SECONDS = 3
  MAX_RETRIES = 5
  def get_deployment_with_delay_and_retry(url, tries = 1)
    sleep RETRY_INTERVAL_SECONDS * tries
    response = get_as_json URI(url)

    if response.code.to_i == 200
      return response
    elsif MAX_RETRIES <= tries
      $stderr.puts "Max retries exhausted while waiting for deployment credentials. Aborting."
      exit 1
    else
      sleep RETRY_INTERVAL_SECONDS * tries
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
    def api_v1_deployments_url
      URI::HTTPS.build(host: HOST, path: "/api/v1/deployments")
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
          @json_parsed_body ||= JSON.parse body
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
