# frozen_string_literal: true

module Envirobly
  class Secret
    attr_reader :plain

    def initialize(value)
      @plain = value
    end

    def init_with(coder)
      @plain = coder.scalar
    end

    def encode_with(coder)
      coder.scalar = @plain
    end

    def to_s
      "[SECRET]"
    end

    def ==(other)
      other.is_a?(Secret) && other.plain == plain
    end
  end
end
