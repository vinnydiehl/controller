class ControllerGame
  def game_init
    @score = 0
    @game_over = false

    @aircraft = []

    # Wave scheduling
    # First wave spawns with a slight delay
    @next_wave_in = 2.seconds
    # Aircraft in incoming wave (0 if there is no incoming wave)
    @incoming_wave = 0
    # Timer to track time between aircraft in a given wave
    @wave_spawn_timer = 0

    load_map("island")
  end

  def game_tick
    handle_mouse_inputs
    handle_kb_inputs

    return if @game_over

    # Activate this to spawn aircraft by hitting spacebar
    # if @kb.key_down.space
    #   spawn_aircraft(AIRCRAFT_TYPES.sample)
    # end
    #
    # Otherwise we will spawn them in waves. The wave system works as follows:
    #
    # For example:
    #  * The waves are spaced out by a random amount from 10 to 15 seconds
    #  * Each wave contains a random amount from 1 to 3 aircraft
    #  * Additionally, each aircraft within a given wave are spaced out by a
    #    random amount from 2 to 4 seconds
    #
    # The exact numbers above can be tweaked for different difficulty levels.
    if @incoming_wave > 0
      handle_incoming_wave
    elsif @next_wave_in <= 0
      release_wave
    else
      @next_wave_in -= 1
    end

    @aircraft.each(&:tick)
    @score += @aircraft.count(&:landed)
    @aircraft.reject!(&:landed)

    @collisions = find_circle_collisions(@aircraft.map(&:hitbox))
    @warnings = find_circle_collisions(@aircraft.map(&:warning_hitbox))
    @game_over = true if @collisions.any?
  end

  def release_wave
    @incoming_wave = Numeric.rand(1..3)
    @wave_spawn_timer = 0
    # Schedule next wave
    @next_wave_in = Numeric.rand(10..15).seconds
  end

  def handle_incoming_wave
    if @wave_spawn_timer <= 0
      spawn_aircraft(AIRCRAFT_TYPES.sample)
      @incoming_wave -= 1

      if @incoming_wave > 0
        # Time between each aircraft in a wave
        @wave_spawn_timer = Numeric.rand(2..4).seconds
      end
    else
      @wave_spawn_timer -= 1
    end
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
