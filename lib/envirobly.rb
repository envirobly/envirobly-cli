module Envirobly
end

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load
