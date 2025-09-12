# frozen_string_literal: true

require "yaml"

module Envirobly
  class Deployment
    include Colorize

    attr_reader :params

    def initialize(environ_name:, commit:, account_id:, project_name:, project_id:, region:, shell:)
      @environ_name = environ_name
      @commit = commit
      @config = Config.new
      @default_account = Defaults::Account.new(shell:)
      @default_project = Defaults::Project.new(shell:)
      @default_region = Defaults::Region.new(shell:)

      target = Target.new(
        default_account_id: @default_account.value,
        default_project_id: @default_project.value,
        default_region: @default_region.value,
        default_project_name: Defaults::Project.dirname,
        default_environ_name: commit.current_branch,
        account_id:,
        project_id:,
        region:,
        project_name:,
        environ_name:
      )

      if target.missing_params.include?(:account_id)
        target.account_id = @default_account.require_value
      end

      if target.missing_params.include?(:region)
        target.region = @default_region.require_value
      end

      @params = {
        account_id: target.account_id,
        project_id: target.project_id,
        project_name: target.project_name,
        region: target.region,
        deployment: {
          environ_name: target.environ_name,
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
      api = Api.new

      Duration.measure do
        response = api.create_deployment @params

        unless response.success?
          display_config_errors response.object.fetch("errors")
          exit 1
        end

        print "Preparing project..."

        @default_account.save_if_none response.object.fetch("account_id")
        @default_project.save_if_none response.object.fetch("project_id")
        @default_region.save_if_none response.object.fetch("region")

        # Fetch credentials for build context upload
        @deployment_url = response.object.fetch("url")
        @credentials_response = api.get_deployment_with_delay_and_retry @deployment_url
      end

      credentials = @credentials_response.object.fetch("credentials")
      region = @credentials_response.object.fetch("region")
      bucket = @credentials_response.object.fetch("bucket")
      watch_deployment_url = @credentials_response.object.fetch("deployment_url")

      Duration.measure do
        # Upload build context
        Aws::S3.new(bucket:, region:, credentials:).push @commit

        # Perform deployment
        api.put_as_json @deployment_url
      end

      puts "Follow at #{watch_deployment_url}"
    end
  end
end
