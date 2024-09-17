require "test_helper"

class Envirobly::ConfigTest < TestCase
  def setup
    @working_dir = Dir.mktmpdir
    `#{init_repository_script}`
    assert $?.success?
    @commits = `GIT_DIR=#{@working_dir}/.git git log --reflog --pretty=format:"%H"`.lines
    assert_equal 1, @commits.size
  end

  def teardown
    FileUtils.rm_rf @working_dir
  end

  def test_one
    commit = Envirobly::Git::Commit.new @commits.first, working_dir: @working_dir
    config = Envirobly::Config.new commit, working_dir: @working_dir
    assert_equal config_yml, config.raw
  end

  private
    def config_yml
      <<~YAML
        services:
          db:
            type: postgres
            instance_type: t4g.small
      YAML
    end

    def init_repository_script
      <<~BASH
        cd #{@working_dir}
        git init

        mkdir .envirobly
        cat <<EOT > .envirobly/project.yml
        #{config_yml.chomp}
        EOT

        git add .
        git commit -m "config"
      BASH
    end
end
