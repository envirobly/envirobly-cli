require "yaml"

class Envirobly::Deployment
  include Envirobly::Colorize

  def initialize(environ_name:, commit:, account_id:, project_name:, project_id:, region:, shell:)
    @environ_name = environ_name
    @commit = commit
    @config = Envirobly::Config.new
    @default_account = Envirobly::Defaults::Account.new(shell:)
    @default_project = Envirobly::Defaults::Project.new(shell:)
    @default_region = Envirobly::Defaults::Region.new(shell:)

    if account_id.blank?
      account_id = @default_account.require_if_none
    end

    if project_id.blank? && project_name.blank?
      project_id = @default_project.id

      if project_id.nil?
        project_name = File.basename(Dir.pwd)
      end
    end

    if region.blank?
      region = @default_region.require_if_none
    end

    @params = {
      account: {
        id: account_id
      },
      project: {
        id: project_id,
        name: project_name,
        region:
      },
      deployment: {
        environ_name:,
        commit_ref: @commit.ref,
        commit_time: @commit.time,
        commit_message: @commit.message,
        object_tree_checksum: @commit.object_tree_checksum,
        **@config.to_params
      }
    }
  end

  def perform(dry_run:)
    puts [ "Deploying commit", yellow(@commit.short_ref), faint("→"), green(@environ_name) ].join(" ")
    puts
    puts "    #{@commit.message}"
    puts

    if dry_run
      puts YAML.dump(@params)
      return
    end

    # Create deployment
    api = Envirobly::Api.new

    Envirobly::Duration.measure do
      response = api.create_deployment @params

      unless response.success?
        display_config_errors response.object.fetch("errors")
        exit 1
      end

      print "Preparing project..."

      @default_account.save_if_none response.object.fetch("account_url")
      @default_project.save_if_none response.object.fetch("project_url")
      @default_region.save_if_none response.object.fetch("region")

      # Fetch credentials for build context upload
      @deployment_url = response.object.fetch("url")
      @credentials_response = api.get_deployment_with_delay_and_retry @deployment_url
    end

    credentials = @credentials_response.object.fetch("credentials")
    region = @credentials_response.object.fetch("region")
    bucket = @credentials_response.object.fetch("bucket")
    watch_deployment_url = @credentials_response.object.fetch("deployment_url")

    Envirobly::Duration.measure do
      # Upload build context
      Envirobly::Aws::S3.new(bucket:, region:, credentials:).push @commit

      # Perform deployment
      api.put_as_json @deployment_url
    end

    puts "Follow at #{watch_deployment_url}"
  end
end
