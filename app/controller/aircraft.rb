class Aircraft
  attr_accessor *%i[position path cleared_to_land emergency
                    landed nordo type speed runway_type vtol]
  attr_reader *%i[course departing departed entry_point incoming_marker_angle]

  # Degrees/frame for smoothing sprite angle
  ANGLE_SMOOTHING_RATE = 5.0

  # Lines for the edges of the screen, the order of these matters
  # for setting the angle of the incoming marker
  SCREEN_LINES = [
    # Left
    {
      x: 0, y: 0,
      x2: 0, y2: $grid.h,
    },
    # Bottom
    {
      x: 0, y: 0,
      x2: $grid.w, y2: 0,
    },
    # Right
    {
      x: $grid.w, y: 0,
      x2: $grid.w, y2: $grid.h,
    },
    # Top
    {
      x: 0, y: $grid.h,
      x2: $grid.w, y2: $grid.h,
    },
  ]

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

    @departed = false

    unless @departing
      # We need to figure out where on the screen the aircraft is going
      # to appear based on the angle... we'll use line intersection.
      # Here's a line from aircraft to center of screen
      ac_line = {
        x: @position.x,
        y: @position.y,
        x2: @screen.w / 2, y2: @screen.h / 2,
      }

      # Now find the first intersection
      SCREEN_LINES.each_with_index do |sl, i|
        if (@entry_point = Geometry.line_intersect(sl, ac_line))
          @incoming_marker_angle = i * 90
          break
        end
      end
    end
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

    if @emergency
      @emergency -= 1
    end

    handle_screen_edge_collision
    handle_departure
    ease_heading
  end

  # Make the aircraft smoothly pathfind towards +runway+ and land there.
  def pathfind_to(runway)
    # Pixels from runway where alignment begins (longitudinal bias).
    # If the aircraft is VTOL, this is 0 as the final approach
    # course doesn't matter.
    final_dist = vtol ? 0.0 : 300.0
    # Lateral offset to shape curved approach
    curve_offset = 40
    # Bezier interpolation density
    steps = 20

    # Geometry setup
    heading_rad = runway.heading.to_radians
    runway_dir = [Math.cos(heading_rad), Math.sin(heading_rad)]
    # Perpendicular vector (left/right)
    perp_dir = [-runway_dir[1], runway_dir[0]]

    # Point behind runway along its heading (start of final approach)
    final_point = [
      runway.position.x - runway_dir[0] * final_dist,
      runway.position.y - runway_dir[1] * final_dist,
    ]

    # Determine aircraft’s side relative to runway heading (lateral bias
    # for correct curvature)
    dx, dy = position.x - runway.position.x, position.y - runway.position.y
    side = ((runway_dir[0] * dy) - (runway_dir[1] * dx)).positive? ? 1 : -1

    # Bezier control points
    dist = Geometry.distance(position, final_point)
    entry_vec = Geometry.vec2_normalize(Geometry.vec2_subtract(final_point, position))
    control_points = [
      Geometry.vec2_add(
        position,
        Geometry.vec2_add(
          Geometry.vec2_scale(entry_vec, 0.3 * dist),
          {
            x: perp_dir[0] * curve_offset * 0.8 * side,
            y: perp_dir[1] * curve_offset * 0.8 * side,
          },
        )
      ),
      {
        x: final_point[0] + perp_dir[0] * curve_offset * 0.4 * side,
        y: final_point[1] + perp_dir[1] * curve_offset * 0.4 * side,
      },
    ]

    p0 = { x: position.x, y: position.y }
    p3 = { x: runway.position.x, y: runway.position.y }

    # Cubic Bezier interpolation
    @path = (0..steps).map do |i|
      t = i.to_f / steps
      omt = 1 - t

      x = (omt**3 * p0[:x]) +
          (3 * omt**2 * t * control_points[0][:x]) +
          (3 * omt * t**2 * control_points[1][:x]) +
          (t**3 * p3[:x])

      y = (omt**3 * p0[:y]) +
          (3 * omt**2 * t * control_points[0][:y]) +
          (3 * omt * t**2 * control_points[1][:y]) +
          (t**3 * p3[:y])

      [x, y]
    end

    @cleared_to_land = true
  end

  def rect
    {
      x: @position.x - AIRCRAFT_RADIUS,
      y: @position.y - AIRCRAFT_RADIUS,
      w: AIRCRAFT_SIZE, h: AIRCRAFT_SIZE,
    }
  end

  def smooth_path
    return if @path.size < 3

    path = @path
    smoothed = [path.first]

    path.each_cons(3) do |p0, p1, p2|
      angle = corner_angle(p0, p1, p2)

      # Flatten p1 toward midpoint of p0-p2
      mid = [(p0[0] + p2[0]) / 2.0, (p0[1] + p2[1]) / 2.0]
      flattened_p1 = [
        p1[0] + (mid[0]-p1[0]) * CORNER_FLATTEN,
        p1[1] + (mid[1]-p1[1]) * CORNER_FLATTEN,
      ]

      if angle < MIN_ANGLE_THRESHOLD
        t_factor = [
          [
            (MIN_ANGLE_THRESHOLD - angle) / (MIN_ANGLE_THRESHOLD - MAX_ANGLE_THRESHOLD),
            1,
          ].min,
          0,
        ].max
        steps = (MIN_CURVE_STEPS + (MAX_CURVE_STEPS - MIN_CURVE_STEPS) * t_factor).ceil

        steps.times do |s|
          t = (s + 1).to_f / (steps + 1)
          smoothed << quadratic_bezier(p0, flattened_p1, p2, t)
        end
      else
        smoothed << p1
      end
    end

    smoothed << path.last
    @path = smoothed
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
    {
      **rect,
      path: "sprites/aircraft/#{type}.png",
      angle: @heading,
      **(@nordo ? WHITE : RUNWAY_COLORS[@runway_type]),
    }
  end

  def primitives
    primitives = [sprite]

    if @departing
      # Departure direction arrow
      primitives << {
        x: @position.x, y: @position.y,
        w: 8, h: 20,
        path: "sprites/symbology/direction_large.png",
        angle: ANGLE[@departing],
        anchor_x: -2,
        anchor_y: 0.5,
        angle_anchor_x: -2,
        angle_anchor_y: 0.5,
      }
    elsif @emergency
      seconds = @emergency.to_seconds

      primitives << [
        # Exclamation point
        {
          x: @position.x - AIRCRAFT_RADIUS, y: @position.y,
          text: "!",
          anchor_x: 1,
          anchor_y: 0.5,
          **RED,
        },
        # Timer
        {
          x: @position.x + AIRCRAFT_RADIUS, y: @position.y,
          text: seconds,
          anchor_x: 0,
          anchor_y: 0.5,
          **(seconds > 10 ? WHITE : RED),
        },
      ]
    end

    primitives
  end

  def path_primitives
    return if @path.empty? || @nordo

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

  def corner_angle(p0, p1, p2)
    v1 = [p0[0] - p1[0], p0[1] - p1[1]]
    v2 = [p2[0] - p1[0], p2[1] - p1[1]]
    dot = v1[0] * v2[0] + v1[1] * v2[1]
    mag1 = Math.hypot(*v1)
    mag2 = Math.hypot(*v2)
    return 180 if mag1.zero? || mag2.zero?
    Math.acos([[dot / (mag1*mag2), 1].min, -1].max) * 180 / Math::PI
  end

  def quadratic_bezier(p0, p1, p2, t)
    omt = 1 - t
    [
      (omt**2 * p0[0]) + (2 * omt * t * p1[0]) + (t**2 * p2[0]),
      (omt**2 * p0[1]) + (2 * omt * t * p1[1]) + (t**2 * p2[1]),
    ]
  end

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
      if @departing == :left
        @offscreen = true
      else
        @position.x = 0
        @course = 180 - @course
        bounced = true
      end
    elsif @position.x >= @screen.w
      if @departing == :right
        @offscreen = true
      else
        @position.x = @screen.w
        @course = 180 - @course
        bounced = true
      end
    end

    # Top/bottom walls
    if @position.y <= 0
      if @departing == :down
        @offscreen = true
      else
        @position.y = 0
        @course = -@course
        bounced = true
      end
    elsif @position.y >= @screen.h
      if @departing == :up
        @offscreen = true
      else
        @position.y = @screen.h
        @course = -@course
        bounced = true
      end
    end

    if bounced
      # Normalize angle
      @course %= 360
      # If path extends off the screen it will get stuck on the edge,
      # so reset it
      @path = []
    end
  end

  def handle_departure
    return unless @departing && @offscreen

    diameter = AIRCRAFT_SIZE / 2

    if @position.x + diameter <= 0 ||
       @position.x - diameter >= @screen.w ||
       @position.y + diameter <= 0 ||
       @position.y - diameter >= @screen.h
      @departed = true
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
