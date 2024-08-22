class Envirobly::Api
  HOST = ENV["ENVIROBLY_API_HOST"] || "envirobly.com"

  def create_deployment(params)
    post_as_json(api_v1_deployments_url, params)
  end

  private
    def post_as_json(uri, params = {}, require_response_code: 200)
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 10

      headers = {
        "User-Agent" => "Envirobly CLI v#{Envirobly::VERSION} #{Socket.gethostname}"
      }
      request = Net::HTTP::Post.new(uri, headers)
      request.content_type = "application/json"
      request.body = params.to_json

      http.request(request).tap do |response|
        unless response.code.to_i == require_response_code
          $stderr.puts "Request to #{uri} responded with #{response.code}. Aborting."
          exit 1
        end

        def response.object
          @json_parsed_body ||= JSON.parse body
        end
      end
    end

    def api_v1_deployments_url
      URI::HTTPS.build(host: HOST, path: "/api/v1/deployments")
    end
end
