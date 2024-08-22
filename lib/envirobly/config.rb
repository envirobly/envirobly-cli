require "yaml"

class Envirobly::Config
  CONFIG_PATH = ".envirobly/project.yml"

  def initialize
    @config = load_config
  end

  def dig(*args)
    @config.dig *args
  rescue NoMethodError
    nil
  end

  private
    def load_config
      YAML.load_file CONFIG_PATH
    rescue Errno::ENOENT
      {}
    end
end
