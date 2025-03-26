require "dotenv"

class Envirobly::Configs
  DIR = ".envirobly"
  ENV = "env"
  BASE = "deploy.yml"
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

        [ file, File.read(path) ]
      end.compact.to_h
    end

    def env_vars
      Dotenv.parse @dir.join(ENV)
    end

    def config_file?(file)
      file == BASE || file.match?(OVERRIDES_PATTERN)
    end
end
