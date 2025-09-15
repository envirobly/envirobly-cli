# frozen_string_literal: true

require "test_helper"

module Envirobly
  class AccessTokenTest < ActiveSupport::TestCase
    test "save and read" do
      refute File.exist?(AccessToken.path)

      access_token = AccessToken.new("abcd!", shell: nil)
      access_token.save

      assert File.exist?(AccessToken.path)
      assert_equal "Bearer abcd!", access_token.as_http_bearer
    end

    test "set" do
      shell = mock "Thor::Shell"
      shell.stubs(:say).returns nil
      shell.stubs(:ask).returns "1234"

      access_token = AccessToken.new(shell:)
      access_token.set

      assert File.exist?(AccessToken.path)
      assert_equal "1234", File.read(AccessToken.path)

      assert_equal "Bearer 1234", access_token.as_http_bearer
    end
  end
end
