class Envirobly::Cli::Main < Envirobly::Base
  include Envirobly::Colorize

  desc "version", "Show Envirobly CLI version"
  method_option :pure, type: :boolean, default: false
  def version
    if options.pure
      puts Envirobly::VERSION
    else
      puts "envirobly CLI v#{Envirobly::VERSION}"
    end
  end

  desc "validate", "Validates config"
  def validate
    configs = Envirobly::Configs.new
    api = Envirobly::Api.new

    params = { validation: configs.to_params }
    response = api.validate_shape params

    if response.object.fetch("valid")
      puts "Config is valid #{green_check}"
    else
      display_config_errors response.object.fetch("errors")
      exit 1
    end
  end

  desc "deploy [ENVIRON_NAME]", <<~TXT
    Deploy to environment identified by name.
    When name is empty, current git branch name is used.
  TXT
  method_option :commit, type: :string, default: "HEAD"
  method_option :dry_run, type: :boolean, default: false
  method_option :account_id, type: :numeric
  method_option :project_name, type: :string, default: File.basename(Dir.pwd)
  method_option :project_region, type: :string
  def deploy(environ_name = Envirobly::Git.new.current_branch)
    deployment = Envirobly::Deployment.new(
      environ_name:,
      commit_ref: options.commit,
      account_id: options.account_id,
      project_name: options.project_name,
      project_region: options.project_region
    )
    deployment.perform(dry_run: options.dry_run)
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
    Envirobly::Duration.measure("Build context download took %s") do
      s3 = Envirobly::Aws::S3.new(region:, bucket:)
      s3.pull ref, path
    end
  end

  desc "object_tree", "Show object tree used for deployments"
  method_option :commit, type: :string, default: "HEAD"
  def object_tree
    commit = Envirobly::Git::Commit.new options.commit
    puts "Commit: #{commit.ref}"
    pp commit.object_tree
    puts "SHA256: #{commit.object_tree_checksum}"
  end

  desc "measure", "POC of Envirobly::Duration"
  def measure
    Envirobly::Duration.measure do
      print "Doing something for 2s"
      sleep 2
    end

    Envirobly::Duration.measure do
      print "Doing something else for 100ms"
      sleep 0.1
    end

    Envirobly::Duration.measure("Custom message, took %s") do
      puts "Sleeping 2.5s with custom message"
      sleep 2.5
    end

    puts "Done."
  end
end
