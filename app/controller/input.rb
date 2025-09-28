class ControllerGame
  def handle_mouse_inputs
    if @mouse.key_down.left
      return unless (@aircraft_redirecting = @aircraft.find do |ac|
        @mouse.intersect_rect?(ac.rect)
      end)

      # Clear path if there is one
      @aircraft_redirecting.path = []
      # Cancel landing clearance
      @aircraft_redirecting.cleared_to_land = false
    end

    if @mouse.key_held.left && (ac = @aircraft_redirecting) && !ac.cleared_to_land
      coords = mouse_coords

      # By not allowing a path to begin until the mouse leaves the edge of
      # the aircraft sprite, we fix that little jitter that happens, especially
      # if the click originated from behind the center of the sprite.
      return if coords.inside_rect?(ac.rect) && ac.path.empty?

      @map.runways.each do |runway|
        if runway.mouse_in_tdz? && ac.runway_type == runway.type
          final_heading = ac.path[-FINAL_APPROACH_BUFFER].angle_to(runway.position)
          alignment = (runway.heading - final_heading).abs

          if ac.vtol || alignment <= FINAL_APPROACH_TOLERANCE
            ac.cleared_to_land = true
            ac.path.take(FINAL_APPROACH_BUFFER)
            ac.path << runway.position

            return
          end
        end
      end

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

  def handle_kb_inputs
    if @kb.key_down.e
      set_scene(:map_editor)
    end
  end

  def mouse_coords
    [@mouse.x, @mouse.y]
  end
end
