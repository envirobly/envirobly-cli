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
  def deploy(environ_name)
    unless commit_exists?
      $stderr.puts "Commit #{options.commit} doesn't exist in this repository. Aborting."
      exit 1
    end

    deployment_params = {
      environ: {
        name: environ_name
      },
      commit: {
        ref: commit_ref,
        time: commit_time,
        message: commit_message
      }
    }
    # puts deployment_params.to_json

    response = post_as_json api_v1_deployments_url, deployment_params
    $stderr.puts "#{api_v1_deployments_url} responded with #{response.code}"

    unless response.code.to_i == 200
      $stderr.puts "Request didn't succeed. Aborting."
      exit 1
    end

    response_object = JSON.parse response.body
    # puts response_object.to_json
    @credentials = response_object.fetch("credentials")
    @bucket = response_object.fetch("bucket")

    if archive_build_context
      $stderr.puts "Build context exported into #{archive_uri}"
    else
      $stderr.puts "Error exporting build context. Aborting."
      exit 1
    end
  end

  private
    def commit_exists?
      `git cat-file -t #{options.commit}`.chomp("") == "commit"
    end

    def commit_ref
      @commit_ref ||= `git rev-parse #{options.commit}`.chomp("")
    end

    def commit_message
      `git log #{options.commit} -n1 --pretty=%B`.chomp("")
    end

    def commit_time
      Time.parse `git log #{options.commit} -n1 --date=iso --pretty=format:"%ad"`
    end

    def archive_uri
      "s3://#{@bucket}/#{commit_ref}.tar.gz"
    end

    def archive_build_context
      `git archive --format=tar.gz #{commit_ref} | #{credentials_as_inline_env_vars} aws s3 cp - #{archive_uri}`
      $?.success?
    end

    def credentials_as_inline_env_vars
      [
        %{AWS_ACCESS_KEY_ID="#{@credentials.fetch("access_key_id")}"},
        %{AWS_SECRET_ACCESS_KEY="#{@credentials.fetch("secret_access_key")}"},
        %{AWS_SESSION_TOKEN="#{@credentials.fetch("session_token")}"}
      ].join " "
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
