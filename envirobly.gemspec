# frozen_string_literal: true

require_relative "lib/envirobly/version"

Gem::Specification.new do |spec|
  spec.name        = "envirobly"
  spec.version     = Envirobly::VERSION
  spec.authors     = [ "Robert Starsi" ]
  spec.email       = "klevo@klevo.sk"
  spec.homepage    = "https://github.com/envirobly/envirobly-cli"
  spec.summary     = "Envirobly command line interface"
  spec.license     = "MIT"

  spec.files = Dir["lib/**/*", "LICENSE"]
  spec.executables = %w[ envirobly ]

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "zeitwerk", "~> 2.6"
  spec.add_dependency "aws-sdk-s3", "~> 1.182"
  spec.add_dependency "concurrent-ruby", "~> 1.3"
  spec.add_dependency "activesupport", "~> 8.0"

  spec.add_development_dependency "debug", "~> 1.10"
  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 2.7"
  spec.add_development_dependency "railties", "~> 8.0"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.1"
end
