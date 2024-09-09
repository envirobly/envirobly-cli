require "time"

class Envirobly::Git::Commit
  def initialize(ref)
    @ref = ref
  end

  def exists?
    `git cat-file -t #{@ref}`.strip == "commit"
  end

  def ref
    @normalized_ref ||= `git rev-parse #{@ref}`.strip
  end

  def message
    `git log #{@ref} -n1 --pretty=%B`.strip
  end

  def time
    Time.parse `git log #{@ref} -n1 --date=iso --pretty=format:"%ad"`
  end
end
