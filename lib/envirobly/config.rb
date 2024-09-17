require "yaml"
require "json"
require "digest"

class Envirobly::Config
  DIR = ".envirobly"
  PATH = "#{DIR}/project.yml"

  attr_reader :parsing_error, :raw

  def initialize(commit)
    @commit = commit
    @parsing_error = nil
    @raw = config_content_at_commit

    if @project = parse
      transform_env_var_values!
      append_image_tags!
    end
  end

  def dig(*args)
    @project.dig(*args)
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
    def parse
      YAML.load @raw, aliases: true
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

    NON_BUILDABLE_TYPES = %w[ postgres mysql valkey ]
    def append_image_tags!
      @project.fetch("services", {}).each do |logical_id, service|
        next if NON_BUILDABLE_TYPES.include?(service["type"]) || service["image_uri"]

        dockerfile = service.fetch("dockerfile", "Dockerfile")
        build_context = service.fetch("build_context", ".")

        @project["services"][logical_id]["image_tag"] = Digest::SHA1.hexdigest [
          git_path_checksums_at_commit(dockerfile),
          git_path_checksums_at_commit(build_context)
        ].to_json
      end
    end

    def git_path_checksums_at_commit(path)
      `git ls-tree #{@commit.ref} --format='%(objectname) %(path)' #{path}`.
        lines.reject { _1.split(" ").last == DIR }
    end
end
