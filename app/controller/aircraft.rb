class Aircraft
  attr_accessor :position, :path, :cleared_to_land, :landed

  # Pixels/frame
  SPEED_PX = AIRCRAFT_SPEED / 60.0
  # Degrees/frame for smoothing sprite angle
  ANGLE_SMOOTHING_RATE = 5.0

  def initialize
    # Array of "waypoints" which connect to form the path the
    # aircraft will follow
    @path = []

    @screen = $gtk.args.grid.rect

    # Random spawn along edges
    @position = {
      left:   [-SPAWN_PADDING, rand(@screen.h)],
      right:  [@screen.w + SPAWN_PADDING, rand(@screen.h)],
      bottom: [rand(@screen.w), -SPAWN_PADDING],
      top:    [rand(@screen.w), @screen.h + SPAWN_PADDING],
    }[[:left, :right, :top, :bottom].sample]

    # Direction the aircraft is moving, in degrees.
    # No unfortunately this doesn't align with compass degrees.
    # Not that it matters it just bugs me slightly...
    #
    # 0 = right, 90 = up, 180 = left, 270 = down
    #
    # Spawns pointing towards the center.
    @course = @position.angle_to([@screen.w / 2, @screen.h / 2])
    # Angle the front of the aircraft sprite is facing, eases
    # towards the course if they become offset.
    @heading = @course

    @cleared_to_land = false
    @landed = false

    # The aircraft begins off the screen. This will be set to true
    # once it enters the screen, and will be used in the future for
    # turning the aircraft around if it hits the edge of the screen.
    @offscreen = true
  end

  def tick
    if @offscreen && @position.inside_rect?(@screen)
      @offscreen = false
    end

    if @path.any?
      target = @path.first
      dist = Geometry.distance(@position, target)

      if dist <= SPEED_PX
        # Snap to waypoint
        @course = target.angle_from(@position)
        @position = target
        # Next waypoint
        @path.shift
      else
        # Step toward waypoint
        @course = target.angle_from(@position)
        move_along_heading
      end

      if @path.empty? && @cleared_to_land
        @landed = true
      end
    else
      # No path, keep flying straight using last heading
      move_along_heading
    end

    handle_screen_edge_collision
    ease_heading
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
        scale_quality_enum: 2,
        **(@cleared_to_land ? CLEARED_TO_LAND_PATH_COLOR : PATH_COLOR),
      }
    end
  end

  private

  def move_along_heading
    @position = Geometry.vec2_add(
      @position,
      [
        Math.cos(@course.to_radians) * SPEED_PX,
        Math.sin(@course.to_radians) * SPEED_PX,
      ],
    )
  end

  def handle_screen_edge_collision
    return if @offscreen

    bounced = false

    # Left/right walls
    if @position.x <= 0
      @position.x = 0
      @course = 180 - @course
      bounced = true
    elsif @position.x >= @screen.w
      @position.x = @screen.w
      @course = 180 - @course
      bounced = true
    end

    # Top/bottom walls
    if @position.y <= 0
      @position.y = 0
      @course = -@course
      bounced = true
    elsif @position.y >= @screen.h
      @position.y = @screen.h
      @course = -@course
      bounced = true
    end

    if bounced
      # Normalize angle
      @course %= 360
      # If path extends off the screen it will get stuck on the edge,
      # so reset it
      @path = []
    end
  end

  # Ease the heading toward the course
  def ease_heading
    delta = (@course - @heading) % 360
    # Shortest path
    delta -= 360 if delta > 180

    if delta.abs <= ANGLE_SMOOTHING_RATE
      @heading = @course
    else
      @heading += ANGLE_SMOOTHING_RATE * (delta.positive? ? 1 : -1)
      @heading %= 360
    end
  end
end
