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
    configs = Envirobly::Config.new
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
    Deploy to environ identified by name.
    Name can contain letters, numbers, dashes or underscores.
    If environ name is left blank, current git branch name is used.
  TXT
  method_option :account_id, type: :numeric
  method_option :region, type: :string
  method_option :project, type: :string
  method_option :commit, type: :string, default: "HEAD"
  method_option :dry_run, type: :boolean, default: false
  def deploy(environ_name = nil)
    commit = Envirobly::Git::Commit.new options.commit

    unless commit.exists?
      say_error "Commit '#{commit.ref}' doesn't exist in this repository. Aborting."
      exit 1
    end

    environ_name = environ_name.presence || commit.current_branch
    project_name = nil
    project_id = nil

    if options.project.present?
      if options.project =~ Envirobly::Defaults::Project.regexp
        project_id = $1.to_i
      else
        project_name = options.project
      end
    end

    deployment = Envirobly::Deployment.new(
      account_id: options.account_id,
      region: options.region,
      project_name:,
      environ_name:,
      project_id:,
      commit:,
      shell:
    )
    deployment.perform(dry_run: options.dry_run)
  end

  desc "set_access_token", "Set access token generated at Envirobly"
  def set_access_token
    token = ask("Access Token:", echo: false).strip

    if token.blank?
      $stderr.puts
      $stderr.puts "Token can't be empty."
      exit 1
    end

    Envirobly::AccessToken.new(token).save
  end

  desc "pull", "Download build context"
  def pull(region, bucket, ref, path)
    Envirobly::Duration.measure("Build context download took %s") do
      s3 = Envirobly::Aws::S3.new(region:, bucket:)
      s3.pull ref, path
    end
  end

  desc "set_default_account", "Choose default account to deploy to"
  def set_default_account
    Envirobly::Defaults::Account.new(shell:).require_id
  end
end
