require "yaml"

class Envirobly::Deployment
  include Envirobly::Colorize

  def initialize(environ_name:, commit_ref:, account_id:, project_name:, project_region:)
    @environ_name = environ_name
    @commit = Envirobly::Git::Commit.new commit_ref

    unless @commit.exists?
      $stderr.puts "Commit #{commit_ref} doesn't exist in this repository. Aborting."
      exit 1
    end

    configs = Envirobly::Configs.new

    if account_id.nil?
      account_id = configs.default_account_id
    end

    project_id = nil
    if project_name.nil?
      project_id = configs.default_project_id
    end

    @params = {
      deployment: {
        account: {
          id: account_id
        },
        project: {
          id: project_id,
          name: project_name,
          region: project_region
        },
        environ: {
          name: environ_name
        },
        commit: {
          ref: @commit.ref,
          time: @commit.time,
          message: @commit.message,
          object_tree_checksum: @commit.object_tree_checksum
        },
        **configs.to_params
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
      print "Preparing project..."
      response = api.create_deployment @params

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
      s3 = Envirobly::Aws::S3.new(bucket:, region:, credentials:)
      s3.push @commit

      # Perform deployment
      api.put_as_json @deployment_url
    end

    puts "Follow at #{watch_deployment_url}"
  end
end
