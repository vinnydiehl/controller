class ControllerGame
  def game_init
    @aircraft = []
    @runways = []

    # Seconds between aircraft spawns
    @spawn_interval = 10

    # Test runway
    @runways << Runway.new("12", 120, 20, 200, [@cx, @cy], :blue)
    @runways << Runway.new("04", 40, 20, 170, [@cx - 100, @cy], :yellow)
    @runways << Runway.new("H1", 0, 20, 20, [@cx + 300, @cy - 100], :orange)
  end

  def game_tick
    handle_mouse_inputs

    # For now, rather than spawning at intervals, just spawn
    # when I hit space for easier development
    #
    # if @ticks % @spawn_interval.seconds == 0
    if @kb.key_down.space
      @aircraft << Aircraft.new(**(AIRCRAFT_TYPES.sample))
    end

    @aircraft.each(&:tick)
    @aircraft.reject!(&:landed)
  end
end
