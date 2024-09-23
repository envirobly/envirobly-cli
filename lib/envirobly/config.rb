require "yaml"
require "json"
require "digest"

class Envirobly::Config
  DIR = ".envirobly"
  PATH = "#{DIR}/project.yml"

  attr_reader :errors, :result, :raw

  def initialize(commit)
    @commit = commit
    @errors = []
    @result = nil
    @project_url = nil
    @raw = @commit.file_content PATH
    @project = parse
  end

  def dig(*args)
    @project.dig(*args)
  rescue NoMethodError
    nil
  end

  def validate
    return unless @project
    validate_top_level_keys
    validate_services @project.fetch(:services)
    validate_environments
  end

  def compile(environment = nil)
    @environment = environment
    return unless @project
    set_project_url
    merge_environment_overrides! unless @environment.nil?
    transform_env_var_values!
    append_image_tags!
    @result = @project.slice(:services)
    nil
  end

  def to_deployment_params
    {
      environ: {
        name: @environment,
        project_url: @project_url
      },
      commit: {
        ref: @commit.ref,
        time: @commit.time,
        message: @commit.message
      },
      config: @result,
      raw_config: @raw
    }
  end

  private
    def parse
      YAML.safe_load @raw, aliases: true, symbolize_names: true
    rescue Psych::Exception => exception
      @errors << exception.message
      nil
    end

    def set_project_url
      @project_url = dig :project
      @errors << "Missing `project: <url>` top level attribute." if @project_url.blank?
    end

    def transform_env_var_values!
      @project.fetch(:services, {}).each do |name, service|
        service.fetch(:env, {}).each do |key, value|
          if value.is_a?(Hash) && value.has_key?(:file)
            @project[:services][name][:env][key] = @commit.file_content(value.fetch(:file)).strip
          end
        end
      end
    end

    NON_BUILDABLE_TYPES = %w[ postgres mysql valkey ]
    BUILD_DEFAULTS = {
      dockerfile: [ "Dockerfile", :file_exists? ],
      build_context: [ ".", :dir_exists? ]
    }
    def append_image_tags!
      @project.fetch(:services, {}).each do |name, service|
        next if NON_BUILDABLE_TYPES.include?(service[:type]) || service[:image].present?
        checksums = []

        BUILD_DEFAULTS.each do |attribute, options|
          value = service.fetch(attribute, options.first)
          unless @commit.public_send(options.second, value)
            @errors << "Service `#{name}` specifies `#{attribute}` as `#{value}` which doesn't exist in this commit."
          else
            checksums << @commit.objects_with_checksum_at(value)
          end
        end

        if checksums.size == 2
          @project[:services][name][:image_tag] = Digest::SHA1.hexdigest checksums.to_json
        end
      end
    end

    def merge_environment_overrides!
      return unless services = @project.dig(:environments, @environment.to_sym)
      services.each do |name, service|
        service.each do |attribute, value|
          if value.is_a?(Hash) && @project[:services][name][attribute].is_a?(Hash)
            @project[:services][name][attribute].merge! value
            @project[:services][name][attribute].compact!
          else
            @project[:services][name][attribute] = value
          end
        end
      end
    end

    VALID_TOP_LEVEL_KEYS = %i[ project services environments ]
    def validate_top_level_keys
      unless @project.is_a?(Hash)
        @errors << "Config doesn't contain a top level hash structure."
        return
      end

      @project.keys.each do |key|
        unless VALID_TOP_LEVEL_KEYS.include?(key)
          @errors << "Top level key `#{key}` is not allowed. Allowed keys: #{VALID_TOP_LEVEL_KEYS.map{ "`#{_1}`" }.join(", ")}."
        end
      end
    end

    VALID_SERVICE_KEYS = %i[
      type
      image
      engine_version
      instance_type
      volume_size
      volume_mount
      dockerfile
      build_context
      command
      env
      health_check
      private
      aliases
    ]
    NAME_FORMAT = /\A[a-z0-9\-_]+\z/
    def validate_services(services)
      unless services.is_a?(Hash)
        @errors << "`services` key must be a hash."
        return
      end

      services.each do |name, attrs|
        unless name =~ NAME_FORMAT
          @errors << "`#{name}` is not a valid service name. Allowed characters: a-z, 0-9, -, _"
        end

        unless attrs.is_a?(Hash)
          @errors << "Service `#{name}` must be a hash."
          next
        end

        attrs.each do |key, value|
          unless VALID_SERVICE_KEYS.include?(key)
            @errors << "Service `#{name}` attribute `#{key}` is not a valid attribute."
          end
        end
      end
    end

    def validate_environments
      environments = @project.fetch :environments

      unless environments.is_a?(Hash)
        @errors << "`environments` key must be a hash."
        return
      end

      environments.each do |environment, services|
        unless environment =~ NAME_FORMAT
          @errors << "`#{environment}` is not a valid environment name. Allowed characters: a-z, 0-9, -, _"
        end

        validate_services services
      end
    end
end
