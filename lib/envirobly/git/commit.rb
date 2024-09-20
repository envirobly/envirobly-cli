require "time"
require "open3"

class Envirobly::Git::Commit
  def initialize(ref, working_dir: Dir.getwd)
    @ref = ref
    @working_dir = working_dir
  end

  def exists?
    git(%(cat-file -t #{@ref})).stdout.strip == "commit"
  end

  def ref
    @normalized_ref ||= git(%(rev-parse #{@ref})).stdout.strip
  end

  def message
    git(%(log #{@ref} -n1 --pretty=%B)).stdout.strip
  end

  def time
    Time.parse git(%(log #{@ref} -n1 --date=iso --pretty=format:"%ad")).stdout
  end

  def file_exists?(path)
    git(%(cat-file -t #{@ref}:#{path})).stdout.strip == "blob"
  end

  def dir_exists?(path)
    git(%(cat-file -t #{@ref}:#{path})).stdout.strip == "tree"
  end

  def file_content(path)
    git(%(show #{@ref}:#{path})).stdout
  end

  def objects_with_checksum_at(path)
    git(%{ls-tree #{@ref} --format='%(objectname) %(path)' #{path}}).stdout.lines.map(&:chomp).
      reject { _1.split(" ").last == Envirobly::Config::DIR }
  end

  def archive_and_upload(bucket:, credentials:)
    git(%(archive --format=tar.gz #{ref} | #{credentials.as_inline_env_vars} aws s3 cp - #{archive_uri(bucket)}))
  end

  private
    OUTPUT = Struct.new :stdout, :stderr, :exit_code, :success?
    def git(cmd)
      Open3.popen3("git #{cmd}", chdir: @working_dir) do |stdin, stdout, stderr, thread|
        stdin.close
        OUTPUT.new stdout.read, stderr.read, thread.value.exitstatus, thread.value.success?
      end
    end

    def archive_uri(bucket)
      "s3://#{bucket}/#{ref}.tar.gz"
    end
end
