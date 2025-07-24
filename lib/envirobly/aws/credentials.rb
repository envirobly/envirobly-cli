# frozen_string_literal: true

# @deprecated
class Envirobly::Aws::Credentials
  def initialize(params)
    @params = params
  end

  def to_h
    @params
  end

  def as_env_vars
    [
      %(AWS_ACCESS_KEY_ID="#{@params.fetch("access_key_id")}"),
      %(AWS_SECRET_ACCESS_KEY="#{@params.fetch("secret_access_key")}"),
      %(AWS_SESSION_TOKEN="#{@params.fetch("session_token")}")
    ]
  end

  def as_inline_env_vars
    as_env_vars.join " "
  end
end
