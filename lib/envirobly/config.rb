require "yaml"

class Envirobly::Config
  PATH = ".envirobly/project.yml"

  def initialize
    @project = load_from_file
  end

  def dig(*args)
    @project.dig *args
  rescue NoMethodError
    nil
  end

  private
    def load_from_file
      YAML.load_file PATH
    rescue Errno::ENOENT
      {}
    end
end
