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
      "x" => {
        "shared_env" => {
          "SECRET" => Envirobly::Secret.new("mySecret")
        }
      },
      "services" => {
        "app" => {
          "public" => true,
          "env" => {
            "SECRET" => Envirobly::Secret.new("mySecret"),
            "APP_ENV" => "production"
          }
        }
      }
    }

    assert_equal expected, config.merge
    assert_empty config.errors

    assert_equal expected, config.merge("xyz"), "This override doens't exist"
    assert_empty config.errors
  end

  test "merge with environ override" do
    config = Envirobly::Config.new("test/fixtures/configs")
    expected = {
      "x" => {
        "shared_env" => {
          "SECRET" => Envirobly::Secret.new("mySecret")
        }
      },
      "services" => {
        "app" => {
          "public" => false,
          "instance_type" => "t4g.micro",
          "env" => {
            "SECRET" => Envirobly::Secret.new("mySecret"),
            "APP_ENV" => "staging",
            "STAGING_VAR" => "abcd"
          }
        }
      }
    }
    assert_equal expected, config.merge("staging")
    assert_empty config.errors
  end

  test "invalid YAML" do
    config = Envirobly::Config.new("test/fixtures/invalid_configs")
    assert_nil config.merge
    assert_equal 1, config.errors.size
    assert_equal "(<unknown>): did not find expected node content while parsing a flow node at line 2 column 3", config.errors.first[:message]
    assert_equal ".envirobly/deploy.yml", config.errors.first[:path]
  end

  test "invalid ERB" do
    config = Envirobly::Config.new("test/fixtures/invalid_configs")
    assert_nil config.merge("erb-error")
    assert_equal 2, config.errors.size
    assert_equal ".envirobly/deploy.yml", config.errors.first[:path]
    assert_equal ".envirobly/deploy.erb-error.yml", config.errors.second[:path]
    assert_equal "uncaught throw \"ERB error\"", config.errors.second[:message]
  end
end
