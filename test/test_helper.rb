require "bundler/setup"
require "active_support/test_case"
require "active_support/testing/autorun"
require "minitest/autorun"
require "debug"
require "envirobly"

class ActiveSupport::TestCase
  def repo1_commits
    [
      "61fe5eb7c26d589b7cbb69c87b9f3f8412d8fca3", # a
      "83d49dc06cdd6a4629d59888386622e1c3bdfeb9", # config
      "38541a424ac370a6cccb4a4131f1125a7535cb84", # simple services definition
      "210f84ac05698bbb494ff329e84910f5981fdd86" # kitchen sink config
    ]
  end

  def repo1_working_dir
    "#{Dir.getwd}/test/fixtures/repo1"
  end
  alias :working_dir :repo1_working_dir
end
