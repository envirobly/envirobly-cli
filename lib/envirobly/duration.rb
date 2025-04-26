require "benchmark"

class Envirobly::Duration
  GREEN  = "\e[32m"
  RED    = "\e[31m"
  YELLOW = "\e[33m"
  BLUE   = "\e[34m"
  RESET  = "\e[0m"
  BOLD   = "\e[1m"
  FAINT  = "\e[2m"

  class << self
    def measure
      duration = Benchmark.measure do
        yield
      end

      puts " #{GREEN}✔#{RESET} #{FAINT}#{format_duration duration.real}#{RESET}"
    end

    def format_duration(duration)
      total_seconds = duration.to_i
      minutes = (total_seconds / 60).floor
      seconds = (total_seconds % 60).ceil
      result = [ "#{seconds}s" ]
      result.prepend "#{minutes}m" if minutes > 0
      result.join
    end
  end
end
