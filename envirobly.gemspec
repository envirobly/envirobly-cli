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

  spec.add_development_dependency "debug", "~> 1.8"
  spec.add_development_dependency "minitest", "~> 5.21"
end
