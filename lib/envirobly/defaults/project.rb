# frozen_string_literal: true

class Envirobly::Defaults::Project < Envirobly::Default
  def self.file = "project.yml"
  def self.regexp = /projects\/(\d+)/
end
