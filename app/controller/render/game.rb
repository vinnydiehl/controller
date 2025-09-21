class ControllerGame
  def render_game
    render_background
    render_paths
    render_aircraft
  end

  def render_background
    @primitives << {
      primitive_marker: :solid,
      x: 0, y: 0,
      w: @screen_width, h: @screen_height,
      **BACKGROUND_COLOR,
    }
  end

  def render_aircraft
    @aircraft.each do |ac|
      @primitives << ac.sprite
    end
  end

  def render_paths
    @primitives << @aircraft.flat_map(&:path_primitives)
  end
end
