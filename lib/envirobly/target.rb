# frozen_string_literal: true

module Envirobly
  class Target
    attr_accessor :project_id, :region

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
      @project_id = project_id
      @project_name = project_name
      @environ_name = environ_name
      @config_path = config_path
      @default_target_dir = config_path.join(".default")
    end

    def missing_params
      [].tap do |result|
        if project_id.blank? && account_id.blank?
          result << :account_id
        end

        if project_id.blank? && region.blank?
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

    def project_id
      return if @project_id.blank? && (@account_id.present? || @project_name.present?)

      @project_id || @default_project_id
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

    def ignored_params
      [].tap do |result|
        if @account_id && @project_id
          result << :account_id
        end

        if @project_id && @region
          result << :region
        end

        if @project_id && @project_name.present?
          result << :project_name
        end
      end
    end

    private
      def default_value_for(type)
        File.read(@default_target_dir.join(type)).strip
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
