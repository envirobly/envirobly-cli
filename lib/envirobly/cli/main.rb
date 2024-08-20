require "time"
require "json"

class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "deploy ENVIRONMENT_NAME", "Deploy current commit to an environment"
  def deploy(environ_name)
    $stderr.puts "deploy to #{environ_name}"
    commit_ref = `git rev-parse HEAD`.chomp("")
    commit_message = `git log -1 --pretty=%B`.chomp("")
    commit_time = Time.parse `git log -1 --date=iso --pretty=format:"%ad"`
    commit = {
      ref: commit_ref,
      message: commit_message,
      time: commit_time
    }
    puts commit.to_json
  end
end
