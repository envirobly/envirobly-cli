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
end
