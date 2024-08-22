require "yaml"
require "json"

class Envirobly::Cli::Remote < Envirobly::Base
  URL_MATCHER = /^https:\/\/envirobly\.test\/(\d+)\/projects\/(\d+)$/
  CONFIG_PATH = ".envirobly/project.yml"
  DEFAULT_CONFIG = <<~YAML
    remote:
      origin: %origin_url%
  YAML

  desc "add NAME URL", "Add a remote (connect a project by URL)"
  def add(name, url)
    unless url =~ URL_MATCHER
      $stderr.puts "URL must match https://envirobly.com/[number]/projects/[number]"
      exit 1
    end

    # $stderr.puts "add remote #{name} #{url}"

    puts config.to_json
  end

  desc "show", "Show connected projects"
  def show
    puts "TODO list remotes"
  end

  private
    def config
      YAML.load_file CONFIG_PATH
    rescue Errno::ENOENT
      DEFAULT_CONFIG
    end
end
