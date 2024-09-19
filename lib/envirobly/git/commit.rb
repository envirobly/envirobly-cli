require "time"
require "open3"

class Envirobly::Git::Commit
  def initialize(ref, working_dir: Dir.getwd)
    @ref = ref
    @working_dir = working_dir
  end

  def exists?
    run(%(cat-file -t #{@ref})).strip == "commit"
  end

  def ref
    @normalized_ref ||= run(%(rev-parse #{@ref})).strip
  end

  def message
    run(%(log #{@ref} -n1 --pretty=%B)).strip
  end

  def time
    Time.parse run(%(log #{@ref} -n1 --date=iso --pretty=format:"%ad"))
  end

  def file_content(path)
    run %(show #{@ref}:#{path})
  end

  def objects_with_checksum_at(path)
    run(%{ls-tree #{@ref} --format='%(objectname) %(path)' #{path}}).lines.map(&:chomp).
      reject { _1.split(" ").last == Envirobly::Config::DIR }
  end

  def archive_and_upload(bucket:, credentials:)
    `GIT_WORK_TREE="#{@working_dir}" GIT_DIR="#{@working_dir}/.git" git archive --format=tar.gz #{ref} | #{credentials.as_inline_env_vars} aws s3 cp - #{archive_uri(bucket)}`
    $?.success?
  end

  private
    def run(cmd)
      @stdout = @stderr = @exit_code = @success = nil
      full_cmd = %(GIT_WORK_TREE="#{@working_dir}" GIT_DIR="#{@working_dir}/.git" git #{cmd})
      Open3.popen3(full_cmd) do |stdin, stdout, stderr, thread|
        stdin.close
        @stdout = stdout.read
        @stderr = stderr.read
        @exit_code = thread.value.exitstatus
        @success = thread.value.success?
      end
      puts @stderr
      @stdout
    end

    def archive_uri(bucket)
      "s3://#{bucket}/#{ref}.tar.gz"
    end
end
