# frozen_string_literal: true

class Envirobly::Cli::Main < Envirobly::Base
  include Envirobly::Colorize

  desc "version", "Show Envirobly CLI version"
  method_option :pure, type: :boolean, default: false
  def version
    if options.pure
      say Envirobly::VERSION
    else
      say "envirobly CLI v#{Envirobly::VERSION}"
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
    say "You've signed out"
    say "You can sign in again with `envirobly signin`"
  end

  desc "target [NAME]", "Configure deployment (default) target"
  method_option :missing_only, type: :boolean, default: false
  def target(name = nil)
    Envirobly::AccessToken.new(shell:).require!

    target = Envirobly::Target.new(default_project_name: File.basename(Dir.pwd), shell:)
    target.name = name if name.present?

    errors = target.errors :name

    if errors.any?
      errors.each do |message|
        shell.say_error message
      end

      exit 1
    end

    target.configure!(missing_only: options.missing_only)

    shell.say "#{green_check} "
    shell.say "Target configured.", :green
  end

  desc "validate", "Validates config (for given environ)"
  def validate(environ_name = nil)
    Envirobly::AccessToken.new(shell:).require!

    config = Envirobly::Config.new
    api = Envirobly::Api.new

    params = { validation: { config: config.merge(environ_name).to_yaml } }
    api.validate_shape params

    say "Config is valid #{green_check}"
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

  desc "deploy [[TARGET/[ENVIRON_NAME]]", <<~TXT
    Deploy to environ identified by name.
    Name can contain letters, numbers, dashes or underscores.
    If environ name is left blank, current git branch name is used.
  TXT
  method_option :account_url, type: :string
  method_option :region, type: :string
  method_option :project_name, type: :string
  method_option :commit, type: :string, default: "HEAD"
  method_option :dry_run, type: :boolean, default: false
  def deploy(path = nil)
    commit = Envirobly::Git::Commit.new options.commit

    unless commit.exists?
      say_error "Commit '#{commit.ref}' doesn't exist in this repository"
      exit 1
    end

    if commit.uncommited_changes?
      say "You have uncommited changes in this repository:"
      say
      commit.uncommited_changes.each do |path|
        say "  #{path}"
      end
      say
      say "These won't be deployed. ", :red
      say "Instead contents of commit #{commit.short_ref} will be."
      say
      unless ask("Continue deploying? [y/N]")[0]&.downcase == "y"
        say "Cancelled"
        exit
      end
    end

    Envirobly::AccessToken.new(shell:).require!

    target = Envirobly::Target.new(
      path,
      account_url: options.account_url,
      project_name: options.project_name,
      region: options.region,
      default_project_name: File.basename(Dir.pwd),
      default_environ_name: commit.current_branch,
      shell:
    )
    target.render_and_exit_on_errors!
    target.configure!(missing_only: true)

    deployment = Envirobly::Deployment.new(target:, commit:, shell:)
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
    Envirobly::ContainerShell.new(service_name, options, shell:).exec(command)
  end

  desc "rsync [SERVICE_NAME:]SOURCE_PATH [SERVICE_NAME:]DESTINATION_PATH", <<~TXT
    Synchronize files between you and your service's data volume.
  TXT
  method_option :account_id, type: :numeric
  method_option :project_id, type: :numeric
  method_option :project_name, type: :string
  method_option :environ_name, type: :string
  method_option :args, type: :string, default: "-avzP"
  def rsync(source, destination)
    service_name = nil

    [ source, destination ].each do |path|
      if path =~ /\A([a-z0-9\-_]+):/i
        service_name = $1
        break
      end
    end

    Envirobly::ContainerShell.new(service_name, options, shell:).rsync(source, destination)
  end
end
