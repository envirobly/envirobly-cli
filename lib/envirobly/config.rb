require "yaml"

class Envirobly::Config
  PATH = ".envirobly/project.yml"

  def initialize(commit)
    @commit = commit
    @project = parse_config_content_at_commit
  end

  def dig(*args)
    @project.dig *args
  rescue NoMethodError
    nil
  end

  def to_h
    @project
  end

  private
    def parse_config_content_at_commit
      YAML.load config_content_at_commit
    rescue Errno::ENOENT
      {}
    end

    def config_content_at_commit
      `git show #{@commit.ref}:#{PATH}`
    end
end
