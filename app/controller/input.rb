class ControllerGame
  def handle_mouse_inputs
    if @mouse.key_down.left
      return unless (@aircraft_redirecting = @aircraft.find do |ac|
        @mouse.intersect_rect?(ac.rect)
      end)

      # Clear path if there is one
      @aircraft_redirecting.path = []
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

      # Distance comparison for smoothing of the path (points need to be
      # at least MIN_DIST apart)
      if Geometry.distance(coords, ac.path.last) >= MIN_DIST
        ac.path << coords
      end
    end
  end

  def mouse_coords
    [@mouse.x, @mouse.y]
  end
end
