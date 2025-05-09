module Envirobly::Colorize
  GREEN  = "\e[32m"
  RED    = "\e[31m"
  YELLOW = "\e[33m"
  BLUE   = "\e[34m"
  RESET  = "\e[0m"
  BOLD   = "\e[1m"
  FAINT  = "\e[2m"

  def faint(text)
    [ FAINT, text, RESET ].join
  end

  def bold(text)
    [ BOLD, text, RESET ].join
  end

  def green(text)
    [ GREEN, text, RESET ].join
  end

  def yellow(text)
    [ YELLOW, text, RESET ].join
  end

  def red(text)
    [ RED, text, RESET ].join
  end

  def green_check
    green("✔")
  end

  def downwards_arrow_to_right
    "↳"
  end

  def cross
    "✖"
  end

  def display_config_errors(errors)
    puts "#{red(cross)} Config contains the following issues:"

    errors.each do |error|
      puts
      puts "  #{error["message"]}"

      if error["path"]
        puts faint("  #{downwards_arrow_to_right} #{error["path"]}")
      end
    end
  end
end
