require "test_helper"

class Envirobly::Git::CommitTest < TestCase
  def setup
    @working_dir = Dir.mktmpdir
    `#{init_repository_script}`
    assert $?.success?
    @commits = `GIT_DIR=#{@working_dir}/.git git log --reflog --pretty=format:"%H"`.lines
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

  def test_exists_with_existing_ref
    commit = Envirobly::Git::Commit.new(@commits.first, working_dir: @working_dir)
    assert commit.exists?
  end

  private
    def init_repository_script
      <<~BASH
        cd #{@working_dir}
        git init
        echo "a" > a.txt
        git add .
        git commit -m "a"
      BASH
    end
end
