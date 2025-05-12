require "fileutils"
require "pathname"

class Envirobly::AccessToken
  def initialize(token = ENV.fetch("ENVIROBLY_ACCESS_TOKEN", nil))
    if token.nil? && File.exist?(path)
      @token = File.read(path)
    else
      @token = token
    end
  end

  def save
    FileUtils.mkdir_p dir
    File.write path, @token
    File.chmod 0600, path
    puts "Access token saved to #{path}"
  end

  def as_http_bearer
    "Bearer #{@token}"
  end

  def destroy
    if File.exist?(path)
      FileUtils.rm path
    end
  end

  private
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
