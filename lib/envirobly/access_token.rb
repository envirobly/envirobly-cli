require "fileutils"
require "pathname"

class Envirobly::AccessToken
  def initialize(token = ENV.fetch("ENVIROBLY_ACCESS_TOKEN", nil))
    if token.nil? && File.exist?(access_token_path)
      @token = File.read(access_token_path)
    else
      @token = token
    end
  end

  def save
    FileUtils.mkdir_p config_root
    File.write access_token_path, @token
    File.chmod 0600, access_token_path
    puts "Access token saved to #{access_token_path}"
  end

  def as_http_bearer
    "Bearer #{@token}"
  end

  private
    def config_root
      if ENV["XDG_CONFIG_HOME"]
        Pathname.new(ENV["XDG_CONFIG_HOME"]).join("envirobly")
      else
        Pathname.new(Dir.home).join(".envirobly")
      end
    end

    def access_token_path
      config_root.join "access_token"
    end
end
