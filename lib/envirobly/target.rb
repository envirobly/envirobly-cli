# frozen_string_literal: true

module Envirobly
  class Target
    attr_accessor :account_url, :project_name, :region, :name
    attr_reader :service_name, :shell

    def initialize(
        path = nil,
        account_url: nil,
        region: nil,
        project_name: nil,
        default_environ_name: nil,
        default_project_name: nil,
        config_path: Config::TARGETS_PATH,
        context: nil,
        shell: nil
      )
      @account_url = account_url
      @region = region
      @project_name = project_name
      @default_environ_name = default_environ_name
      @default_project_name = default_project_name
      @config_path = config_path
      @context = context
      @name = ".default"
      @shell = shell

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
      @account_url.presence || stored_value_for("account_url")
    end

    def account_id
      if account_url =~ /accounts\/(\d)+/i
        $1.to_i
      else
        nil
      end
    end

    def project_name
      @project_name.presence || stored_value_for("project_name").presence || @default_project_name
    end

    def environ_name
      @environ_name.presence || @default_environ_name
    end

    def region
      @region.presence || stored_value_for("region")
    end

    def save
      save_attribute "account_url"
      save_attribute "project_name"
      save_attribute "region"
    end

    def configure!
      configure_account
      configure_project_name
      configure_region
    end

    private
      def storage_dir
        @config_path.join(@name)
      end

      def stored_value_for(type)
        File.read(storage_dir.join(type)).strip
      rescue Errno::ENOENT
        nil
      end

      def save_attribute(type)
        FileUtils.mkdir_p storage_dir
        File.write storage_dir.join(type), send(type)
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

      def configure_account
        shell.say "Configuring "
        shell.say "#{@name} ", :green
        shell.say "deploy target"
        shell.say

        api = Envirobly::Api.new
        accounts = api.list_accounts

        if accounts.object.blank?
          shell.say_error "Please connect an AWS account to your Envirobly account first."
          exit 1
        end

        data = [ [ "ID", "Name", "AWS number", "URL" ] ] +
          accounts.object.pluck("id", "name", "aws_id", "url")

        shell.say "Available accounts:"
        shell.print_table data, borders: true

        limited_to = accounts.object.pluck("id").map(&:to_s)
        account_id = limited_to.first

        begin
          account_id = shell.ask("Choose Account ID:", limited_to:, default: account_id).to_i
        rescue Interrupt
          shell.say_error "Cancelled", :red
          exit
        end

        accounts.object.each do |account|
          if account_id == account["id"]
            @account_url = account["url"]
            break
          end
        end

        save_attribute "account_url"
      end

      def configure_project_name
        begin
          @project_name = shell.ask("Name your project:", default: project_name)
        rescue interrupt
          shell.say_error "cancelled", :red
          exit
        end

        save_attribute "project_name"
      end

      def configure_region
        api = Envirobly::Api.new
        response = api.list_regions

        shell.say "Choose region:"
        shell.print_table [ [ "Name", "Location", "Group" ] ] +
          response.object.pluck("code", "title", "group_title"), borders: true

        code = nil
        limited_to = response.object.pluck("code")

        while code.nil?
          begin
            code = shell.ask("Region name:", default: "us-east-1")
          rescue Interrupt
            shell.say_error "Cancelled", :red
            exit
          end

          unless code.in?(limited_to)
            shell.say_error "'#{code}' is not a supported region, please try again"
            code = nil
          end
        end

        @region = code
        save_attribute "region"
      end
  end
end
