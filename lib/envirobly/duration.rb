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
    def measure(message = nil)
      measurement = Benchmark.measure do
        yield
      end

      duration = format_duration(measurement)

      if message.nil?
        puts " #{GREEN}✔#{RESET} #{FAINT}#{duration}#{RESET}"
      else
        puts sprintf(message, duration)
      end
    end

    def format_duration(tms)
      ms = (tms.real * 1000).to_i

      if ms >= 60_000
        minutes = ms / 60_000
        seconds = (ms % 60_000) / 1000
        sprintf("%dm%ds", minutes, seconds)
      elsif ms >= 1000
        seconds = ms / 1000
        sprintf("%ds", seconds)
      else
        sprintf("%dms", ms)
      end
    end
  end
end
