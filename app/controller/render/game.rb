class ControllerGame
  def render_game
    render_map
    render_paths
    render_aircraft
  end

  def render_aircraft
    @primitives << @aircraft.map(&:sprite)
  end

  def render_paths
    @primitives << @aircraft.flat_map(&:path_primitives)
  end
end
