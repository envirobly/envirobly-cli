
require "test_helper"

class Envirobly::NumericTest < ActiveSupport::TestCase
  test "default formatting to two decimal places" do
    numeric = Envirobly::Numeric.new(0.5)
    assert numeric.is_a?(Numeric)
    assert_equal "0.50", numeric.to_s

    numeric = Envirobly::Numeric.new(2)
    assert_equal "2.00", numeric.to_s
  end

  test "formatting to shortest form" do
    numeric = Envirobly::Numeric.new(0.5, short: true)
    assert_equal "0.5", numeric.to_s

    numeric = Envirobly::Numeric.new(2.0, short: true)
    assert_equal "2", numeric.to_s
  end
end
