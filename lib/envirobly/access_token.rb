# frozen_string_literal: true

require "fileutils"
require "pathname"

class Envirobly::AccessToken
  include Envirobly::Colorize

  attr_reader :shell

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

  def initialize(token = ENV["ENVIROBLY_ACCESS_TOKEN"].presence, shell: nil)
    @shell = shell

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
  end

  def as_http_bearer
    "Bearer #{@token}"
  end

  def require!
    return if @token.present?

    shell.say "This action requires you to be signed in."
    shell.say "Please visit https://on.envirobly.com/profile/access_tokens"
    shell.say "to generate an access token and then paste it in here."
    shell.say

    set
  end

  def set
    @token = nil

    while @token.blank?
      begin
        @token = shell.ask("Access Token:", echo: false)
      rescue Interrupt
        shell.say
        shell.say_error "Cancelled"
        exit
      end

      api = Envirobly::Api.new(access_token: self, exit_on_error: false)

      # TODO: Eventually replace with custom `whoami` API that returns name, email...
      if api.list_accounts.success?
        save
        shell.say
        shell.say "Successfully signed in "
        shell.say green_check
      else
        shell.say
        shell.say_error "This token is invalid. Please try again"
        @token = nil
      end
    end
  end
end
