require "time"

class Envirobly::Git::Commit
  def initialize(ref, working_dir: Dir.getwd)
    @ref = ref
    @working_dir = working_dir
  end

  def exists?
    run(%{cat-file -t #{@ref}}).strip == "commit"
  end

  def ref
    @normalized_ref ||= run(%{rev-parse #{@ref}}).strip
  end

  def message
    run(%{log #{@ref} -n1 --pretty=%B}).strip
  end

  def time
    Time.parse run(%{log #{@ref} -n1 --date=iso --pretty=format:"%ad"})
  end

  private
    def run(cmd)
      `GIT_WORK_TREE="#{@working_dir}" GIT_DIR="#{@working_dir}/.git" git #{cmd}`
    end
end
