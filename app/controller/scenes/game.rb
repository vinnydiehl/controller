class ControllerGame
  def game_init
    @aircraft = []

    # Seconds between aircraft spawns
    @spawn_interval = 10
  end

  def game_tick
    handle_mouse_inputs

    if @ticks % @spawn_interval.seconds == 0
      @aircraft << Aircraft.new
    end

    @aircraft.each(&:tick)
  end
end
