require "test_helper"

class Envirobly::Git::CommitTest < TestCase
  def setup
    @working_dir = Dir.mktmpdir
    `#{init_repository_script}`
    assert $?.success?
    @commits = `GIT_DIR=#{@working_dir}/.git git log --reflog --pretty=format:"%H"`.lines.map(&:chomp)
    # puts @commits.inspect
    # assert_equal 2, @commits.size
  end

  def teardown
    FileUtils.rm_rf @working_dir
  end

  def test_exists_when_not_a_git_object
    commit = Envirobly::Git::Commit.new("not-a-git-object", working_dir: @working_dir)
    refute commit.exists?
  end

  def test_exists_when_ref_does_not_exist
    commit = Envirobly::Git::Commit.new("5b30cdac88626750ad840f11d86f56a3c89d2180", working_dir: @working_dir)
    refute commit.exists?
  end

  def test_ref_otputs_full_hash_when_given_short_one
    commit = Envirobly::Git::Commit.new(@commits.first.slice(0, 7), working_dir: @working_dir)
    assert_equal @commits.first, commit.ref
  end

  def test_ref_otputs_object_hash_when_given_tag
    commit = Envirobly::Git::Commit.new("v1", working_dir: @working_dir)
    assert_equal @commits.first, commit.ref
  end

  def test_exists_with_existing_ref
    commit = Envirobly::Git::Commit.new(@commits.first, working_dir: @working_dir)
    assert commit.exists?
  end

  def test_message
    commit = Envirobly::Git::Commit.new(@commits.first, working_dir: @working_dir)
    assert_equal "a", commit.message
  end

  def test_time
    commit = Envirobly::Git::Commit.new(@commits.first, working_dir: @working_dir)
    assert_kind_of Time, commit.time
  end

  def test_config_content_when_there_is_no_config
    skip "TODO: Fails weirdly"
    commit = Envirobly::Git::Commit.new(@commits.first, working_dir: @working_dir)
    assert_empty commit.config_content
  end

  def test_config_content_with_config_present
    commit = Envirobly::Git::Commit.new(@commits[1], working_dir: @working_dir)
    assert_equal "hi\n", commit.config_content
  end

  def test_objects_with_checksum_at_does_not_contain_config_file
    skip "TODO"
  end

  private
    def init_repository_script
      <<~BASH
        cd #{@working_dir}
        git init
        echo "a" > a.txt
        git add .
        git commit -m "a"
        git tag v1

        mkdir .envirobly
        echo "hi" > .envirobly/project.yml
        git add .
        git commit -m "config"
      BASH
    end
end
