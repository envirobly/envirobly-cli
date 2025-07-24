# frozen_string_literal: true

class Envirobly::Git
  def initialize(working_dir = Dir.getwd)
    @working_dir = working_dir
  end

  OUTPUT = Struct.new :stdout, :stderr, :exit_code, :success?
  def git(cmd, chdir: @working_dir)
    Open3.popen3("git #{cmd}", chdir:) do |stdin, stdout, stderr, thread|
      stdin.close
      OUTPUT.new stdout.read, stderr.read, thread.value.exitstatus, thread.value.success?
    end
  end

  def current_branch
    git("branch --show-current").stdout.strip
  end
end
