require "test_helper"

class Envirobly::Git::CommitTest < TestCase
  def test_exists
    commit = Envirobly::Git::Commit.new("abcd")
  end
end
