require "yaml"

class Envirobly::Deployment
  include Envirobly::Colorize

  def initialize(environ_name, options)
    commit = Envirobly::Git::Commit.new options.commit

    unless commit.exists?
      $stderr.puts "Commit #{options.commit} doesn't exist in this repository. Aborting."
      exit 1
    end

    configs = Envirobly::Configs.new

    params = {
      deployment: {
        account: {
          id: options.account_id
        },
        project: {
          id: options.project_id,
          name: options.project_name,
          region: options.project_region
        },
        environ: {
          name: environ_name
        },
        commit: {
          ref: commit.ref,
          time: commit.time,
          message: commit.message,
          object_tree_checksum: commit.object_tree_checksum
        },
        **configs.to_params
      }
    }

    puts [ "Deploying commit", yellow(commit.short_ref), faint("→"), green(environ_name) ].join(" ")
    puts
    puts "    #{commit.message}"
    puts

    if options.dry_run?
      puts
      puts YAML.dump(params)
      return
    end

    # Create deployment
    api = Envirobly::Api.new

    Envirobly::Duration.measure do
      print "Preparing project"
      response = api.create_deployment params

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
      s3.push commit

      # Perform deployment
      api.put_as_json @deployment_url
    end

    puts "Follow at #{watch_deployment_url}"
  end
end
