require "yaml"

class Envirobly::Config
  PATH = ".envirobly/project.yml"

  attr_reader :parsing_error

  def initialize(commit)
    @commit = commit
    @parsing_error = nil
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

  def parsing_error?
    !@parsing_error.nil?
  end

  def path
    PATH
  end

  private
    def parse_config_content_at_commit
      YAML.load config_content_at_commit
    rescue Psych::Exception => exception
      @parsing_error = exception.message
      nil
    end

    def config_content_at_commit
      `git show #{@commit.ref}:#{path}`
    end
end
