class Envirobly::Defaults::Account < Envirobly::Default
  include Envirobly::Colorize

  def self.file = "account.yml"
  def self.regexp = /accounts\/(\d+)/

  def require_id
    api = Envirobly::Api.new
    accounts = api.list_accounts

    if accounts.object.blank?
      shell.say_error "Please connect an AWS account to your Envirobly account first."
      exit 1
    end

    account = accounts.object.first
    id = account["id"]

    if accounts.object.size > 1
      puts "Choose default account to deploy this project to:"

      data = [ [ "ID", "Name", "AWS number", "URL" ] ] +
        accounts.object.pluck("id", "name", "aws_id", "url")

      shell.print_table data, borders: true

      limited_to = accounts.object.pluck("id").map(&:to_s)

      begin
        id = shell.ask("Type in the account ID:", limited_to:).to_i
      rescue Interrupt
        shell.say_error "Cancelled"
        exit
      end

      account = accounts.object.find { |a| a["id"] == id }
    end

    save account["url"]

    shell.say "Account ##{id} set as project default "
    shell.say green_check

    id
  end
end
