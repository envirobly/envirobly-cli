# frozen_string_literal: true

module Envirobly
  class Deployment
    include Colorize

    attr_reader :params, :shell

    def initialize(target:, commit:, shell:)
      @target = target
      @commit = commit
      @shell = shell
      @api = Api.new
      @config = Config.new
    end

    def perform(dry_run:)
      params = {
        account_id: @target.account_id,
        project_name: @target.project_name,
        region: @target.region,
        deployment: {
          environ_name: @target.environ_name,
          commit_ref: @commit.ref,
          commit_time: @commit.time,
          commit_message: @commit.message,
          object_tree_checksum: @commit.object_tree_checksum,
          config: @config.merge(@target.environ_name).to_yaml
        }
      }

      if dry_run
        shell.say "This is a dry run, nothing will be deployed.", :green
      end

      # TODO: Replace with shell
      puts [ "Deploying commit", yellow(@commit.short_ref), faint("→"), green(@target.environ_name) ].join(" ")
      puts
      # TODO: Multiline indent
      puts "    #{@commit.message}"
      puts

      if dry_run
        puts green("Config:")
        puts params[:deployment][:config]

        shell.say
        shell.say "Target:", :green

        targets_and_values = [
          [ "Account", @target.account_url ],
          [ "Region", params[:region] ],
          [ "Project", params[:project_name] ],
          [ "Environ", params[:deployment][:environ_name] ]
        ]

        shell.print_table targets_and_values, borders: true

        return
      end

      Duration.measure do
        # Create deployment
        response = @api.create_deployment params

        print "Preparing project..."

        # Fetch credentials for build context upload
        @deployment_url = response.object.fetch("url")
        @credentials_response = @api.get_deployment_with_delay_and_retry @deployment_url
      end

      credentials = @credentials_response.object.fetch("credentials")
      region = @credentials_response.object.fetch("region")
      bucket = @credentials_response.object.fetch("bucket")

      Duration.measure do
        # Upload build context
        Aws::S3.new(bucket:, region:, credentials:).push @commit

        # Perform deployment
        @api.put_as_json @deployment_url
      end

      watch_deployment_url = @credentials_response.object.fetch("deployment_url")
      puts "Follow at #{watch_deployment_url}"
    end
  end
end
