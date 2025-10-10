# frozen_string_literal: true

module Envirobly
  class Config
    DIR = ".envirobly"
    BASE = "deploy.yml"
    OVERRIDES_PATTERN = /deploy\.([a-z0-9\-_]+)\.yml/i

    attr_reader :errors

    def initialize(dir = DIR)
      @dir = Pathname.new dir
      @errors = []
    end

    def configs
      Dir.entries(@dir).map do |file|
        path = File.join(@dir, file)

        next unless File.file?(path) && config_file?(file)

        [ "#{DIR}/#{file}", File.read(path) ]
      end.compact.to_h
    end

    def merge(environ_name = nil)
      path = Pathname.new(DIR).join(BASE).to_s
      yaml = configs.fetch(path)
      base = YAML.safe_load ERB.new(yaml).result, aliases: true, symbolize_names: true

      if environ_name.present?
        override_path = Pathname.new(DIR).join("deploy.#{environ_name}.yml").to_s

        if configs.key?(override_path)
          other_yaml = configs.fetch(override_path)
          override = YAML.safe_load ERB.new(other_yaml).result, aliases: true, symbolize_names: true
          return base.deep_merge(override)
        end
      end

      base
    end

    private
      def config_file?(file)
        file == BASE || file.match?(OVERRIDES_PATTERN)
      end
  end
end
