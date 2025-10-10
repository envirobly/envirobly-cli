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
      result = parse yaml, path

      if environ_name.present?
        override_path = Pathname.new(DIR).join("deploy.#{environ_name}.yml").to_s

        if configs.key?(override_path)
          other_yaml = configs.fetch(override_path)
          override = parse other_yaml, override_path
          result = result.deep_merge(override) if override.is_a?(Hash)
        end
      end

      @errors.empty? ? result : nil
    end

    private
      def config_file?(file)
        file == BASE || file.match?(OVERRIDES_PATTERN)
      end

      def parse(content, path)
        begin
          yaml = ERB.new(content).result
        rescue Exception => e
          @errors << { message: e.message, path: }
          return
        end

        YAML.safe_load yaml, aliases: true, symbolize_names: true, permitted_classes: [ Secret ]
      rescue Psych::Exception => e
        @errors << { message: e.message, path: }
      end
  end
end
