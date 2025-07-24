class Envirobly::ContainerShell
  ENV = [
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

  def initialize(service_name, inner_command, options)
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
    with_private_key do |private_key_path|
      cmd = sprintf(
        join(ENV, SSH, USER_AND_HOST),
        ssh_params.fetch("open_tunnel_credentials").fetch("access_key_id"),
        ssh_params.fetch("open_tunnel_credentials").fetch("secret_access_key"),
        ssh_params.fetch("open_tunnel_credentials").fetch("session_token"),
        private_key_path,
        ssh_params.fetch("instance").fetch("aws_id"),
        ssh_params.fetch("region"),
        ssh_params.fetch("instance").fetch("private_ipv4")
      )

      if @options.shell.present?
        cmd = join "ENVIROBLY_SERVICE_INTERACTIVE_SHELL='#{@options.shell}'", cmd
      end

      if @options.user.present?
        cmd = join "ENVIROBLY_SERVICE_SHELL_USER='#{@options.user}'", cmd
      end

      if @inner_command.present?
        cmd = join cmd, @inner_command
      end

      system cmd
    end
  end

  private
    def join(*parts)
      parts.flatten.join(" ")
    end

    def ssh_params
      @ssh_params ||= begin
        api = Envirobly::Api.new
        api.create_service_shell_connection(@params).object
      end
    end

    def with_private_key
      Tempfile.create do |file|
        file.write ssh_params.fetch("instance").fetch("private_key")
        file.flush

        yield file.path
      end
    end
end
