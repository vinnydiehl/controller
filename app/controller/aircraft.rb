class Aircraft
  attr_accessor :position, :path

  def initialize
    @position = [250, 500]
    @path = []
    @speed = 50
  end

  def tick
    return if @path.empty?

    # Convert to pixels per frame (assuming 60fps)
    movement_left = @speed / 60.0

    while movement_left > 0 && @path.any?
      target = @path.first
      dx = target[0] - @position[0]
      dy = target[1] - @position[1]
      dist = Math.sqrt(dx * dx + dy * dy)

      if dist <= movement_left
        @position = target
        @path.shift
        movement_left -= dist
      else
        ratio = movement_left / dist
        @position = [
          @position[0] + dx * ratio,
          @position[1] + dy * ratio
        ]
        movement_left = 0
      end
    end
  end

  def rect
    {
      x: @position.x - AIRCRAFT_RADIUS,
      y: @position.y - AIRCRAFT_RADIUS,
      w: AIRCRAFT_SIZE, h: AIRCRAFT_SIZE,
    }
  end

  # Returns the angle for the sprite based on which direction
  # the aircraft is heading.
  def angle
    return 0 if @path.empty?

    dx = @path.first[0] - @position[0]
    dy = @path.first[1] - @position[1]
    radians = Math.atan2(dy, dx)
    degrees = radians * 180.0 / Math::PI

    # Normalize to 0–360
    degrees % 360
  end

  # Returns a sprite primitive Hash for the aircraft.
  def sprite
    {
      **rect,
      path: "sprites/circle/blue.png",
      angle: angle
    }
  end
end
