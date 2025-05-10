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

    begin
      code = shell.ask("Type in the region name:", limited_to: response.object.map { |r| r["code"] })
    rescue Interrupt
      shell.say_error "Cancelled"
      exit
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
