class Aircraft
  attr_accessor :position, :path

  # Pixels/frame
  SPEED_PX = AIRCRAFT_SPEED / 60.0

  def initialize
    # Array of "waypoints" which connect to form the path the
    # aircraft will follow
    @path = []

    # Random spawn along edges
    screen_w, screen_h = $gtk.args.grid.w, $gtk.args.grid.h
    side =

    @position = {
      left: [-SPAWN_PADDING, rand(screen_h)],
      right: [screen_w + SPAWN_PADDING, rand(screen_h)],
      bottom: [rand(screen_w), -SPAWN_PADDING],
      top: [rand(screen_w), screen_h + SPAWN_PADDING],
    }[[:left, :right, :top, :bottom].sample]

    # Angle pointing toward center. Angle is in degrees.
    # No unfortunately this doesn't align with compass heading.
    # Not that it matters it just bugs me slightly
    # 0 = right, 90 = up, 180 = left, 270 = down
    @heading = @position.angle_to([screen_w / 2, screen_h / 2])
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

  def path_primitives
    return if @path.empty?

    [[@position.x, @position.y], *@path].each_cons(2).map do |(x, y), (x2, y2)|
      {
        x: x, y: y,
        x2: x2, y2: y2,
        **PATH_COLOR,
      }
    end
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
