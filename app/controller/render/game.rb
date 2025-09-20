class ControllerGame
  def render_game
    render_background
  end

  def render_background
    @primitives << {
      primitive_marker: :solid,
      x: 0, y: 0,
      w: @screen_width, h: @screen_height,
      **BACKGROUND_COLOR,
    }
  end
end
