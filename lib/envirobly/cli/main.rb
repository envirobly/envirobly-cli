require "time"
require "json"

class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "deploy ENVIRONMENT_NAME", "Deploy current commit to an environment"
  method_option :commit, type: :string, default: "HEAD"
  def deploy(environ_name)
    # $stderr.puts "deploy to #{environ_name}"
    deployment = {
      environ_name:,
      commit_ref:,
      commit_time:,
      commit_message:
    }
    puts deployment.to_json
  end

  private
    def commit_ref
      `git rev-parse #{options.commit}`.chomp("")
    end

    def commit_message
      `git log #{options.commit} -n1 --pretty=%B`.chomp("")
    end

    def commit_time
      Time.parse `git log #{options.commit} -n1 --date=iso --pretty=format:"%ad"`
    end
end
