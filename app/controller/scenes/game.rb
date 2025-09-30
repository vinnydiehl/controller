class ControllerGame
  def game_init
    @score = 0
    @aircraft = []

    # Seconds between aircraft spawns
    @spawn_interval = 10

    load_map("island")
  end

  def game_tick
    handle_mouse_inputs
    handle_kb_inputs

    # For now, rather than spawning at intervals, just spawn
    # when I hit space for easier development
    #
    # if @ticks % @spawn_interval.seconds == 0
    if @kb.key_down.space
      @aircraft << Aircraft.new(**(AIRCRAFT_TYPES.sample))
    end

    @aircraft.each(&:tick)
    @score += @aircraft.count(&:landed)
    @aircraft.reject!(&:landed)
  end
end
