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
    @aircraft.each do |ac|
      return if ac.path.empty?

      previous = ac.position

      ac.path.each do |(x, y)|
        # Draw a line connecting the current point to the previous
        # point in the path
        @primitives << {
          x: x, y: y,
          x2: previous.x, y2: previous.y,
          r: 255, g: 255, b: 255,
        }

        previous = [x, y]
      end
    end
  end
end
