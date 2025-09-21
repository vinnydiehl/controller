class Aircraft
  attr_accessor :position, :path

  # Pixels/frame
  SPEED_PX = AIRCRAFT_SPEED / 60.0

  def initialize
    # Hardcoded start position for now
    @position = [250.0, 500.0]
    # Array of "waypoints" which connect to form the path the
    # aircraft will follow
    @path = []

    # Degrees. No unfortunately this doesn't align with compass heading.
    # Not that it matters it just bugs me slightly
    # 0 = right, 90 = up, 180 = left, 270 = down
    @heading = 0.0
  end

  def tick
    if @path.any?
      target = @path.first
      dist = Geometry.distance(@position, target)

      if dist <= SPEED_PX
        # Snap to waypoint
        @heading = target.angle_from(@position)
        @position = target
        # Next waypoint
        @path.shift
      else
        # Step toward waypoint
        @heading = target.angle_from(@position)
        move_along_heading
      end
    else
      # No path, keep flying straight using last heading
      move_along_heading
    end
  end

  def rect
    {
      x: @position.x - AIRCRAFT_RADIUS,
      y: @position.y - AIRCRAFT_RADIUS,
      w: AIRCRAFT_SIZE, h: AIRCRAFT_SIZE,
    }
  end

  def sprite
    {
      **rect,
      # Placeholder
      path: "sprites/circle/blue.png",
      angle: @heading,
    }
  end

  private

  def move_along_heading
    @position = Geometry.vec2_add(
      @position,
      [
        Math.cos(@heading.to_radians) * SPEED_PX,
        Math.sin(@heading.to_radians) * SPEED_PX,
      ],
    )
  end
end
