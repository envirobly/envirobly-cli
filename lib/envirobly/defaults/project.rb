# frozen_string_literal: true

class Envirobly::Defaults::Project < Envirobly::Default
  def self.name
    File.basename(Dir.pwd)
  end
end
