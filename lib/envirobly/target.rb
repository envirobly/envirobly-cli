# frozen_string_literal: true

module Envirobly
  class Target
    attr_accessor :account_url, :project_name, :region

    def initialize(
        name: nil,
        account_url: nil,
        region: nil,
        project_name: nil,
        environ_name: nil,
        config_path: Config::TARGETS_PATH
      )
      @name = name
      @account_url = account_url
      @region = region
      @project_name = project_name
      @environ_name = environ_name
      @config_path = config_path
      @default_target_dir = config_path.join(".default")
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
      @project_name.presence || default_project_name
    end

    def environ_name
      @environ_name.presence || @default_environ_name
    end

    def region
      @region.presence || default_region
    end

    private
      def default_value_for(type)
        File.read(@default_target_dir.join(type)).strip
      rescue Errno::ENOENT
        nil
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
  end
end
