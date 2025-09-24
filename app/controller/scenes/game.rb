class ControllerGame
  def game_init
    @aircraft = []
    @runways = []

    # Seconds between aircraft spawns
    @spawn_interval = 10

    # Test runway
    @runways << Runway.new("12", 120, 20, 200, [@cx, @cy])
  end

  def game_tick
    handle_mouse_inputs

    # For now, rather than spawning at intervals, just spawn
    # when I hit space for easier development
    #
    # if @ticks % @spawn_interval.seconds == 0
    if @kb.key_down.space
      @aircraft << Aircraft.new
    end

    @aircraft.each(&:tick)
    @aircraft.reject!(&:landed)
  end
end
