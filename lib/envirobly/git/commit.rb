class Envirobly::Git::Commit
  def initialize(ref)
    @ref = ref
  end

  def exists?
    `git cat-file -t #{@ref}`.chomp("") == "commit"
  end

  def ref
    @normalized_ref ||= `git rev-parse #{@ref}`.chomp("")
  end

  def message
    `git log #{@ref} -n1 --pretty=%B`.chomp("")
  end

  def time
    Time.parse `git log #{@ref} -n1 --date=iso --pretty=format:"%ad"`
  end
end
