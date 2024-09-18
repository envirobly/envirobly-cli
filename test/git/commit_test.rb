require "test_helper"

class Envirobly::Git::CommitTest < ActiveSupport::TestCase
  test "exists? when not a git object" do
    commit = Envirobly::Git::Commit.new("not-a-git-object", working_dir:)
    assert_not commit.exists?
  end

  test "exists? when provided hash is not found" do
    commit = Envirobly::Git::Commit.new("5b30cdac88626750ad840f11d86f56a3c89d2180", working_dir:)
    assert_not commit.exists?
  end

  test "ref outputs full hash when initialized from short one" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first.slice(0, 7), working_dir:)
    assert_equal repo1_commits.first, commit.ref
  end

  test "exists with existing ref" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert commit.exists?
  end

  test "ref outputs object hash when given its tag" do
    commit = Envirobly::Git::Commit.new("v1", working_dir:)
    assert_equal repo1_commits.first, commit.ref
  end

  test "message" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_equal "a", commit.message
  end

  test "time" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_kind_of Time, commit.time
  end

  test "config_content when there is no config" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_empty commit.config_content
  end

  test "config_content with config present" do
    commit = Envirobly::Git::Commit.new(repo1_commits[1], working_dir:)
    assert_equal "hi\n", commit.config_content
  end

  test "objects_with_checksum at root dir does not contain config dir" do
    commit = Envirobly::Git::Commit.new(repo1_commits[1], working_dir:)
    expected = [ "78981922613b2afb6025042ff6bd878ac1994e85 a.txt" ]
    assert_equal expected, commit.objects_with_checksum_at(".")
  end

  test "objects_with_checksum when given a tag" do
    commit = Envirobly::Git::Commit.new("v1", working_dir:)
    expected = [ "78981922613b2afb6025042ff6bd878ac1994e85 a.txt" ]
    assert_equal expected, commit.objects_with_checksum_at(".")
  end
end
