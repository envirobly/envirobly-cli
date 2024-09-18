require "test_helper"

class Envirobly::Git::CommitTest < TestCase
  def test_exists_when_not_a_git_object
    commit = Envirobly::Git::Commit.new("not-a-git-object", working_dir:)
    refute commit.exists?
  end

  def test_exists_when_ref_does_not_exist
    commit = Envirobly::Git::Commit.new("5b30cdac88626750ad840f11d86f56a3c89d2180", working_dir:)
    refute commit.exists?
  end

  def test_ref_otputs_full_hash_when_given_short_one
    commit = Envirobly::Git::Commit.new(repo1_commits.first.slice(0, 7), working_dir:)
    assert_equal repo1_commits.first, commit.ref
  end

  def test_ref_otputs_object_hash_when_given_tag
    commit = Envirobly::Git::Commit.new("v1", working_dir:)
    assert_equal repo1_commits.first, commit.ref
  end

  def test_exists_with_existing_ref
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert commit.exists?
  end

  def test_message
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_equal "a", commit.message
  end

  def test_time
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_kind_of Time, commit.time
  end

  def test_config_content_when_there_is_no_config
    commit = Envirobly::Git::Commit.new(repo1_commits.first, working_dir:)
    assert_empty commit.config_content
  end

  def test_config_content_with_config_present
    commit = Envirobly::Git::Commit.new(repo1_commits[1], working_dir:)
    assert_equal "hi\n", commit.config_content
  end

  def test_objects_with_checksum_at_does_not_contain_config_file
    skip "TODO"
  end
end
