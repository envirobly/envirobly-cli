# frozen_string_literal: true

module Envirobly
  class Name
    NAME_FORMAT = /\A[a-z0-9\-_]+\z/i
    ERROR_MESSAGE = "is limited to alphanumerical characters, dashes and undercores"

    attr_reader :error

    def initialize(name)
      @name = name
      @error = nil
    end

    def validate
      if @name =~ NAME_FORMAT
        true
      else
        @error = ERROR_MESSAGE
        false
      end
    end
  end
end
