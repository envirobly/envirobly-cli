# frozen_string_literal: true

module Envirobly
  class ContainerShell
    AWS_ENV = [
      "AWS_ACCESS_KEY_ID='%s'",
      "AWS_SECRET_ACCESS_KEY='%s'",
      "AWS_SESSION_TOKEN='%s'"
    ]
    SSH = [
      "ssh -i %s",
      "-o StrictHostKeyChecking=no",
      "-o UserKnownHostsFile=/dev/null",
      "-o SendEnv=ENVIROBLY_SERVICE_INTERACTIVE_SHELL",
      "-o SendEnv=ENVIROBLY_SERVICE_SHELL_USER",
      "-o ProxyCommand='aws ec2-instance-connect open-tunnel --instance-id %s --region %s'"
    ]
    USER_AND_HOST = "envirobly-service@%s"

    attr_reader :options, :service_name

    def initialize(service_name, options, shell:)
      @service_name = service_name
      @options = options

      commit = Git::Commit.new "HEAD"
      default_account = Defaults::Account.new(shell:)
      default_project = Defaults::Project.new(shell:)

      target = Target.new(
        default_account_id: default_account.value,
        default_project_id: default_project.value,
        default_project_name: Defaults::Project.dirname,
        default_environ_name: commit.current_branch,
        account_id: options.account_id,
        project_id: options.project_id,
        project_name: options.project_name,
        environ_name: options.environ_name
      )

      if target.missing_params.include?(:account_id)
        target.account_id = default_account.require_value
      end

      @params = {
        account_id: target.account_id,
        project_id: target.project_id,
        project_name: target.project_name,
        environ_name: target.environ_name,
        service_name:,
        instance_slot: options.instance_slot || 0
      }

      if options.project_name.blank? && options.account_id.blank? && options.project_id.blank?
        @params[:project_id] = Defaults::Project.new.value
      end
    end

    def exec(command = nil)
      with_private_key do
        system join(env_vars, ssh, user_and_host, command)
      end
    end

    def rsync(source, destination)
      with_private_key do
        system join(
          env_vars,
          %(rsync #{options.args} -e "#{ssh}"),
          source.sub("#{service_name}:", "#{user_and_host}:"),
          destination.sub("#{service_name}:", "#{user_and_host}:")
        )
      end
    end

    private
      def join(*parts)
        parts.flatten.compact.join(" ")
      end

      def connect_data
        @connect_data ||= begin
          api = Api.new
          api.create_service_shell_connection(@params).object
        end
      end

      def with_private_key
        Tempfile.create do |file|
          file.write connect_data.fetch("instance").fetch("private_key")
          file.flush

          @private_key_path = file.path

          yield
        end
      end

      def env_vars
        credentials = connect_data.fetch("open_tunnel_credentials")

        result = sprintf(
          join(AWS_ENV),
          credentials.fetch("access_key_id"),
          credentials.fetch("secret_access_key"),
          credentials.fetch("session_token")
        )

        if options.shell.present?
          result = join "ENVIROBLY_SERVICE_INTERACTIVE_SHELL='#{options.shell}'", result
        end

        if options.user.present?
          result = join "ENVIROBLY_SERVICE_SHELL_USER='#{options.user}'", result
        end

        result
      end

      def ssh
        sprintf(
          join(SSH),
          @private_key_path,
          connect_data.fetch("instance").fetch("aws_id"),
          connect_data.fetch("region")
        )
      end

      def user_and_host
        sprintf USER_AND_HOST, connect_data.fetch("instance").fetch("private_ipv4")
      end
  end
end
