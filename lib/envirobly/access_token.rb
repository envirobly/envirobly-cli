require "fileutils"
require "pathname"

class Envirobly::AccessToken
  class << self
    def destroy
      if File.exist?(path)
        FileUtils.rm path
      end
    end

    def dir
      if ENV["XDG_CONFIG_HOME"]
        Pathname.new(ENV["XDG_CONFIG_HOME"]).join("envirobly")
      else
        Pathname.new(Dir.home).join(".envirobly")
      end
    end

    def path
      dir.join "access_token"
    end
  end

  def initialize(token = ENV["ENVIROBLY_ACCESS_TOKEN"].presence)
    if token.blank? && File.exist?(self.class.path)
      @token = File.read(self.class.path)
    else
      @token = token
    end
  end

  def save
    FileUtils.mkdir_p self.class.dir
    File.write self.class.path, @token
    File.chmod 0600, self.class.path
    puts "Access token saved to #{self.class.path}"
  end

  def as_http_bearer
    "Bearer #{@token}"
  end
end
