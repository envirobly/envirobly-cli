require "yaml"
require "json"
require "digest"

class Envirobly::Config
  DIR = ".envirobly"
  PATH = "#{DIR}/project.yml"

  attr_reader :errors, :raw

  def initialize(commit)
    @commit = commit
    @errors = []
    @raw = @commit.file_content PATH
  end

  def dig(*args)
    @project.dig(*args)
  rescue NoMethodError
    nil
  end

  def compile(environment = nil)
    @environment = environment
    return unless @project = parse
    merge_environment_overrides! unless @environment.nil?
    transform_env_var_values!
    append_image_tags!
    @project.slice(:services)
  end

  private
    def parse
      YAML.safe_load @raw, aliases: true, symbolize_names: true
    rescue Psych::Exception => exception
      @errors << exception.message
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
        dockerfile_checksum = @commit.objects_with_checksum_at(dockerfile)
        if dockerfile_checksum.empty?
          @errors << "Service '#{logical_id}' specifies dockerfile '#{dockerfile}' that doesn't exist in the commit"
        end

        build_context = service.fetch(:build_context, ".")
        build_context_checksum = @commit.objects_with_checksum_at(build_context)
        if build_context_checksum.empty?
          @errors << "Service '#{logical_id}' specifies build_context '#{build_context}' that doesn't exist in the commit"
        end

        if dockerfile_checksum.any? && build_context_checksum.any?
          @project[:services][logical_id][:image_tag] = Digest::SHA1.hexdigest [
            dockerfile_checksum,
            build_context_checksum
          ].to_json
        end
      end
    end

    def merge_environment_overrides!
      return unless services = @project.dig(:environments, @environment.to_sym)
      services.each do |logical_id, service|
        service.each do |attribute, value|
          if value.is_a?(Hash) && @project[:services][logical_id][attribute].is_a?(Hash)
            @project[:services][logical_id][attribute].merge! value
            @project[:services][logical_id][attribute].compact!
          else
            @project[:services][logical_id][attribute] = value
          end
        end
      end
    end
end
