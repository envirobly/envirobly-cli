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
  end
end
