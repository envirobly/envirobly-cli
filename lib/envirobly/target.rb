# frozen_string_literal: true

module Envirobly
  class Target
    attr_accessor :account_url, :project_name, :region
    attr_reader :name, :service_name

    def initialize(
        path = nil,
        account_url: nil,
        region: nil,
        project_name: nil,
        default_environ_name: nil,
        default_project_name: nil,
        config_path: Config::TARGETS_PATH,
        context: nil
      )
      @account_url = account_url
      @region = region
      @project_name = project_name
      @default_environ_name = default_environ_name
      @default_project_name = default_project_name
      @config_path = config_path
      @context = context
      @name = ".default"

      load_path path
    end

    def missing_params
      [].tap do |result|
        if account_url.blank?
          result << :account_url
        end

        if region.blank?
          result << :region
        end
      end
    end

    def account_url
      @account_url.presence || default_account_url
    end

    def account_id
      if account_url =~ /accounts\/(\d)+/i
        $1.to_i
      else
        nil
      end
    end

    def project_name
      @project_name.presence || default_project_name.presence || @default_project_name
    end

    def environ_name
      @environ_name.presence || @default_environ_name
    end

    def region
      @region.presence || default_region
    end

    def save
      FileUtils.mkdir_p storage_dir
      write_default "account_url"
      write_default "project_name"
      write_default "region"
    end

    private
      def storage_dir
        @config_path.join(@name)
      end

      def default_value_for(type)
        File.read(storage_dir.join(type)).strip
      rescue Errno::ENOENT
        nil
      end

      def write_default(type)
        File.write storage_dir.join(type), send(type)
      end

      def default_account_url
        default_value_for "account_url"
      end

      def default_project_name
        default_value_for "project_name"
      end

      def default_region
        default_value_for "region"
      end

      def load_path(path)
        return if path.blank?

        parts = path.split("/").map &:strip

        if @context == :service
          case parts.size
          when 1
            @service_name = parts.first
          when 2
            @environ_name, @service_name = parts
          when 3
            @name, @environ_name, @service_name = parts
            @default_project_name = @name
          end

          return
        end

        case parts.size
        when 1
          @environ_name = parts.first
        when 2
          @name, @environ_name = parts
          @default_project_name = @name
        end
      end
  end
end
