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
    assert_equal Time.parse("Sep 18 10:20:34 2024"), commit.time
  end

  test "file_content with file missing" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_empty commit.file_content("b.txt")
  end

  test "file_content with file present" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_equal "a\n", commit.file_content("a.txt")
  end

  test "objects_with_checksum at root dir does not contain config dir" do
    commit = Envirobly::Git::Commit.new(repo1_commits.second, working_dir:)
    expected = [ "78981922613b2afb6025042ff6bd878ac1994e85 a.txt" ]
    assert_equal expected, commit.objects_with_checksum_at(".")
  end

  test "objects_with_checksum when given a tag" do
    commit = Envirobly::Git::Commit.new("v1", working_dir:)
    expected = [ "78981922613b2afb6025042ff6bd878ac1994e85 a.txt" ]
    assert_equal expected, commit.objects_with_checksum_at(".")
  end

  test "objects_with_checksum when path does not exist" do
    commit = Envirobly::Git::Commit.new("v1", working_dir:)
    expected = []
    assert_equal expected, commit.objects_with_checksum_at("i-am-not-there")
  end
end
