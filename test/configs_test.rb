require "test_helper"

class Envirobly::ConfigsTest < ActiveSupport::TestCase
  test "load" do
    configs = Envirobly::Configs.new("test/fixtures/configs")

    expected = {
      configs: {
        "deploy.yml" => File.read("test/fixtures/configs/deploy.yml"),
        "deploy.staging.yml" => File.read("test/fixtures/configs/deploy.staging.yml")
      },
      env_vars: {
        "SOME_ENV_VAR" => "1",
        "POEM" => "some multiline\ntext with an emoji: 🦄"
      }
    }
    assert_equal expected, configs.to_params
  end
end
