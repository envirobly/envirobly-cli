# frozen_string_literal: true

class Envirobly::Default
  attr_accessor :shell

  def initialize(shell: nil)
    @path = File.join Envirobly::Config::DIR, "defaults", self.class.name.demodulize.downcase
    @shell = shell
  end

  def value
    if File.exist?(@path)
      cast_value File.read(@path)
    else
      nil
    end
  end

  def save(value)
    FileUtils.mkdir_p(File.dirname(@path))
    File.write(@path, value)
  end

  def save_if_none(new_value)
    return if value.present?

    save(new_value)
  end

  def require_if_none
    value || require_value
  end

  private
    def cast_value(value)
      value.to_i
    end
end
