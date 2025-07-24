# frozen_string_literal: true

require "thor"

class Envirobly::Base < Thor
  def self.exit_on_failure?
    true
  end
end
