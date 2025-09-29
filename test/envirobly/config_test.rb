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
end
