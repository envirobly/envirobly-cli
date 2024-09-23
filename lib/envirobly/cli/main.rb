class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "validate", "Validates config"
  def validate
    commit = Envirobly::Git::Unstaged.new
    config = Envirobly::Config.new(commit)
    config.validate

    if config.errors.any?
      $stderr.puts "Errors found while validating #{Envirobly::Config::PATH}:"
      $stderr.puts
      config.errors.each do |error|
        $stderr.puts "  - #{error}"
      end
      exit 1
    else
      puts "Great, #{Envirobly::Config::PATH} passes all checks."
    end
  end

  desc "deploy ENVIRONMENT", "Deploy to environment identified by name or URL"
  method_option :commit, type: :string, default: "HEAD"
  method_option :dry_run, type: :boolean, default: false
  def deploy(environment)
    abort_if_aws_cli_is_missing
    Envirobly::Deployment.new environment, options
  end

  desc "set_access_token TOKEN", "Save and use an access token generated at Envirobly"
  def set_access_token
    token = ask("Access Token:", echo: false).strip
    if token == ""
      $stderr.puts "Token can't be empty."
      exit 1
    end

    Envirobly::AccessToken.new(token).save
  end

  private
    def abort_if_aws_cli_is_missing
      `which aws`
      unless $?.success?
        $stderr.puts "AWS CLI is missing. Please install it first: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
      end
    end
end
