require "yaml"

class Envirobly::Deployment
  def initialize(environ_name, options)
    commit = Envirobly::Git::Commit.new options.commit

    unless commit.exists?
      $stderr.puts "Commit #{options.commit} doesn't exist in this repository. Aborting."
      exit 1
    end

    configs = Envirobly::Configs.new

    params = {
      deployment: {
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

    puts "Deploying commit #{commit.short_ref} ⇢ #{environ_name}"
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
    response = api.create_deployment params

    # Fetch credentials for build context upload
    deployment_url = response.object.fetch("url")
    response = api.get_deployment_with_delay_and_retry deployment_url

    credentials = response.object.fetch("credentials")
    region = response.object.fetch("region")
    bucket = response.object.fetch("bucket")
    watch_deployment_url = response.object.fetch("deployment_url")

    # Upload build context
    s3 = Envirobly::Aws::S3.new(bucket:, region:, credentials:)
    s3.push commit

    # Perform deployment
    api.put_as_json deployment_url
    puts "Follow at #{watch_deployment_url}"
  end
end
