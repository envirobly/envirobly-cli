# frozen_string_literal: true

require "test_helper"

module Envirobly
  class AccessTokenTest < ActiveSupport::TestCase
    test "save and read" do
      access_token = AccessToken.new("abcd!", shell: nil)
      access_token.save

      assert_equal "Bearer abcd!", access_token.as_http_bearer
    end
  end
end
