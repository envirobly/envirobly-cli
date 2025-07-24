# frozen_string_literal: true

class Envirobly::Git::Unstaged < Envirobly::Git::Commit
  def initialize(working_dir: Dir.getwd)
    @working_dir = working_dir
  end

  def file_exists?(path)
    File.exist? path
  end

  def dir_exists?(path)
    Dir.exist? path
  end

  def file_content(path)
    File.read path
  end
end
