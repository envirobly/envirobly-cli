class Envirobly::ContainerShell
  AWS_ENV = [
    "AWS_ACCESS_KEY_ID='%s'",
    "AWS_SECRET_ACCESS_KEY='%s'",
    "AWS_SESSION_TOKEN='%s'"
  ]
  SSH = [
    "ssh -i %s",
    "-o StrictHostKeyChecking=accept-new",
    "-o SendEnv=ENVIROBLY_SERVICE_INTERACTIVE_SHELL",
    "-o SendEnv=ENVIROBLY_SERVICE_SHELL_USER",
    "-o ProxyCommand='aws ec2-instance-connect open-tunnel --instance-id %s --region %s'"
  ]
  USER_AND_HOST = "envirobly-service@%s"

  attr_reader :options, :service_name

  def initialize(service_name, inner_command, options)
    @service_name = service_name
    @inner_command = inner_command
    @options = options
    commit = Envirobly::Git::Commit.new "HEAD"

    @params = {
      project: {
        account_id: options.account_id || Envirobly::Defaults::Account.new.id,
        name: options.project_name || File.basename(Dir.pwd), # TODO: Extract into Defaults::ProjectName
        id: options.project_id
      },
      environ: { name: options.environ_name || commit.current_branch },
      service: { name: service_name },
      instance: { slot: options.instance_slot }
    }

    if options.project_name.blank? && options.account_id.blank? && options.project_id.blank?
      @params[:project][:id] = Envirobly::Defaults::Project.new.id
    end
  end

  def connect
    with_private_key do
      system join(env_vars, ssh, user_and_host, @inner_command)
    end
  end

  def rsync(source, destination)
    with_private_key do
      system join(
        env_vars,
        %(rsync #{options.args} -e "#{ssh}"),
        source.replace("#{service_name}:", "#{user_and_host}:"),
        destination.replace("#{service_name}:", "#{user_and_host}:")
      )
    end
  end

  private
    def join(*parts)
      parts.flatten.compact.join(" ")
    end

    def connect_data
      @connect_data ||= begin
        api = Envirobly::Api.new
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
