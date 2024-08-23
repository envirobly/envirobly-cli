# require "debug"

class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "deploy ENVIRONMENT", "Deploy to environment identified by name or URL"
  method_option :commit, type: :string, default: "HEAD"
  def deploy(environment)
    Envirobly::Deployment.new environment, options
  end
end
