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
    @result = {}
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
    return unless @project
    @environment = environment
    @result = @project.slice(:services)
    set_project_url
    merge_environment_overrides! unless @environment.nil?
    transform_env_var_values!
    append_image_tags!
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
    end

    def transform_env_var_values!
      @result[:services].each do |name, service|
        service.fetch(:env, {}).each do |key, value|
          if value.is_a?(Hash) && value.has_key?(:file)
            @result[:services][name][:env][key] = @commit.file_content(value.fetch(:file)).strip
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
      @result[:services].each do |name, service|
        next if NON_BUILDABLE_TYPES.include?(service[:type]) || service[:image].present?
        checksums = []

        BUILD_DEFAULTS.each do |attribute, options|
          value = service.fetch(attribute, options.first)
          if @commit.public_send(options.second, value)
            checksums << @commit.objects_with_checksum_at(value)
          end
        end

        if checksums.size == 2
          @result[:services][name][:image_tag] = Digest::SHA1.hexdigest checksums.to_json
        end
      end
    end

    def merge_environment_overrides!
      return unless services = @project.dig(:environments, @environment.to_sym)
      services.each do |name, service|
        service.each do |attribute, value|
          if value.is_a?(Hash) && @result[:services][name][attribute].is_a?(Hash)
            @result[:services][name][attribute].merge! value
            @result[:services][name][attribute].compact!
          else
            @result[:services][name][attribute] = value
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

      @errors << "Missing `project: <url>` top level attribute." if @project[:project].blank?

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

      services.each do |name, service|
        unless name =~ NAME_FORMAT
          @errors << "`#{name}` is not a valid service name. Allowed characters: a-z, 0-9, -, _"
        end

        unless service.is_a?(Hash)
          @errors << "Service `#{name}` must be a hash."
          next
        end

        service.each do |attribute, value|
          unless VALID_SERVICE_KEYS.include?(attribute)
            @errors << "Service `#{name}` attribute `#{attribute}` is not a valid attribute."
          end
        end

        BUILD_DEFAULTS.each do |attribute, options|
          value = service.fetch(attribute, options.first)
          unless @commit.public_send(options.second, value)
            @errors << "Service `#{name}` specifies `#{attribute}` as `#{value}` which doesn't exist in this commit."
          end
        end

        service.fetch(:env, {}).each do |key, value|
          if value.is_a?(Hash) && value.has_key?(:file)
            unless @commit.file_exists?(value.fetch(:file))
              @errors << "Environment variable `#{key}` referring to a file `#{value.fetch(:file)}` doesn't exist in this commit."
            end
          end
        end
      end
    end

    def validate_environments
      return unless @project.has_key?(:environments)

      environments = @project.fetch :environments, nil

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
