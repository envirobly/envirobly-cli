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

  desc "signin", "Set access token generated at Envirobly"
  def signin
    access_token = Envirobly::AccessToken.new(shell:)
    access_token.set
  end

  desc "signout", "Sign out"
  def signout
    Envirobly::AccessToken.destroy
    say "You've signed out."
    say "This didn't delete the access token itself."
    say "You can sign in again with `envirobly signin`."
  end

  desc "set_default_account", "Choose default account to deploy the current project to"
  def set_default_account
    Envirobly::Defaults::Account.new(shell:).require_id
  end

  desc "set_default_region", "Set default region for the current project when deploying for the first time"
  def set_default_region
    Envirobly::Defaults::Region.new(shell:).require_id
  end

  desc "validate", "Validates config"
  def validate
    Envirobly::AccessToken.new(shell:).require!

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

  desc "instance_types [REGION]", "List instance types in the given region, including price and performance characteristics."
  def instance_types(region = nil)
    default_region = Envirobly::Defaults::Region.new(shell:)
    region = region.presence || default_region.require_if_none

    api = Envirobly::Api.new
    table_data = api.list_instance_types(region).object.map do |item|
      [
        item["code"],
        item["vcpu"],
        Envirobly::Numeric.new(item["memory"], short: true),
        Envirobly::Numeric.new(item["monthly_price"]),
        item["group"]
      ]
    end

    print_table [ [ "Name", "vCPU", "Memory (GB)", "Monthly price ($)", "Group" ] ] +
      table_data, borders: true
  end

  desc "deploy [ENVIRON_NAME]", <<~TXT
    Deploy to environ identified by name.
    Name can contain letters, numbers, dashes or underscores.
    If environ name is left blank, current git branch name is used.
  TXT
  method_option :account_id, type: :numeric
  method_option :region, type: :string
  method_option :project_id, type: :numeric
  method_option :project_name, type: :string
  method_option :commit, type: :string, default: "HEAD"
  method_option :dry_run, type: :boolean, default: false
  def deploy(environ_name = nil)
    commit = Envirobly::Git::Commit.new options.commit

    unless commit.exists?
      say_error "Commit '#{commit.ref}' doesn't exist in this repository"
      exit 1
    end

    Envirobly::AccessToken.new(shell:).require!

    deployment = Envirobly::Deployment.new(
      account_id: options.account_id,
      region: options.region,
      project_id: options.project_id,
      project_name: options.project_name,
      environ_name: environ_name.presence || commit.current_branch,
      commit:,
      shell:
    )
    deployment.perform(dry_run: options.dry_run)
  end

  desc "pull REGION BUCKET REF PATH", "Download build context. Used by Envirobly builders."
  def pull(region, bucket, ref, path)
    Envirobly::Duration.measure("Build context download took %s") do
      s3 = Envirobly::Aws::S3.new(region:, bucket:)
      s3.pull ref, path
    end
  end

  desc "exec SERVICE_NAME [COMMAND] [ARG...]", "Start interactive service shell or execute a command"
  method_option :account_id, type: :numeric
  method_option :project_id, type: :numeric
  method_option :project_name, type: :string
  method_option :environ_name, type: :string
  method_option :instance_slot, type: :numeric
  method_option :shell, type: :string
  method_option :user, type: :string
  def exec(service_name, *command)
    say "exec #{service_name} #{command.join(" ")}"
  end
end
