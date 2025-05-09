require "dotenv"

class Envirobly::Config
  DIR = ".envirobly"
  ENV = "env"
  BASE = "deploy.yml"
  OVERRIDES_PATTERN = /deploy\.([a-z0-9\-_]+)\.yml/i
  DEFAULTS_DIR = File.join DIR, "defaults"
  DEFAULT_ACCOUNT_PATH = File.join(DEFAULTS_DIR, "account.yml")
  DEFAULT_PROJECT_PATH = File.join(DEFAULTS_DIR, "project.yml")

  def initialize(dir = DIR)
    @dir = Pathname.new dir
  end

  def to_params
    {
      configs:,
      env_vars:
    }
  end

  def default_project_id
    if File.exist?(DEFAULT_PROJECT_PATH)
      content = YAML.safe_load_file(DEFAULT_PROJECT_PATH)
      if content["url"] =~ /projects\/(\d+)/
        return $1.to_i
      end
    end

    nil
  end

  def default_account_id
    if File.exist?(DEFAULT_ACCOUNT_PATH)
      content = YAML.safe_load_file(DEFAULT_ACCOUNT_PATH)
      if content["url"] =~ /accounts\/(\d+)/
        return $1.to_i
      end
    end

    nil
  end

  def save_default_account(url, force: false)
    return if !force && File.exist?(DEFAULT_ACCOUNT_PATH)

    FileUtils.mkdir_p(DEFAULTS_DIR)
    content = YAML.dump({ "url" => url })
    File.write(DEFAULT_ACCOUNT_PATH, content)
  end

  def save_default_project(url, force: false)
    return if !force && File.exist?(DEFAULT_PROJECT_PATH)

    FileUtils.mkdir_p(DEFAULTS_DIR)
    content = YAML.dump({ "url" => url })
    File.write(DEFAULT_PROJECT_PATH, content)
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
      Dotenv.parse @dir.join(ENV)
    end

    def config_file?(file)
      file == BASE || file.match?(OVERRIDES_PATTERN)
    end
end
