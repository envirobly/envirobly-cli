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
      env_vars:
    }
  end

  private
    def env_vars
      Dotenv.parse @dir.join(ENV)
    end
end
