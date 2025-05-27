class Envirobly::Numeric < Numeric
  def initialize(value, short: false)
    @value = value
    @short = short
  end

  def to_s
    if @short
      @value.to_s.delete_suffix(".0")
    else
      "%.2f" % @value
    end
  end
end
