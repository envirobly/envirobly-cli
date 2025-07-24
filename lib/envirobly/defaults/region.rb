# frozen_string_literal: true

class Envirobly::Defaults::Region < Envirobly::Default
  include Envirobly::Colorize

  def self.file = "region.yml"
  def self.regexp = /([a-z0-9\-)]+)/
  def self.key = "code"

  def require_id
    api = Envirobly::Api.new
    response = api.list_regions

    shell.say "Choose default project region to deploy to:"
    shell.print_table [ [ "Name", "Location", "Group" ] ] +
      response.object.pluck("code", "title", "group_title"), borders: true

    code = nil
    limited_to = response.object.pluck("code")

    while code.nil?
      begin
        code = shell.ask("Type in the region name:", default: "us-east-1")
      rescue Interrupt
        shell.say_error "Cancelled"
        exit
      end

      unless code.in?(limited_to)
        shell.say_error "'#{code}' is not a supported region, please try again"
        code = nil
      end
    end

    save code

    shell.say "Region '#{id}' set as project default "
    shell.say green_check

    id
  end

  private
    def cast_id(value)
      value
    end
end
