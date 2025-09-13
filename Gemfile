# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :rubocop do
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "testerobly", "~> 1.0.0", github: "klevo/testerobly"
end
