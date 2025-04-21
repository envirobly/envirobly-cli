require "time"
require "open3"

class Envirobly::Git::Commit < Envirobly::Git
  EXECUTABLE_FILE_MODE = "100755"
  SYMLINK_FILE_MODE = "120000"

  attr_reader :working_dir

  def initialize(ref, working_dir: Dir.getwd)
    @ref = ref
    super working_dir
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
    suffix = path.end_with?("/") ? nil : "/"
    git(%(cat-file -t #{@ref}:#{path}#{suffix})).stdout.strip == "tree"
  end

  def file_content(path)
    git(%(show #{@ref}:#{path})).stdout
  end

  def object_tree(ref: @ref, chdir: @working_dir)
    objects = {}
    objects[chdir] = []

    git(%(ls-tree -r #{ref}), chdir:).stdout.lines.each do |line|
      mode, type, object_hash, path = line.split(/\s+/)

      if type == "commit"
        objects.merge! object_tree(ref: object_hash, chdir: File.join(chdir, path))
      else
        objects[chdir] << [ mode, type, object_hash, path ]
      end
    end

    objects
  end

  # @deprecated
  def objects_with_checksum_at(path)
    git(%{ls-tree #{@ref} --format='%(objectname) %(path)' #{path}}).stdout.lines.map(&:chomp).
      reject { _1.split(" ").last == Envirobly::Configs::DIR }
  end
end
