class ControllerGame
  def handle_mouse_inputs
    return if @game_over

    if @mouse.key_down.left
      # See if we're clicking on an airborne aircraft
      @aircraft_redirecting = @aircraft.reject(&:nordo).find do |ac|
        @mouse.intersect_rect?(ac.rect)
      end

      # Handle click on departure
      if !@aircraft_redirecting
        @map.runways.select(&:departure).each do |runway|
          if runway.mouse_in_hold_short?
            ac_type = AIRCRAFT_TYPES.find { |t| t.type == runway.departure.type }
            course = runway.heading
            # The way that helipads are angled, we'll want to depart straight
            # forward rather than turning onto the runway
            course = (course + 90) % 360 if ac_type.vtol

            @aircraft << Aircraft.new(
              position: runway.position,
              **ac_type,
              course: course,
              departing: runway.departure[:direction],
            )
            runway.depart

            play_sound(:takeoff)
          end
        end
      end

      # Otherwise we're trying to vector an aircraft
      return unless @aircraft_redirecting

      @aircraft_redirecting.vectoring = true

      # Clear path if there is one
      @aircraft_redirecting.path = []
      # Cancel landing clearance
      @aircraft_redirecting.cleared_to_land = false

      play_sound(:click_aircraft)
    end

    if @mouse.key_held.left && (ac = @aircraft_redirecting) && !ac.cleared_to_land
      coords = mouse_coords

      # By not allowing a path to begin until the mouse leaves the edge of
      # the aircraft sprite, we fix that little jitter that happens, especially
      # if the click originated from behind the center of the sprite.
      return if coords.inside_rect?(ac.rect) && ac.path.empty?

      # Handle landing clearance
      unless ac.departing
        @map.runways.each do |runway|
          if runway.mouse_in_tdz? && ac.runway_type == runway.type && ac.path.any?
            # Take a buffer a few waypoints back from the final leg of the path
            # to determine if the runway alignment of the path is within tolerance
            # to clear for landing. If the path is shorter than the buffer,
            # just use the first point in the path
            buffer_i = ac.path.size >= FINAL_APPROACH_BUFFER ? -FINAL_APPROACH_BUFFER : 0
            final_heading = ac.path[buffer_i].angle_to(runway.position)
            alignment = (runway.heading - final_heading).abs

            if ac.vtol || alignment <= FINAL_APPROACH_TOLERANCE
              ac.cleared_to_land = true
              ac.path.take(FINAL_APPROACH_BUFFER)
              ac.path << runway.position

              ac.finalize_path

              play_sound(:clear_for_landing)

              return
            end
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

    if @mouse.key_up.left && (ac = @aircraft_redirecting)
      ac.finalize_path
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
