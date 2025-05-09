class Envirobly::Default
  attr_accessor :shell

  def initialize(shell: nil)
    @path = File.join Envirobly::Config::DIR, "defaults", self.class.file
    @shell = shell
  end

  def id
    if File.exist?(@path)
      content = YAML.safe_load_file(@path)

      if content["url"] =~ self.class.regexp
        return $1.to_i
      end
    end

    nil
  end

  def save(url)
    unless url =~ self.class.regexp
      raise ArgumentError, "'#{url}' must match #{self.class.regexp}"
    end

    FileUtils.mkdir_p(File.dirname(@path))
    content = YAML.dump({ "url" => url })
    File.write(@path, content)
  end

  def save_if_none(url)
    return if id.present?

    save(url)
  end
end
