# frozen_string_literal: true

require "test_helper"

class Envirobly::ConfigTest < ActiveSupport::TestCase
  test "load" do
    configs = Envirobly::Config.new("test/fixtures/configs")

    expected = {
      configs: {
        ".envirobly/deploy.yml" => File.read("test/fixtures/configs/deploy.yml"),
        ".envirobly/deploy.staging.yml" => File.read("test/fixtures/configs/deploy.staging.yml")
      },
      env_vars: {
        "JUST_A_NUMBER" => "1",
        "POEM" => "some multiline\ntext with an emoji: 🦄",
        "INTERPOLATED_COMMAND" => "interpolated"
      }
    }
    assert_equal expected, configs.to_params
  end
end
