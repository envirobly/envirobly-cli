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
    assert_equal Time.parse("2024-09-18 10:20:34 +0200"), commit.time
  end

  test "file_exists? with missing file" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_not commit.file_exists?("b.txt")
  end

  test "file_exists? when pointed to directory fails" do
    commit = Envirobly::Git::Commit.new("ac3457fbdd2ef219a8e2e0e074365092970d5dd3", working_dir:)
    assert_not commit.file_exists?("app")
  end

  test "file_exists? with present file" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert commit.file_exists?("a.txt")
  end

  test "dir_exists? with missing dir" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_not commit.dir_exists?("not-there")
  end

  test "dir_exists? when pointed to file fails" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_not commit.dir_exists?("a.txt")
  end

  test "dir_exists? with present dir" do
    commit = Envirobly::Git::Commit.new("ac3457fbdd2ef219a8e2e0e074365092970d5dd3", working_dir:)
    assert commit.dir_exists?("app")
    assert commit.dir_exists?("app/")
    assert commit.dir_exists?("./")
    assert commit.dir_exists?(".")
  end

  test "file_content with file missing" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_empty commit.file_content("b.txt")
  end

  test "file_content with file present" do
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_equal "a\n", commit.file_content("a.txt")
  end

  test "object_tree doesn't list envirobly config" do
    commit = Envirobly::Git::Commit.new(repo1_commits.second, working_dir:)
    expected = {}
    expected[working_dir] = [
      [ "100644", "blob", "78981922613b2afb6025042ff6bd878ac1994e85", "a.txt" ]
    ]
    assert_equal expected, commit.object_tree
  end

  test "object_tree_checksum" do
    commit = Envirobly::Git::Commit.new(repo1_commits.second, working_dir:)
    assert_equal "129745150acdf0ebfbcd106d608d9a4de5ef718f884faaea6cde6416018c5b3c", commit.object_tree_checksum
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
