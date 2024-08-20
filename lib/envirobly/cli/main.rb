require "time"
require "json"
# require "debug"

class Envirobly::Cli::Main < Envirobly::Base
  desc "version", "Show Envirobly CLI version"
  def version
    puts Envirobly::VERSION
  end

  desc "deploy ENVIRONMENT_NAME", "Deploy current commit to an environment"
  method_option :commit, type: :string, default: "HEAD"
  def deploy(environ_name)
    unless commit_exists?
      $stderr.puts "Commit #{options.commit} doesn't exist in this repository. Aborting."
      exit 1
    end

    # $stderr.puts "deploy to #{environ_name}"
    deployment = {
      environ_name:,
      commit_ref:,
      commit_time:,
      commit_message:
    }
    puts deployment.to_json

    if archive_build_context
      $stderr.puts "Build context exported into #{archive_path}"
    else
      $stderr.puts "Error exporting build context. Aborting."
      exit 1
    end
  end

  private
    def commit_exists?
      `git cat-file -t #{options.commit}`.chomp("") == "commit"
    end

    def commit_ref
      @commit_ref ||= `git rev-parse #{options.commit}`.chomp("")
    end

    def commit_message
      `git log #{options.commit} -n1 --pretty=%B`.chomp("")
    end

    def commit_time
      Time.parse `git log #{options.commit} -n1 --date=iso --pretty=format:"%ad"`
    end

    def archive_path
      "/tmp/#{commit_ref}.tar.gz"
    end

    def archive_build_context
      `git archive --format=tar.gz --output=#{archive_path} #{commit_ref}`
      $?.success?
    end
end
