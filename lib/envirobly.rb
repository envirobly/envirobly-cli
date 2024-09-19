module Envirobly
end

require "zeitwerk"
require "core_ext"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/core_ext.rb")
loader.setup
loader.eager_load
