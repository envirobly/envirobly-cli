require "benchmark"

class Envirobly::Duration
  class << self
    def measure
      duration = Benchmark.measure do
        yield
      end

      puts " OK #{format_duration duration.real}"
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
