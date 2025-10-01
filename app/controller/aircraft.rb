class Aircraft
  attr_accessor *%i[position path cleared_to_land landed
                    type speed runway_type vtol]
  attr_reader :departing

  # Degrees/frame for smoothing sprite angle
  ANGLE_SMOOTHING_RATE = 5.0

  def initialize(position:, type:, speed:, runway:, vtol:,
                 course: nil, departing: nil)
    @position, @type, @speed, @runway_type, @vtol, @course, @departing =
      position, type, speed, runway, vtol, course, departing

    # Pixels/frame
    @speed_px = @speed / 60.0

    # Array of "waypoints" which connect to form the path the
    # aircraft will follow
    @path = []

    @screen = $gtk.args.grid.rect

    # Direction the aircraft is moving, in degrees.
    # No unfortunately this doesn't align with compass degrees.
    # Not that it matters it just bugs me slightly...
    #
    # 0 = right, 90 = up, 180 = left, 270 = down
    #
    # Spawns pointing towards the center.
    @course ||= @position.angle_to([@screen.w / 2, @screen.h / 2])
    # Angle the front of the aircraft sprite is facing, eases
    # towards the course if they become offset.
    @heading = @course

    @cleared_to_land = false
    @landed = false

    # The aircraft begins off the screen. This will be set to false
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

      if dist <= @speed_px
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

  # Hitbox for a collision
  def hitbox
    Geometry.rect_to_circle(rect).tap { |c| c[:radius] /= 1.5 }
  end

  # Hitbox to produce a warning that aircraft are about to collide
  def warning_hitbox
    # Scale size of warning hitbox with aircraft speed
    scale_factor = ((@speed + 5) / 10).clamp(2, 3)
    Geometry.rect_to_circle(rect).tap { |c| c[:radius] *= scale_factor }
  end

  def sprite
    sprites = [
      {
        **rect,
        path: "sprites/aircraft/#{type}.png",
        angle: @heading,
        **RUNWAY_COLORS[@runway_type],
      },
    ]

    if @departing
      sprites << {
        x: @position.x, y: @position.y,
        w: 8, h: 20,
        path: "sprites/symbology/direction_large.png",
        angle: ANGLE[@departing],
        anchor_x: -2,
        anchor_y: 0.5,
        angle_anchor_x: -2,
        angle_anchor_y: 0.5,
      }
    end

    sprites
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
        Math.cos(@course.to_radians) * @speed_px,
        Math.sin(@course.to_radians) * @speed_px,
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
