# frozen_string_literal: true

require "test_helper"

class Envirobly::ConfigTest < ActiveSupport::TestCase
  test "configs" do
    config = Envirobly::Config.new("test/fixtures/configs")

    expected = {
      ".envirobly/deploy.yml" => File.read("test/fixtures/configs/deploy.yml"),
      ".envirobly/deploy.staging.yml" => File.read("test/fixtures/configs/deploy.staging.yml")
    }
    assert_equal expected, config.configs
  end

  test "merge without override" do
    config = Envirobly::Config.new("test/fixtures/configs")
    expected = {
      x: { shared_env: { VERSION: 1 } },
      services: {
        app: { public: true, env: { VERSION: 1, APP_ENV: "production" } }
      }
    }
    assert_equal expected, config.merge
  end

  test "merge with environ override" do
    skip "todo"
  end
end
