# frozen_string_literal: true

require "test_helper"

module Envirobly
  class SecretTest < ActiveSupport::TestCase
    test "equality" do
      secret1 = Secret.new("a")
      secret2 = Secret.new("a")
      assert_equal secret1, secret2

      secret2 = Secret.new("b")
      assert_not_equal secret1, secret2
    end
  end
end
