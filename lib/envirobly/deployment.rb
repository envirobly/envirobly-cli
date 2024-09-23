class Envirobly::Deployment
  def initialize(environment, options)
    commit = Envirobly::Git::Commit.new options.commit

    unless commit.exists?
      $stderr.puts "Commit #{options.commit} doesn't exist in this repository. Aborting."
      exit 1
    end

    config = Envirobly::Config.new(commit)
    config.validate

    if config.errors.any?
      $stderr.puts "Errors found while parsing #{Envirobly::Config::PATH}:"
      $stderr.puts
      config.errors.each do |error|
        $stderr.puts "  - #{error}"
      end
      $stderr.puts
      $stderr.puts "Please fix these, commit the changes and try again."
      exit 1
    end

    config.compile(environment)
    params = config.to_deployment_params

    puts "Deployment config:"
    puts params.to_yaml

    exit if options.dry_run?

    api = Envirobly::Api.new
    response = api.create_deployment params
    deployment_url = response.object.fetch("url")
    response = api.get_deployment_with_delay_and_retry deployment_url
    credentials = Envirobly::Aws::Credentials.new response.object.fetch("credentials")
    bucket = response.object.fetch("bucket")

    puts "Uploading build context, please wait..."
    unless commit.archive_and_upload(bucket:, credentials:).success?
      $stderr.puts "Error exporting build context. Aborting."
      exit 1
    end

    puts "Build context uploaded."
    api.put_as_json deployment_url

    # TODO: Output URL to watch the deployment progress
  end
end
