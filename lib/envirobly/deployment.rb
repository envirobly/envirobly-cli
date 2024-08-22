class Envirobly::Deployment
  URL_MATCHER = /^https:\/\/envirobly\.(test|com)\/(\d+)\/environs\/(\d+)$/

  def initialize(environment, options)
    @commit = Envirobly::Git::Commit.new options.commit

    unless @commit.exists?
      $stderr.puts "Commit #{options.commit} doesn't exist in this repository. Aborting."
      exit 1
    end

    deployment_params = {
      environ: {
        logical_id: environment
      },
      commit: {
        ref: @commit.ref,
        time: @commit.time,
        message: @commit.message
      }
    }

    unless environment =~ URL_MATCHER
      $stderr.puts "If no environ URL is provided, remote.origin is required in config"
      exit 1
    end

    api = Envirobly::Api.new
    response = api.create_deployment deployment_params
    @credentials = Envirobly::Aws::Credentials.new response.object.fetch("credentials")
    @bucket = response.object.fetch("bucket")

    if archive_commit_and_upload
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

    def archive_commit_and_upload
      `git archive --format=tar.gz #{@commit.ref} | #{@credentials.as_inline_env_vars} aws s3 cp - #{archive_uri}`
      $?.success?
    end
end
