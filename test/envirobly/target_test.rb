# frozen_string_literal: true

require "test_helper"

module Envirobly
  class TargetTest < ActiveSupport::TestCase
    test "all defaults exist, no overrides" do
      target = Target.new config_path: Pathname.new("test/fixtures/targets")
      assert_equal "https://example.com/accounts/1", target.account_url
      assert_equal 1, target.account_id
      assert_equal "world", target.project_name
      assert_equal "eu-north-1", target.region
    end

    test "all defaults exist, override account_url" do
      target = Target.new(
        account_url: "https://example.com/accounts/3",
        config_path: Pathname.new("test/fixtures/targets")
      )
      assert_equal "https://example.com/accounts/3", target.account_url
      assert_equal 3, target.account_id
      assert_equal "world", target.project_name
      assert_equal "eu-north-1", target.region
    end

    test "all defaults exist, override project_name" do
      target = Target.new(
        project_name: "home",
        config_path: Pathname.new("test/fixtures/targets")
      )
      assert_equal 1, target.account_id
      assert_equal "home", target.project_name
      assert_equal "eu-north-1", target.region
    end

    test "missing_params" do
      target = Target.new
      assert_equal %i[ account_url region ], target.missing_params

      target.account_url = "https://example.com/accounts/3"
      assert_equal 3, target.account_id
      assert_equal %i[ region ], target.missing_params

      target.region = "us-east-2"
      assert_empty target.missing_params
    end

    # test "default_project_name and default_environ_name and no other defaults" do
    #   target = Target.new(
    #     default_project_name: "dirname",
    #     default_environ_name: "main"
    #   )
    #   assert_nil target.account_id
    #   assert_nil target.project_id
    #   assert_equal "dirname", target.project_name
    #   assert_equal "main", target.environ_name
    #   assert_nil target.region
    #   assert_equal %i[ account_id region ], target.missing_params
    # end
    #
    # test "environ_name override" do
    #   target = Target.new(
    #     default_project_name: "dirname",
    #     default_environ_name: "main",
    #     environ_name: "production"
    #   )
    #   assert_nil target.account_id
    #   assert_nil target.project_id
    #   assert_equal "dirname", target.project_name
    #   assert_equal "production", target.environ_name
    #   assert_nil target.region
    #   assert_equal %i[ account_id region ], target.missing_params
    # end
  end
end
