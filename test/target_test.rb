# frozen_string_literal: true

require "test_helper"

module Envirobly
  class TargetTest < ActiveSupport::TestCase
    test "all defaults exist, no overrides" do
      target = Target.new(
        default_account_id: 1,
        default_project_id: 2,
        default_region: "eu-north-1"
      )
      assert_equal 1, target.account_id
      assert_equal 2, target.project_id
      assert_equal "eu-north-1", target.region
    end

    test "all defaults exist, override account_id" do
      target = Target.new(
        default_account_id: 1,
        default_project_id: 2,
        default_region: "eu-north-1",
        account_id: 3
      )
      assert_equal 3, target.account_id
      assert_nil target.project_id
      assert_equal "eu-north-1", target.region
    end

    test "all defaults exist, override project_id" do
      target = Target.new(
        default_account_id: 1,
        default_project_id: 2,
        default_region: "eu-north-1",
        project_id: 3
      )
      assert_nil target.account_id
      assert_equal 3, target.project_id
      assert_nil target.region
    end

    test "ignored_params when project_id is specified" do
      target = Target.new(
        account_id: 6,
        project_id: 3,
        region: "us-east-2"
      )
      assert_equal %i[ account_id region ], target.ignored_params

      target = Target.new(
        project_id: 3,
        region: "us-east-2"
      )
      assert_equal %i[ region ], target.ignored_params

      target = Target.new(
        project_id: 3
      )
      assert_empty target.ignored_params
    end

    test "missing_params" do
      target = Target.new
      assert_equal %i[ account_id region ], target.missing_params

      target.account_id = 6
      assert_equal %i[ region ], target.missing_params

      target.region = "us-east-2"
      assert_empty target.missing_params
    end

    test "project_name overrides default_project_id and default_project_name" do
      target = Target.new(
        default_account_id: 1,
        default_project_id: 2,
        default_project_name: "dirname",
        project_name: "custom"
      )
      assert_equal 1, target.account_id
      assert_nil target.project_id
      assert_equal "custom", target.project_name
      assert_equal %i[ region ], target.missing_params
    end

    test "project_id overrides project_name" do
      target = Target.new(
        default_account_id: 1,
        default_project_id: 2,
        default_project_name: "dirname",
        project_name: "custom",
        project_id: 3
      )
      assert_nil target.account_id
      assert_equal 3, target.project_id
      assert_nil target.project_name
      assert_nil target.region
      assert_empty target.missing_params
      assert_equal %i[ project_name ], target.ignored_params
    end

    test "default_project_name and default_environ_name and no other defaults" do
      target = Target.new(
        default_project_name: "dirname",
        default_environ_name: "main"
      )
      assert_nil target.account_id
      assert_nil target.project_id
      assert_equal "dirname", target.project_name
      assert_equal "main", target.environ_name
      assert_nil target.region
      assert_equal %i[ account_id region ], target.missing_params
      assert_empty target.ignored_params
    end

    test "environ_name override" do
      target = Target.new(
        default_project_name: "dirname",
        default_environ_name: "main",
        environ_name: "production"
      )
      assert_nil target.account_id
      assert_nil target.project_id
      assert_equal "dirname", target.project_name
      assert_equal "production", target.environ_name
      assert_nil target.region
      assert_equal %i[ account_id region ], target.missing_params
      assert_empty target.ignored_params
    end
  end
end
