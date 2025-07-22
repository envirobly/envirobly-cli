class Envirobly::ContainerShell
  CMD_TEMLATE =
    "AWS_ACCESS_KEY_ID='%s' " +
    "AWS_SECRET_ACCESS_KEY='%s' " +
    "AWS_SESSION_TOKEN='%s' " +
    "ssh -i %s " +
    "envirobly-service@%s " +
    "-o StrictHostKeyChecking=accept-new " +
    "-o ProxyCommand='aws ec2-instance-connect open-tunnel --instance-id %s --region %s'"

  def initialize(service_name, command, options)
    @command = command
    @options = options
    @params = {
      project: {
        account_id: options.account_id,
        name: options.project_name,
        id: options.project_id
      },
      environ: { name: options.environ_name },
      service: { name: service_name },
      instance: { slot: options.instance_slot }
    }
  end

  def connect
    api = Envirobly::Api.new
    response = api.create_service_shell_connection @params
    ssh_params = response.object

    Tempfile.create do |tempkey|
      tempkey.write ssh_params.fetch("instance").fetch("private_key")
      tempkey.flush

      cmd = sprintf(
        CMD_TEMLATE,
        ssh_params.fetch("open_tunnel_credentials").fetch("access_key_id"),
        ssh_params.fetch("open_tunnel_credentials").fetch("secret_access_key"),
        ssh_params.fetch("open_tunnel_credentials").fetch("session_token"),
        tempkey.path,
        ssh_params.fetch("instance").fetch("private_ipv4"),
        ssh_params.fetch("instance").fetch("aws_id"),
        ssh_params.fetch("region")
      )

      if @options.shell.present?
        cmd = "ENVIROBLY_SERVICE_INTERACTIVE_SHELL='#{options.shell}' #{cmd} -o SendEnv=ENVIROBLY_SERVICE_INTERACTIVE_SHELL"
      end

      if @options.user.present?
        cmd = "ENVIROBLY_SERVICE_SHELL_USER='#{options.user}' #{cmd} -o SendEnv=ENVIROBLY_SERVICE_SHELL_USER"
      end

      if @command.present?
        cmd = "#{cmd} #{@command.join(" ")}"
      end

      system cmd
    end
  end
end
