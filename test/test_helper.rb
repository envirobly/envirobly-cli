# frozen_string_literal: true

require "bundler/setup"
require "active_support/test_case"
require "active_support/testing/autorun"
require "mocha/minitest"
require "minitest/autorun"
require "debug"
require "envirobly"

class ActiveSupport::TestCase
  def repo1_commits
    [
      "61fe5eb7c26d589b7cbb69c87b9f3f8412d8fca3", # a
      "83d49dc06cdd6a4629d59888386622e1c3bdfeb9", # config
      "38541a424ac370a6cccb4a4131f1125a7535cb84", # simple services definition
      "ac3457fbdd2ef219a8e2e0e074365092970d5dd3" # kitchen sink config
    ]
  end

  def repo1_working_dir
    "#{Dir.getwd}/test/fixtures/repo1"
  end
  alias :working_dir :repo1_working_dir

  setup do
    @data_home_dir = Dir.mktmpdir "envirobly-cli-test"
    ENV["ENVIROBLY_CLI_DATA_HOME"] = @data_home_dir
  end

  teardown do
    FileUtils.rm_rf @data_home_dir
  end
end
