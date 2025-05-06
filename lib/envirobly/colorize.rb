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
end
