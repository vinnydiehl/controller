class ControllerGame
  def handle_mouse_inputs
    if @mouse.key_down.left
      return unless ac = @aircraft.find { |a| @mouse.intersect_rect?(a.rect) }

      @aircraft_redirecting = ac
      # Clear path if there is one
      ac.path = []
    end

    if @mouse.key_held.left && (ac = @aircraft_redirecting)
      coords = mouse_coords

      # By not allowing a path to begin until the mouse leaves the edge of
      # the aircraft sprite, we fix that little jitter that happens, especially
      # if the click originated from behind the center of the sprite.
      return if coords.inside_rect?(ac.rect) && ac.path.empty?

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
