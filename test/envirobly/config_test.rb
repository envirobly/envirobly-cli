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
      x: {
        shared_env: {
          VERSION: 1
        }
      },
      services: {
        app: {
          public: true,
          env: {
            VERSION: 1,
            APP_ENV: "production"
          }
        }
      }
    }
    assert_equal expected, config.merge
    assert_empty config.errors
  end

  test "merge with environ override" do
    config = Envirobly::Config.new("test/fixtures/configs")
    expected = {
      x: {
        shared_env: {
          VERSION: 1
        }
      },
      services: {
        app: {
          public: false,
          instance_type: "t4g.micro",
          env: {
            VERSION: 1,
            APP_ENV: "staging",
            STAGING_VAR: "abcd"
          }
        }
      }
    }
    assert_equal expected, config.merge("staging")
    assert_empty config.errors
  end
end
