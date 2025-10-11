# frozen_string_literal: true

require "test_helper"

module Envirobly
  class NameTest < ActiveSupport::TestCase
    test "successful validate" do
      name = Name.new("produc-tio_n")
      assert name.validate
      assert_nil name.error
    end

    test "failed validate" do
      name = Name.new("!")
      assert_not name.validate
      assert_not_empty name.error
    end
  end
end
