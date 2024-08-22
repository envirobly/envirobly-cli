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

    api = Envirobly::Api.new
    response = api.create_deployment deployment_params
    @credentials = Envirobly::Aws::Credentials.new response.object.fetch("credentials")
    @bucket = response.object.fetch("bucket")

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
end
