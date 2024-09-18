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
    @raw = @commit.config_content

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

  def compile
    @project.slice(:services)
  end

  def parsing_error?
    !@parsing_error.nil?
  end

  private
    def parse
      YAML.safe_load @raw, aliases: true, symbolize_names: true
    rescue Psych::Exception => exception
      @parsing_error = exception.message
      nil
    end

    def transform_env_var_values!
      @project.fetch(:services, {}).each do |logical_id, service|
        service.fetch(:env, {}).each do |key, value|
          if value.is_a?(Hash) && value.has_key?(:file)
            @project[:services][logical_id][:env][key] = @commit.file_content(value.fetch(:file)).strip
          end
        end
      end
    end

    NON_BUILDABLE_TYPES = %w[ postgres mysql valkey ]
    def append_image_tags!
      @project.fetch(:services, {}).each do |logical_id, service|
        next if NON_BUILDABLE_TYPES.include?(service[:type]) || service[:image]

        dockerfile = service.fetch(:dockerfile, "Dockerfile")
        build_context = service.fetch(:build_context, ".")

        @project[:services][logical_id][:image_tag] = Digest::SHA1.hexdigest [
          @commit.objects_with_checksum_at(dockerfile),
          @commit.objects_with_checksum_at(build_context)
        ].to_json
      end
    end
end
