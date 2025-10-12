class Aircraft
  attr_accessor *%i[position path cleared_to_land emergency
                    landed nordo type speed runway_type vectoring vtol]
  attr_reader *%i[course departing departed entry_point
                  incoming_marker_angle landed_emergency]

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
                 course: nil, departing: nil, size: AIRCRAFT_SIZE)
    @position, @type, @runway_type, @vtol, @course, @departing, @size =
      position, type, runway, vtol, course, departing, size

    set_speed(speed)

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
    # Tick that landing started (for animation)
    @landed_at = nil
    # This will fade to 0 during landing animation
    @alpha = 255


    # For tracking whether or not the aircraft is allowed to be off-screen:
    # The aircraft begins off the screen. This will be set to false
    # once it fully enters the screen and then the edge of the aircraft
    # will bounce off the edge of the screen
    @incoming_offscreen = true
    # This will be set to true once the center of the aircraft has entered
    # the screen, at this point it will become controllable. If it attempts
    # to steer off-screen at this point, the center of the aircraft will
    # bounce off the edge
    @incoming_point_on_screen = false
    # Departing aircraft will be allowed to leave the screen in a certain
    # direction, this variable tracks that
    @departing_offscreen = false

    @departed = false

    if @departing
      # The aircraft will take some time to animate the process of taxiing
      # onto the runway and becoming airborne. Once it's airborne,
      # this will be set to false.
      @taking_off = true
      # The speed will also need to accelerate to the set speed, so save this
      @cruise_speed = speed
      set_speed(TAXI_SPEED)
    else
      # Otherwise we've spawned an incoming aircraft off-screen.
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

    # Cache for dotted path
    @dotted_path_primitives = []

    @spawned_at = Kernel.tick_count
  end

  def tick
    # Handle aircraft coming onto the screen
    if @incoming_offscreen
      @incoming_offscreen = !rect.inside_rect?(@screen)
      @incoming_point_on_screen = @position.inside_rect?(@screen)
    end

    # If a departure begins to head offscreen but then comes back
    # onscreen, we need to unset this so it can't leave the screen
    # on any edge
    if @departing_offscreen && rect.inside_rect?(@screen)
      @departing_offscreen = false
    end

    # Remove dotted path points the aircraft has already passed
    if @vectoring && @dotted_path_primitives.any?
      @dotted_path_primitives.reject! do |dot|
        Geometry.distance(dot, @position) < DOT_SPACING / 2
      end
    end

    if @path.any?
      if holding?
        move_along_hold
      else
        move_along_path
      end
    else
      # No path, keep flying straight using last heading
      move_along_course
    end

    handle_landing_animation if @landed_at

    # If the aircraft is taking off, ease the aircraft's size and
    # speed as it becomes airborne
    if taking_off? && path.size == 1
      @takeoff_run ||= Geometry.distance(@position, @path[0])
      run_remaining = Geometry.distance(@position, @path[0])

      progress = 1.0 - (run_remaining / @takeoff_run.to_f)
      progress = progress.clamp(0.0, 1.0)

      eased = 1 - (1 - progress)**2

      @size = DEPARTURE_SIZE + (AIRCRAFT_SIZE - DEPARTURE_SIZE) * eased
      set_speed(TAXI_SPEED + (@cruise_speed - TAXI_SPEED) * eased)
    end

    if @emergency
      @emergency -= 1
    end

    handle_screen_edge_collision
    handle_departure
    ease_heading
  end

  def set_speed(speed)
    @speed = speed
    @speed_px = @speed / 60
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

    @cleared_to_land = runway
  end

  def rect
    {
      x: @position.x - @size / 2,
      y: @position.y - @size / 2,
      w: @size, h: @size,
    }
  end

  def smooth_path(corner_flatten = CORNER_FLATTEN)
    return if @path.size < 3

    path = @path
    smoothed = [path.first]

    path.each_cons(3) do |p0, p1, p2|
      angle = corner_angle(p0, p1, p2)

      # Flatten p1 toward midpoint of p0-p2
      mid = [(p0[0] + p2[0]) / 2.0, (p0[1] + p2[1]) / 2.0]
      flattened_p1 = [
        p1[0] + (mid[0]-p1[0]) * corner_flatten,
        p1[1] + (mid[1]-p1[1]) * corner_flatten,
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
    sprite = {
      **rect,
      path: "sprites/aircraft/#{type}.png",
      angle: @heading,
      **(@nordo ? WHITE : RUNWAY_COLORS[@runway_type]),
      a: @alpha,
    }

    if type == :helicopter
      # Animate helicopter rotor
      sprite.merge(
        tile_x: @spawned_at.frame_index(3, 3, true) * AIRCRAFT_SIZE,
        tile_y: 0,
        tile_w: AIRCRAFT_SIZE,
        tile_h: AIRCRAFT_SIZE,
      )
    else
      sprite
    end
  end

  def primitives
    primitives = [sprite]

    if @departing
      # Departure direction arrow
      scale = @size / AIRCRAFT_SIZE
      primitives << {
        x: @position.x, y: @position.y,
        w: 8 * scale, h: 20 * scale,
        path: "sprites/symbology/direction_large.png",
        angle: ANGLE[@departing],
        anchor_x: -2,
        anchor_y: 0.5,
        angle_anchor_x: -2,
        angle_anchor_y: 0.5,
        a: taking_off? ? 100 : 255,
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
    return if @path.empty? || @nordo || taking_off?

    color = if holding?
      HOLD_PATH_COLOR
    elsif @cleared_to_land
      CLEARED_TO_LAND_PATH_COLOR
    else
      PATH_COLOR
    end

    path = holding? ? @path : [[@position.x, @position.y], *@path]
    path.each_cons(2).map do |(x, y), (x2, y2)|
      {
        x: x, y: y,
        x2: x2, y2: y2,
        scale_quality_enum: 2,
        **color,
      }
    end
  end

  def dotted_path_primitives
    update_dotted_path
  end

  def clear_dots
    @dotted_path_primitives = []
  end

  def finalize_path
    clear_dots
    @vectoring = false

    if cleared_to_land
      x, y = cleared_to_land.position
      tdz = {
        x: x, y: y,
        radius: cleared_to_land.tdz_radius,
      }

      @path.reject! do |p|
        p = { x: p.x, y: p.y }
        p.point_inside_circle?(tdz)
      end

      @path << cleared_to_land.position
    end

    smooth_path
  end

  # Starts a hold at the Aircraft's current @position along its
  # current @heading.
  def hold
    @holding = true
    @hold_path_i = 0

    # Need to generate a path, starting at the current position
    @path = [[@position.x, @position.y]]

    # Outbound leg
    leg_1 = Geometry.rotate_point(
      { x: @position.x + HOLD_LEG_LENGTH, y: @position.y },
      @heading,
      x: @position.x, y: @position.y
    )
    @path << [leg_1.x, leg_1.y]

    # First turn (to reciprocal heading)
    turn_1_center = Geometry.rotate_point(
      { x: leg_1.x + HOLD_TURN_RADIUS, y: leg_1.y },
      (@heading - 90) % 360,
      x: leg_1.x, y: leg_1.y
    )
    @path += arc_points(
      turn_1_center.x, turn_1_center.y,
      HOLD_TURN_RADIUS,
      (@heading + 90) % 360, (@heading - 90) % 360,
      HOLD_TURN_STEPS,
    )

    # Inbound leg
    inbound_start = @path.last
    leg_2 = Geometry.rotate_point(
      { x: inbound_start[0] + HOLD_LEG_LENGTH, y: inbound_start[1] },
      (@heading - 180) % 360,
      x: inbound_start[0], y: inbound_start[1]
    )
    @path << [leg_2.x, leg_2.y]

    # Second turn (back to original heading)
    turn_2_center = Geometry.rotate_point(
      { x: leg_2.x + HOLD_TURN_RADIUS, y: leg_2.y },
      (@heading + 90) % 360,
      x: leg_2.x, y: leg_2.y
    )
    @path += arc_points(
      turn_2_center.x, turn_2_center.y,
      HOLD_TURN_RADIUS,
      (@heading - 90) % 360, (@heading + 90) % 360,
      HOLD_TURN_STEPS,
    )

    # If any part of the hold goes off-screen, we can't do the hold
    unless @path.all? { |pt| pt.inside_rect?(@screen) }
      cancel_hold
    end
  end

  def holding?
    !!@holding
  end

  def cancel_hold
    @holding = false
    @path = []
  end

  # Returns whether or now the takeoff animation is in progress
  def taking_off?
    !!@taking_off
  end

  # Returns whether or not the landing animation is in progress
  def landing?
    !!@landed_at
  end

  # Can this aircraft be redirected? If this returns false, clicking on the
  # aircraft will do nothing
  def redirectable?
    !nordo && !taking_off? && !landing? && (@incoming_point_on_screen || @departing)
  end

  private

  def update_dotted_path
    @dotted_path_primitives ||= []
    @last_dot_index ||= 0

    return if @path.empty?

    # Start from last path segment we processed
    path_points = [[@position.x, @position.y], *@path]

    # Keep track of remaining distance to place next dot
    @dot_accum ||= 0.0

    # Process new segments only
    (@last_dot_index...(path_points.size - 1)).each do |i|
      start_pt = path_points[i]
      end_pt = path_points[i + 1]

      seg_vec = [end_pt[0] - start_pt[0], end_pt[1] - start_pt[1]]
      seg_len = Math.sqrt(seg_vec[0]**2 + seg_vec[1]**2)
      next if seg_len.zero?

      dir = [seg_vec[0] / seg_len, seg_vec[1] / seg_len]

      distance = @dot_accum
      while distance < seg_len
        @dotted_path_primitives << {
          x: start_pt[0] + dir[0] * distance,
          y: start_pt[1] + dir[1] * distance,
          w: PATH_DOT_SIZE,
          h: PATH_DOT_SIZE,
          anchor_x: 0.5,
          anchor_y: 0.5,
          path: "sprites/symbology/path_dot.png",
        }
        distance += DOT_SPACING
      end
      @dot_accum = distance - seg_len
    end

    @last_dot_index = path_points.size - 1
    @dotted_path_primitives
  end

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

  # Generate points for an arc.
  def arc_points(cx, cy, radius, start_angle, end_angle, steps)
    step = 180 / steps
    (0..steps).map do |i|
      angle = (start_angle - i * step) % 360
      rad = angle.to_radians
      [cx + Math.cos(rad) * radius, cy + Math.sin(rad) * radius]
    end
  end

  # Advance the aircraft long its path.
  def move_along_path
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
      move_along_course
    end

    if @path.empty?
      # Handle landing
      if @cleared_to_land
        # Save the tick count that we landed at for animation progress
        @landed_at = Kernel.tick_count
        # If it's an emergency... we made it! Stop the timer
        @emergency = nil
        @landed_emergency = true
        # Align aircraft with runway heading for landing animation
        # (unless it's VTOL)
        unless @vtol
          @course = @cleared_to_land.heading
        end
      end

      if @taking_off
        @taking_off = false
        @size = AIRCRAFT_SIZE
      end
    end
  end

  # If the Aircraft is in a hold, we don't want to destroy the path as
  # we advance along it, so we will use the index of @path instead.
  def move_along_hold
    target = @path[@hold_path_i]
    dist = Geometry.distance(@position, target)

    if dist <= @speed_px
      # Snap to waypoint
      @course = target.angle_from(@position)
      @position = target
      # Next waypoint
      @hold_path_i = (@hold_path_i + 1) % @path.size
    else
      # Step toward waypoint
      @course = target.angle_from(@position)
      move_along_course
    end
  end

  def move_along_course
    # VTOL aircraft land straight down
    return if @landed_at && @vtol

    @position = Geometry.vec2_add(
      @position,
      [
        Math.cos(@course.to_radians) * @speed_px,
        Math.sin(@course.to_radians) * @speed_px,
      ],
    )
  end

  def handle_screen_edge_collision
    return if @departing_offscreen

    bounced = false

    edges = {
      up: {
        hit: @position.y + AIRCRAFT_RADIUS >= @screen.h,
        center_hit: @position.y >= @screen.h,
        set: -> { @position.y = @screen.h - AIRCRAFT_RADIUS },
        center_set: -> { @position.y = @screen.h },
        reflect: -> { @course = -@course },
      },
      down: {
        hit: @position.y <= AIRCRAFT_RADIUS,
        center_hit: @position.y <= 0,
        set: -> { @position.y = AIRCRAFT_RADIUS },
        center_set: -> { @position.y = 0 },
        reflect: -> { @course = -@course },
      },
      left: {
        hit: @position.x <= AIRCRAFT_RADIUS,
        center_hit: @position.x <= 0,
        set: -> { @position.x = AIRCRAFT_RADIUS },
        center_set: -> { @position.x = 0 },
        reflect: -> { @course = 180 - @course },
      },
      right: {
        hit: @position.x + AIRCRAFT_RADIUS >= @screen.w,
        center_hit: @position.x >= @screen.w,
        set: -> { @position.x = @screen.w - AIRCRAFT_RADIUS },
        center_set: -> { @position.x = @screen.w },
        reflect: -> { @course = 180 - @course },
      },
    }

    edges.each do |direction, data|
      # Have we hit a wall (either with the edge of the aircraft if it's
      # already on-screen, or the center of the aircraft if it hasn't
      # fully entered the screen)?
      next unless (!@incoming_offscreen && data[:hit]) ||
                   (@incoming_point_on_screen && data[:center_hit])

      if @departing == direction
        # Allow departures to leave the screen in the appropriate direction
        @departing_offscreen = true
        return
      else
        # Otherwise set it back to where it was and bounce it off the wall
        data[@incoming_offscreen ? :center_set : :set].call
        data[:reflect].call
        bounced = true
      end
    end

    if bounced
      # Normalize angle
      @course %= 360
      # If path extends off the screen it will get stuck on the edge,
      # so reset it
      @path.clear
    end
  end

  def handle_departure
    # @departing_offscreen check isn't strictly needed, but prevents doing
    # unnecessary collision checks
    if @departing && @departing_offscreen && !rect.intersect_rect?(@screen)
      @departed = true
    end
  end

  # Ease the heading toward the course
  def ease_heading
    # Find delta between heading and course
    delta = (@course - @heading) % 360
    delta -= 360 if delta > 180
    abs_delta = delta.abs
    # Normalize delta (0–180) to 0–1
    t = [abs_delta / 180, 1].min

    # Minimum turn rate (deg/frame) for small deltas (as small as possible)
    base_rate = Float::EPSILON
    # Max turn rate for very large deltas
    max_rate = 5
    # Curve steepness; higher == more sensitive to large deltas
    response = 5

    # Ease-in-out curve
    scale = Math.sin(t * Math::PI / 2)

    # Compute adaptive rate
    rate = base_rate + (max_rate - base_rate) * scale

    # Trend heading towards the course at the appropriate rate
    if abs_delta <= rate
      @heading = @course
    else
      @heading += rate * (delta.positive? ? 1 : -1)
      @heading %= 360
    end
  end

  def handle_landing_animation
    elapsed = Kernel.tick_count - @landed_at
    progress = (elapsed / LANDING_ANIMATION_LENGTH).clamp(0.0, 1.0)

    # Ease-out size
    eased_size = 1 - (1 - progress)**2
    @size = AIRCRAFT_SIZE - (AIRCRAFT_SIZE - LANDING_SIZE) * eased_size

    # Ease-in alpha
    eased_alpha = progress**2
    @alpha = (255 * (1 - eased_alpha)).to_i

    # Once animation completes, mark as landed
    if progress >= 1.0
      @landed = true
    end
  end
end
