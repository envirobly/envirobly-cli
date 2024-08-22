require "time"
require "json"
require "uri"
require "net/http"
require "socket"
# require "debug"

class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "deploy ENVIRONMENT_NAME", "Deploy current commit to an environment"
  method_option :commit, type: :string, default: "HEAD"
  def deploy(environment)
    @commit = Envirobly::Git::Commit.new options.commit

    unless @commit.exists?
      $stderr.puts "Commit #{options.commit} doesn't exist in this repository. Aborting."
      exit 1
    end

    deployment_params = {
      environ: {
        name: environment
      },
      commit: {
        ref: @commit.ref,
        time: @commit.time,
        message: @commit.message
      }
    }

    response = post_as_json api_v1_deployments_url, deployment_params
    $stderr.puts "#{api_v1_deployments_url} responded with #{response.code}"

    unless response.code.to_i == 200
      $stderr.puts "Request didn't succeed. Aborting."
      exit 1
    end

    response_object = JSON.parse response.body
    @credentials = Envirobly::Aws::Credentials.new response_object.fetch("credentials")
    @bucket = response_object.fetch("bucket")

    if archive_build_context
      $stderr.puts "Build context exported into #{archive_uri}"
    else
      $stderr.puts "Error exporting build context. Aborting."
      exit 1
    end
  end

  private
    def archive_uri
      "s3://#{@bucket}/#{@commit.ref}.tar.gz"
    end

    def archive_build_context
      `git archive --format=tar.gz #{@commit.ref} | #{@credentials.as_inline_env_vars} aws s3 cp - #{archive_uri}`
      $?.success?
    end

    def api_host
      ENV["ENVIROBLY_API_HOST"] || "envirobly.com"
    end

    def api_v1_deployments_url
      URI::HTTPS.build(host: api_host, path: "/api/v1/deployments")
    end

    def post_as_json(uri, params = {})
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

      http.request request
    end
end
