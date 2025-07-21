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
      Envirobly::Aws::S3.new(region:, bucket:).pull ref, path
    end
  end

  desc "exec SERVICE_NAME [COMMAND] [ARG...]", <<~TXT
    Start interactive service shell when launched without arguments or execute a one-off command.
    Keep in mind, your container might not have a shell installed. In such cases you won't be able
    to start an interactive session.
  TXT
  method_option :account_id, type: :numeric
  method_option :project_id, type: :numeric
  method_option :project_name, type: :string
  method_option :environ_name, type: :string
  method_option :instance_slot, type: :numeric, default: 0
  method_option :shell, type: :string
  method_option :user, type: :string
  def exec(service_name, *command)
    api = Envirobly::Api.new
    params = {
      project: { account_id: options.account_id, name: options.project_name, id: options.project_id },
      environ: { name: options.environ_name },
      service: { name: service_name },
      instance: { slot: options.instance_slot }
    }
    response = api.create_service_shell_connection params
    ssh_params = response.object

    cmd_template =
      "AWS_ACCESS_KEY_ID='%s' " +
      "AWS_SECRET_ACCESS_KEY='%s' " +
      "AWS_SESSION_TOKEN='%s' " +
      # "ENVIROBLY_SERVICE_SHELL_USER=root " +
      "ssh -i %s " +
      "envirobly-service@%s " +
      # "-o SendEnv=ENVIROBLY_SERVICE_SHELL_USER " +
      "-o StrictHostKeyChecking=accept-new " +
      "-o ProxyCommand='aws ec2-instance-connect open-tunnel --instance-id %s --region %s'"

    Tempfile.create do |tempkey|
      tempkey.write ssh_params.fetch("instance").fetch("private_key")
      tempkey.flush

      cmd = sprintf(
        cmd_template,
        ssh_params.fetch("open_tunnel_credentials").fetch("access_key_id"),
        ssh_params.fetch("open_tunnel_credentials").fetch("secret_access_key"),
        ssh_params.fetch("open_tunnel_credentials").fetch("session_token"),
        tempkey.path,
        ssh_params.fetch("instance").fetch("private_ipv4"),
        ssh_params.fetch("instance").fetch("aws_id"),
        ssh_params.fetch("region")
      )

      if options.shell.present?
        cmd = "ENVIROBLY_SERVICE_INTERACTIVE_SHELL='#{options.shell}' #{cmd} -o SendEnv=ENVIROBLY_SERVICE_INTERACTIVE_SHELL"
      end

      if command.present?
        cmd = %(#{cmd} "#{command.join(" ")}")
      end

      system cmd
    end
  end
end
