class Symbol
  def to_capitalized_str
    to_s.split("_").map(&:capitalize).join(" ")
  end
end
