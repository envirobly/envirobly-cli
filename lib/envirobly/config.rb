# frozen_string_literal: true

class Envirobly::Config
  DIR = ".envirobly"
  BASE = "deploy.yml"
  OVERRIDES_PATTERN = /deploy\.([a-z0-9\-_]+)\.yml/i

  def initialize(dir = DIR)
    @dir = Pathname.new dir
  end

  def configs
    Dir.entries(@dir).map do |file|
      path = File.join(@dir, file)

      next unless File.file?(path) && config_file?(file)

      [ "#{DIR}/#{file}", ERB.new(File.read(path)).result ]
    end.compact.to_h
  end

  private
    def config_file?(file)
      file == BASE || file.match?(OVERRIDES_PATTERN)
    end
end
