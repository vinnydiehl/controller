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

    @warnings = []
  end

  def game_tick
    handle_mouse_inputs
    handle_kb_inputs

    return if @game_over

    # For development:
    # Space to spawn an incoming aircraft, Ctrl+Space to spawn a departure
    if development?
      if @kb.key_down.space
        if @kb.key_down_or_held?(:ctrl)
          spawn_departure
        else
          spawn_aircraft(@aircraft_types.sample)
        end
      end
    end

    handle_spawns unless @dev_mode

    @aircraft.each(&:tick)
    handle_scoring

    # Game over if there's a collision
    @collisions = find_circle_collisions(@aircraft.map(&:hitbox))
    if @collisions.any?
      @game_over = true
      play_sound(:collision)
      return
    end

    # Game over if an emergency aircraft timer reaches zero
    if @aircraft.select(&:emergency).any? { |ac| ac.emergency <= 0 }
      @game_over = true
      play_sound(:collision)
      return
    end

    # Decrement departure timers, game over if one reaches zero
    @map.runways.select(&:departure).each do |runway|
      runway.departure[:timer] -= 1 unless @game_over
      if runway.departure[:timer] <= 0
        @game_over = true
        play_sound(:departure_failure)
        return
      end
    end

    # Find warnings and play sound if there's a new one
    warnings_orig = @warnings.dup
    @warnings = find_circle_collisions(@aircraft.map(&:warning_hitbox))
    # If one warning disappears the same frame as a new one appears this
    # won't play a new sound, but I can't think of a better way to
    # do this without extensive modification to the warning system
    if @warnings.size > warnings_orig.size
      play_sound(:warning)
    end
  end

  # Handles spawning of incoming aircraft and departures.
  def handle_spawns
    # Spawn aircraft in waves. The wave system works as follows:
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

    # For departure spawns, there is a 50% chance of spawning a departure
    # every 5 seconds.
    if @ticks > 0 && @ticks % 10.seconds == 0
      if rand < 0.5
        spawn_departure
      end
    end
  end

  def release_wave
    @incoming_wave = Numeric.rand(1..3)
    @wave_spawn_timer = 0
    # Schedule next wave
    @next_wave_in = Numeric.rand(10..15).seconds
  end

  def handle_incoming_wave
    if @wave_spawn_timer <= 0
      spawn_aircraft(@aircraft_types.sample)
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
    return unless (pos = find_spawn_position)

    ac = Aircraft.new(position: pos, **type)
    @aircraft << ac

    # Find all runways of the appropriate type, we'll need these if the
    # aircraft is emergency or NORDO
    available_runways = @map.runways.select { |r| r.type == ac.runway_type }

    # 10% of aircraft are emergency aircraft, but one can't spawn if a
    # NORDO aircraft is on-screen
    set_emergency = !@aircraft.any?(&:nordo) && rand < 0.1

    if set_emergency
      nearest_runway = available_runways.min_by do |r|
        Geometry.distance(r.position, pos)
      end

      # How long will it take to reach the nearest runway?
      # This is calculated in 2 legs, from spawn to the edge of the screen, then from
      # edge of the screen to the runway. That way if the aircraft is spawned going
      # the "wrong way" before the player is able to redirect it, the player isn't
      # penalized.
      spawn_to_edge = Geometry.distance(pos, ac.entry_point)
      edge_to_runway = Geometry.distance(ac.entry_point, nearest_runway.position)
      seconds_to_reach = (spawn_to_edge + edge_to_runway) / ac.speed

      # If the aircraft spawns toward the departure end of the runway, that is,
      # traveling close to opposite the runway heading, it will have to make
      # a turn in order to land, so we'll give it a few more seconds if it's
      # more than perpendicular to the runway (this doesn't matter for VTOL)
      unless ac.vtol
        reciprocal = (nearest_runway.heading + 180) % 360
        # Smallest angular difference from runway heading
        delta = (ac.course - nearest_runway.heading) % 360
        # Normalize to [-180, 180]
        delta -= 360 if delta > 180
        # If the aircraft is facing closer to reciprocal than to original heading,
        # and it's more than 90° away from the runway heading
        if delta.abs > 90 && ((ac.course - reciprocal) % 360).abs < 90
          seconds_to_reach += 3
        end
      end

      # Set the timer with a little extra time
      ac.emergency = (seconds_to_reach + EMERGENCY_TIME_BUFFER).seconds
    end

    # NORDO aircraft have a 2% chance to spawn (and emergency aircraft spawning
    # has priority). Also can't spawn a NORDO aircraft when an emergency
    # aircraft is on-screen
    set_nordo = !ac.emergency && !@aircraft.any?(&:emergency) && rand < 0.02

    if set_nordo
      ac.nordo = true
      ac.pathfind_to(available_runways.sample)
    end

    # NORDO aircraft have no incoming notification
    unless ac.nordo
      play_sound(set_emergency ? :emergency_spawn : :aircraft_spawn)
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

  # Add a departure to a random runway that doesn't already have one.
  # If all runways already have departures, do nothing.
  def spawn_departure
    # Guard with an if so the sound doesn't play if a departure
    # can't spawn
    if @map.runways.reject(&:departure).sample&.add_departure
      play_sound(:departure_spawn)
    end
  end

  def handle_scoring
    # Score and cull landed/departed aircraft
    landed = @aircraft.select(&:landed)
    unless landed.empty?
      @score += landed.size

      play_sound(:nordo_land) if landed.any?(&:nordo)
      play_sound(:land) if landed.any? { |a| !a.nordo }

      @aircraft.reject!(&:landed)
    end

    count = @aircraft.count(&:departed)
    @score += count
    @aircraft.reject!(&:departed)
    if count > 0
      play_sound(:depart)
    end
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
