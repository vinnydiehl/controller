class ControllerGame
  def game_init
    @score = SCORE_VALUE.map { |k, _| [k, 0] }.to_h

    @game_over = nil

    @aircraft = []

    @map.runways.each(&:reset)

    @birds = nil

    # Wave scheduling
    # First wave spawns with a slight delay
    @next_wave_in = 2.seconds
    # Aircraft in incoming wave (0 if there is no incoming wave)
    @incoming_wave = 0
    # Timer to track time between aircraft in a given wave
    @wave_spawn_timer = 0

    @collisions = []
    @warnings = []

    # Game over modal
    @game_over_modal = Layout.rect(
      row: 4.75, col: 9,
      w: 6, h: 2.5,
      include_row_gutter: true,
      include_col_gutter: true
    ).merge(primitive_marker: :solid, **MAP_EDITOR_INPUT_BG_COLOR)
    @game_over_buttons = [
      Button.new(
        **Layout.rect(
          row: 6.25, col: 9.25, w: 2.75, h: 0.75,
        ).slice(:x, :y, :w, :h),
        on_click: -> do
          @game_over = nil
          set_scene(:game, reset_stack: true)
          play_sound(:start_game)
        end,
        text: "Restart",
      ),
      Button.new(
        **Layout.rect(
          row: 6.25, col: 12, w: 2.75, h: 0.75,
        ).slice(:x, :y, :w, :h),
        on_click: -> do
          @game_over = nil
          set_scene(:map_select_menu, reset_stack: true)
          play_sound(:back)
        end,
        text: "Menu",
      ),
    ]
  end

  def game_tick
    if @game_over
      @game_over_buttons.each(&:tick)
      return
    end

    handle_mouse_inputs
    handle_kb_inputs

    # For development:
    #  * Space to spawn an incoming aircraft
    #  * Ctrl+Space to spawn a departure
    #  * Ctrl+B to spawn birds
    if development?
      if @kb.key_down.space
        if @kb.key_down_or_held?(:ctrl)
          spawn_departure
        else
          spawn_aircraft(@aircraft_types.sample)
        end
      end

      if @kb.key_down_or_held?(:ctrl) && @kb.key_down.b
        spawn_birds
      end
    end

    handle_spawns unless @dev_mode

    @aircraft.each(&:tick)
    handle_birds if @birds

    handle_scoring
    handle_game_over
    handle_warnings
  end

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

    # Departure spawns
    if periodic_chance(50, 10)
      spawn_departure
    end

    # Bird spawns
    if !@birds && periodic_chance(25, 30)
      spawn_birds
    end
  end

  # +percentage+ chance of something happening every +seconds+ seconds.
  def periodic_chance(percentage, seconds)
    @ticks > 0 && @ticks % seconds.seconds == 0 && rand < (percentage / 100)
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

    # 10% of aircraft are emergency aircraft, but one can't spawn if a
    # NORDO aircraft is on-screen
    set_emergency = !@aircraft.any?(&:nordo) && rand < 0.1
    ac.declare_emergency(@map.runways) if set_emergency

    # NORDO aircraft have a 2% chance to spawn (and emergency aircraft spawning
    # has priority). Also can't spawn a NORDO aircraft when an emergency
    # aircraft is on-screen
    if !ac.emergency && !@aircraft.any?(&:emergency) && rand < 0.02
      # Find all runways of the appropriate type
      available_runways = @map.runways.select { |r| r.type == ac.runway_type }

      ac.nordo = true
      ac.pathfind_to(available_runways.sample)
    end

    # NORDO aircraft have no incoming notification
    unless ac.nordo
      play_sound(set_emergency ? :emergency : :aircraft_spawn)
    end
  end

  def spawn_birds
    # Just don't spawn if there's no suitable position
    return unless (pos = find_spawn_position)
    @birds = Birds.new(pos)
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
      # Prevent spawning directly into a departing aircraft
      departing_circle = circle.merge(radius: AIRCRAFT_RADIUS + SPAWN_DEPARTURE_BUFFER)

      # Check against all existing aircraft
      too_close = @aircraft.any? do |ac|
        Geometry.intersect_circle?(
          ac.departing ? departing_circle : circle,
          ac.hitbox,
        )
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

  def handle_birds
    @birds.tick

    # Delete the birds when they go offscreen
    unless @birds.offscreen? || @birds.rect.intersect_rect?(@screen)
      unless @birds.struck?
        @score[:birds] += 1
        play_sound(:birds)
      end
      @birds = nil
      return
    end

    # Handle bird collisions
    return unless @birds.collideable?
    @aircraft.reject(&:emergency).each do |ac|
      if Geometry.intersect_circle?(ac.hitbox, @birds.hitbox)
        ac.declare_emergency(@map.runways)
        ac.birdstrike = true
        @birds.strike

        # Departing aircraft must return and NORDO aircraft become
        # controllable (guess they decided to get their head out of
        # their ass and call when they had an emergency)
        ac.departing = nil if ac.departing
        ac.nordo = false if ac.nordo

        play_sound(:emergency)
      end
    end
  end

  def handle_scoring
    # Score and cull landed/departed aircraft
    landed = @aircraft.select(&:landed)
    if landed.any?
      emergencies = landed.count(&:landed_emergency)
      birdstrikes = landed.count(&:birdstrike)
      nordos = landed.count(&:nordo)
      normal_landings = landed.size - emergencies - nordos

      @score[:land] += normal_landings
      @score[:emergency] += emergencies - birdstrikes
      @score[:nordo] += nordos

      play_sound(:nordo_land) if nordos > 0
      play_sound(:land) if normal_landings + emergencies > 0

      @aircraft.reject!(&:landed)
    end

    count = @aircraft.count(&:departed)
    @score[:departure] += count
    @aircraft.reject!(&:departed)
    if count > 0
      play_sound(:depart)
    end
  end

  def score
    @score.reduce(0) { |sum, (type, n)| sum + (SCORE_VALUE[type] * n) }
  end

  def handle_game_over
    # Game over if there's a collision
    @collisions = find_circle_collisions(@aircraft.map(&:hitbox))
    if @collisions.any?
      @game_over = :collision
      play_sound(:collision)
      return
    end

    # Game over if an emergency aircraft timer reaches zero
    if @aircraft.select(&:emergency).any? { |ac| ac.emergency <= 0 }
      @game_over = :emergency
      play_sound(:collision)
      return
    end

    # Decrement departure timers, game over if one reaches zero
    @map.runways.select(&:departure).each do |runway|
      runway.departure[:timer] -= 1 unless @game_over
      if runway.departure[:timer] <= 0
        @game_over = :departure
        play_sound(:departure_failure)
        return
      end
    end
  end

  def handle_warnings
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
