# frozen_string_literal: true

module Envirobly
  class Target
    attr_accessor :account_id, :project_id, :region

    def initialize(
        default_account_id: nil,
        default_project_id: nil,
        default_region: nil,
        default_project_name: nil,
        default_environ_name: nil,
        account_id: nil,
        project_id: nil,
        region: nil,
        project_name: nil,
        environ_name: nil
      )
      @default_account_id = default_account_id
      @default_project_id = default_project_id
      @default_region = default_region
      @default_project_name = default_project_name
      @default_environ_name = default_environ_name
      @account_id = account_id
      @project_id = project_id
      @region = region
      @project_name = project_name
      @environ_name = environ_name
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

    def account_id
      return if @project_id

      @account_id || @default_account_id
    end

    def project_id
      return if @account_id || (@project_name.present? && @project_id.blank?)

      @project_id || @default_project_id
    end

    def project_name
      return if @project_id

      @project_name.presence || @default_project_name
    end

    def environ_name
      @environ_name.presence || @default_environ_name
    end

    def region
      return if @project_id

      @region || @default_region
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
  end
end
