class ControllerGame
  def game_init
    @score = 0
    @game_over = false

    @aircraft = []

    # Seconds between aircraft spawns
    @spawn_interval = 10

    load_map("island")
  end

  def game_tick
    handle_mouse_inputs
    handle_kb_inputs

    return if @game_over

    # For now, rather than spawning at intervals, just spawn
    # when I hit space for easier development
    #
    # if @ticks % @spawn_interval.seconds == 0
    if @kb.key_down.space
      spawn_aircraft(AIRCRAFT_TYPES.sample)
    end

    @aircraft.each(&:tick)
    @score += @aircraft.count(&:landed)
    @aircraft.reject!(&:landed)

    @collisions = find_circle_collisions(@aircraft.map(&:hitbox))
    @warnings = find_circle_collisions(@aircraft.map(&:warning_hitbox))
    @game_over = true if @collisions.any?
  end

  def spawn_aircraft(type)
    # Just don't spawn if there's no suitable position
    if (pos = find_spawn_position)
      @aircraft << Aircraft.new(position: pos, **type)
    end
  end

  # Returns a random spawn position that is a reasonable distance away from
  # other aircaft, or nil if there is no suitable position.
  def find_spawn_position
    SPAWN_RETRY_LIMIT.times do
      pos = {
        left: [-SPAWN_PADDING, rand(@screen.h)],
        right: [@screen.w + SPAWN_PADDING, rand(@screen.h)],
        bottom: [rand(@screen.w), -SPAWN_PADDING],
        top: [rand(@screen.w), @screen.h + SPAWN_PADDING],
      }[[:left, :right, :top, :bottom].sample]

      circle = { x: pos.x, y: pos.y, radius: AIRCRAFT_RADIUS + SPAWN_BUFFER }

      # Check against all existing aircraft
      too_close = @aircraft.any? do |a|
        Geometry.intersect_circle?(circle, a.hitbox)
      end

      return pos unless too_close
    end

    nil
  end

  def find_circle_collisions(circles)
    collisions = []

    circles.combination(2) do |c1, c2|
      if Geometry.intersect_circle?(c1, c2)
        collisions << c1
        collisions << c2
      end
    end

    collisions.uniq
  end

  def circle_to_rect(circle)
    size = circle.radius * 2
    {
      x: circle.x - circle.radius,
      y: circle.y - circle.radius,
      w: size, h: size,
    }
  end
end
