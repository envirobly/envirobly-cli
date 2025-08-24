# frozen_string_literal: true

class Envirobly::Defaults::Region < Envirobly::Default
  include Envirobly::Colorize

  def require_value
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

    shell.say "Region '#{code}' set as project default "
    shell.say green_check

    code
  end

  private
    def cast_value(value)
      value.to_s
    end
end
