class Numeric
  def minutes
    self * 60 * 60
  end

  def to_seconds
    (self / 60).ceil
  end
end
