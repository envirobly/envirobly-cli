class Array
  alias_method :blank?, :empty?

  def present?
    !empty?
  end

  def second
    self[1]
  end

  def third
    self[2]
  end

  def fourth
    self[3]
  end

  def fifth
    self[4]
  end
end

class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : false
  end

  def present?
    !blank?
  end

  def presence
    self if present?
  end
end

class NilClass
  def blank?
    true
  end

  def present?
    false
  end
end

class FalseClass
  def blank?
    true
  end

  def present?
    false
  end
end

class TrueClass
  def blank?
    false
  end

  def present?
    true
  end
end

class Hash
  alias_method :blank?, :empty?

  def present?
    !empty?
  end
end

class Symbol
  alias_method :blank?, :empty?

  def present?
    !empty?
  end
end

class String
  def blank?
    strip.empty?
  end

  def present?
    !blank?
  end
end

class Numeric
  def blank?
    false
  end

  def present?
    true
  end
end

class Time
  def blank?
    false
  end

  def present?
    true
  end
end
