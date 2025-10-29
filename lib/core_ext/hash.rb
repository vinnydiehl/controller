class Hash
  # Shifts the value of a color towards white. +intensity+ is a value
  # between 0 and 1, where 0 is the original color and 1 is white.
  #
  # If the color is blue-dominant, reduce the effective intensity so
  # very-blue colors don't simply wash into white.
  #
  # Requires a Hash with :r, :g, and :b keys.
  def glow(intensity)
    r, g, b = values_at(:r, :g, :b)

    # How dominant blue is relative to the brightest channel
    blue_dom = b / [r, g, b].max
    # Scale intensity down based on blue dominance
    blue_damping = 0.4
    intensity *= 1.0 - (blue_dom * blue_damping)

    transform_values do |n|
      n += ((255 - n) * intensity).floor
    end
  end
end
