class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "validate", "Validates config"
  def validate
    commit = Envirobly::Git::Unstaged.new
    config = Envirobly::Config.new(commit)
    params = {
      shape: {
        content: config.raw,
        file_secrets: [] # TODO
      }
    }

    api = Envirobly::Api.new
    response = api.validate_shape params

    if response.object.fetch("valid")
      puts "All checks pass."
    else
      puts "Issues found validating '#{Envirobly::Config::PATH}':"
      puts
      response.object.fetch("errors").each_with_index do |error, index|
        puts "  #{index + 1}. #{error}"
      end
      puts
      exit 1
    end
  end

  desc "deploy ENVIRONMENT", "Deploy to environment identified by name or URL"
  method_option :commit, type: :string, default: "HEAD"
  method_option :dry_run, type: :boolean, default: false
  def deploy(environment)
    Envirobly::Deployment.new environment, options
  end

  desc "set_access_token TOKEN", "Save and use an access token generated at Envirobly"
  def set_access_token
    token = ask("Access Token:", echo: false).strip

    if token.blank?
      $stderr.puts
      $stderr.puts "Token can't be empty."
      exit 1
    end

    Envirobly::AccessToken.new(token).save
  end

  desc "push", "Push commit manifest and blobs to S3"
  def push(region, bucket, ref = "HEAD")
    commit = Envirobly::Git::Commit.new ref
    s3 = Envirobly::Aws::S3.new(region:, bucket:)
    s3.push commit
  end

  desc "pull", "Download working copy from S3"
  def pull(region, bucket, ref, path)
    s3 = Envirobly::Aws::S3.new(region:, bucket:)
    s3.pull ref, path
  end
end
