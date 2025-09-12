# frozen_string_literal: true

module Envirobly
  class Target
    attr_accessor :account_id, :project_id, :region

    def initialize(
        default_account_id: nil,
        default_project_id: nil,
        default_region: nil,
        account_id: nil,
        project_id: nil,
        region: nil,
        project_name: nil
      )
      @default_account_id = default_account_id
      @default_project_id = default_project_id
      @default_region = default_region
      @account_id = account_id
      @project_id = project_id
      @region = region
      @project_name = project_name
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

      @project_name.presence
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
      end
    end
  end
end
