require "dotenv"

class Envirobly::Configs
  DIR = ".envirobly"
  BASE = "deploy.yml"
  OVERRIDES_PATTERN = /deploy\.([a-z0-9\-_]+)\.yml/i

  def initialize(dir = DIR)

  end

  def env_vars
    @env_vars ||= Dotenv.parse(ENV_PATH)
  end
end
