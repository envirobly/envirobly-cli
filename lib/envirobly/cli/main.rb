class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "validate", "Validates config"
  def validate
    configs = Envirobly::Configs.new

    params = {
      shape: configs.to_params
    }

    api = Envirobly::Api.new
    response = api.validate_shape params

    if response.object.fetch("valid")
      puts "All checks pass."
    else
      response.object.fetch("errors").each do |config_path, messages|
        puts "#{config_path}:"
        puts
        messages.each_with_index do |message, index|
          puts "    #{message}"
          puts
        end
      end

      exit 1
    end
  end

  desc "deploy [ENVIRON_NAME]", <<~TXT
    Deploy to environment identified by name.
    When name is empty, current git branch name is used.
  TXT
  method_option :commit, type: :string, default: "HEAD"
  method_option :dry_run, type: :boolean, default: false
  def deploy(environ_name = Envirobly::Git.new.current_branch)
    Envirobly::Deployment.new environ_name, options
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
    # TODO: Work with existing target directory: a) download missing/changed files; b) delete removed files; c) apply executable status
    s3 = Envirobly::Aws::S3.new(region:, bucket:)
    s3.pull ref, path
  end

  desc "object_tree", "Show object tree used for deployments"
  method_option :commit, type: :string, default: "HEAD"
  def object_tree
    commit = Envirobly::Git::Commit.new options.commit
    pp commit.object_tree
  end
end
