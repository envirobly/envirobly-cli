# frozen_string_literal: true

class Envirobly::Default
  attr_accessor :shell

  def self.key = "url"

  def initialize(shell: nil)
    @path = File.join Envirobly::Config::DIR, "defaults", self.class.file
    @shell = shell
  end

  def id
    if File.exist?(@path)
      content = YAML.safe_load_file(@path)

      if content[self.class.key] =~ self.class.regexp
        return cast_id($1)
      end
    end

    nil
  end

  def save(url)
    unless url =~ self.class.regexp
      raise ArgumentError, "'#{url}' must match #{self.class.regexp}"
    end

    FileUtils.mkdir_p(File.dirname(@path))
    content = YAML.dump({ self.class.key => url })
    File.write(@path, content)
  end

  def save_if_none(url)
    return if id.present?

    save(url)
  end

  def require_if_none
    id || require_id
  end

  private
    def cast_id(value)
      value.to_i
    end
end
