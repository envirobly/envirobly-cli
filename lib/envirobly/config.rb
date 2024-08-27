require "yaml"

class Envirobly::Config
  PATH = ".envirobly/project.yml"

  attr_reader :parsing_error

  def initialize(commit)
    @commit = commit
    @parsing_error = nil
    @project = parse_config_content_at_commit

    transform_env_var_values! if @project
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
      YAML.load config_content_at_commit, aliases: true
    rescue Psych::Exception => exception
      @parsing_error = exception.message
      nil
    end

    def config_content_at_commit
      `git show #{@commit.ref}:#{path}`
    end

    def transform_env_var_values!
      @project.fetch("services", {}).each do |logical_id, service|
        service.fetch("env", {}).each do |key, value|
          if value.is_a?(Hash) && value.has_key?("file")
            @project["services"][logical_id]["env"][key] = File.read value.fetch("file")
          end
        end
      end
    end
end
