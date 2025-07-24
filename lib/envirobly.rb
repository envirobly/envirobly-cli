# frozen_string_literal: true

module Envirobly
end

require "active_support"
require "active_support/core_ext"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load
