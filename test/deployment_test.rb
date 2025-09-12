# frozen_string_literal: true

require "test_helper"

module Envirobly
  class DeploymentTest < ActiveSupport::TestCase
    test "all required params specified, no defaults used" do
      skip "TODO needs .envirobly dir in working_dir"

      commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
      deployment = Deployment.new(
        account_id: 1,
        project_name: "success",
        environ_name: "main",
        region: "eu-north-1",
        project_id: nil,
        commit:,
        shell: nil
      )
      result = deployment.params
      assert_equal 1, result[:account_id]
    end
  end
end
