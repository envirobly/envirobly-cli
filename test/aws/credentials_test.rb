require "test_helper"

class Envirobly::Aws::CredentialsTest < TestCase
  def test_as_env_vars
    credential = Envirobly::Aws::Credentials.new(
      "access_key_id" => "a",
      "secret_access_key" => "b",
      "session_token" => "c"
    )
    expected = [
      "AWS_ACCESS_KEY_ID=\"a\"",
      "AWS_SECRET_ACCESS_KEY=\"b\"",
      "AWS_SESSION_TOKEN=\"c\""
    ]
    assert_equal expected, credential.as_env_vars
  end
end