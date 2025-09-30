class ControllerGame
  def render_game
    render_map
    render_score

    render_runways

    if @collisions.any?
      render_collisions
    end

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

  def render_collisions
    @primitives << @collisions.map do |collision|
      {
        **circle_to_rect(collision.dup.tap { |c| c.radius *= 2 }),
        path: "sprites/map_editor/circle.png",
        **COLLISION_COLOR,
      }
    end
  end

  def render_paths
    @primitives << @aircraft.flat_map(&:path_primitives)
  end

  def render_aircraft
    @primitives << @aircraft.map(&:sprite)
  end
end
