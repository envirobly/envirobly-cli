require_relative "lib/envirobly/version"

Gem::Specification.new do |spec|
  spec.name        = "envirobly"
  spec.version     = Envirobly::VERSION
  spec.authors     = [ "Robert Starsi" ]
  spec.email       = "klevo@klevo.sk"
  spec.homepage    = "https://github.com/envirobly/envirobly-cli"
  spec.summary     = "Envirobly command line interface"
  spec.license     = "MIT"

  spec.files = Dir[ "lib/**/*", "LICENSE" ]
  spec.executables = %w[ envirobly ]

  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "zeitwerk", "~> 2.6"
  # spec.add_dependency "aws-sdk-s3", "~> 1.141"

  # .rbenv/versions/3.3.5/lib/ruby/3.3.0/json/generic_object.rb:2: warning: ostruct was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.5.0.
  spec.add_dependency "ostruct", "~> 0.1.0"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "railties"
end
