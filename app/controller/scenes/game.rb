class ControllerGame
  def game_init
    @aircraft = []
    @runways = []

    # Seconds between aircraft spawns
    @spawn_interval = 10

    # Test map
    @map = Map.new(name: "Test", image: "data/maps/test/image.png")
    @map.runways = [
      Runway.new(
        type: :blue,
        name: "12",
        position: [@cx, @cy],
        tdz_radius: 10,
        heading: 120,
      ),
      Runway.new(
        type: :yellow,
        name: "04",
        position: [@cx - 100, @cy],
        tdz_radius: 10,
        heading: 40,
      ),
      Runway.new(
        type: :orange,
        name: "H1",
        position: [@cx + 300, @cy - 100],
        tdz_radius: 20,
        heading: 0,
      ),
    ]
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
