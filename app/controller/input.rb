class ControllerGame
  def handle_mouse_inputs
    if @mouse.key_down.left
      return unless ac = @aircraft.find { |a| @mouse.intersect_rect?(a.rect) }

      @aircraft_redirecting = ac
      ac.path = [mouse_coords]
    end

    if @mouse.key_held.left && (ac = @aircraft_redirecting)
      coords = mouse_coords

      if ac.path.empty?
        ac.path << coords
        return
      end

      last_x, last_y = ac.path.last
      dx = coords.x - last_x
      dy = coords.y - last_y
      dist = Math.sqrt(dx * dx + dy * dy)

      if dist >= MIN_DIST
        ac.path << coords
      end
    end
  end

  def mouse_coords
    [@mouse.x, @mouse.y]
  end
end
