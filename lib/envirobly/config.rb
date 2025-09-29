# frozen_string_literal: true

require "dotenv"

class Envirobly::Config
  DIR = ".envirobly"
  BASE = "deploy.yml"
  ENV_VARS = "env"
  OVERRIDES_PATTERN = /deploy\.([a-z0-9\-_]+)\.yml/i

  def initialize(dir = DIR)
    @dir = Pathname.new dir
  end

  def to_params
    {
      configs:,
      env_vars:
    }
  end

  private
    def configs
      Dir.entries(@dir).map do |file|
        path = File.join(@dir, file)

        next unless File.file?(path) && config_file?(file)

        [ "#{DIR}/#{file}", File.read(path) ]
      end.compact.to_h
    end

    def env_vars
      Dotenv.parse @dir.join(ENV_VARS)
    end

    def config_file?(file)
      file == BASE || file.match?(OVERRIDES_PATTERN)
    end
end
