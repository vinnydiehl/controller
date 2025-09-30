class ControllerGame
  def render_game
    render_map
    render_score
    render_runways
    render_paths
    render_aircraft
  end

  def render_score
    @primitives << Layout.point(
      row: -0.75,
      col: -0.5,
      row_anchor: 0.5,
      col_anchor: 0.5,
    ).merge(
      text: @score,
      size_enum: 10,
      anchor_x: 0,
      anchor_y: 0.5,
      **WHITE,
    )
  end

  def render_aircraft
    @primitives << @aircraft.map(&:sprite)
  end

  def render_paths
    @primitives << @aircraft.flat_map(&:path_primitives)
  end
end
