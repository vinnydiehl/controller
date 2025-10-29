class ControllerGame
  def handle_mouse_inputs
    return if @game_over

    if @mouse.key_down.left
      @aircraft_redirecting = aircraft_clicked

      # Handle click on departure
      if !@aircraft_redirecting
        @map.runways.select(&:departure).each do |runway|
          if runway.mouse_in_hold_short?
            ac_type = @aircraft_types.find { |t| t.type == runway.departure.type }
            course = runway.hold_short_heading

            # Construct a path for the aircraft to taxi onto the runway and takeoff
            path = [runway.hold_short_point]
            if runway.helipad
              offset = {
                x: runway.position.x + AIRCRAFT_SIZE * 2,
                y: runway.position.y,
              }
              rotated = Geometry.rotate_point(
                offset,
                runway.hold_short_heading,
                x: runway.position.x,
                y: runway.position.y,
              )
              toc = [rotated.x, rotated.y]

              path += [
                runway.position,
                toc,
              ]
            else
              # The first point will be straight ahead, just a little bit
              straight_ahead = Geometry.rotate_point(
                {
                  x: runway.hold_short_point.x + DEPARTURE_SIZE / 4,
                  y: runway.hold_short_point.y,
                },
                runway.hold_short_heading,
                x: runway.hold_short_point.x,
                y: runway.hold_short_point.y,
              )
              path << [straight_ahead.x, straight_ahead.y]

              # Then path to the hold short point, then to a point a little bit
              # down the runway, then halfway down the runway (this will be smoothed)
              offsets = [
                HOLD_SHORT_DISTANCE,
                HOLD_SHORT_DISTANCE * 2,
                runway.length / 2,
              ]
              path += offsets.map do |offset|
                point = { x: runway.position.x + offset, y: runway.position.y }
                rotated = Geometry.rotate_point(
                  point,
                  runway.heading,
                  x: runway.position.x,
                  y: runway.position.y,
                )
                [rotated.x, rotated.y]
              end
            end

            @aircraft << Aircraft.new(
              position: runway.hold_short_point,
              **ac_type,
              course: course,
              departing: runway.departure[:direction],
              size: DEPARTURE_SIZE,
              spawned_at: runway.departure_spawned_at,
            ).tap do |ac|
              ac.path = path
              ac.smooth_path(0)
            end

            runway.depart
            # Clear departure warning
            @warnings[:departure][@map.runways.find_index(runway)] = false

            play_sound(:takeoff)
          end
        end

        return
      end

      # Otherwise we're trying to vector an aircraft
      @aircraft_redirecting.vectoring = true

      # Clear path if there is one
      @aircraft_redirecting.path = []
      @aircraft_redirecting.cancel_hold
      # Cancel landing clearance
      @aircraft_redirecting.cleared_to_land = false

      # Start runway glow animation
      @runway_glow_start = @ticks
      @runway_glow_type = @aircraft_redirecting.runway_type

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
              ac.cleared_to_land = runway
              ac.path.take(FINAL_APPROACH_BUFFER)
              ac.path << runway.position

              ac.finalize_path

              reset_runway_glow

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
      reset_runway_glow
    end

    # Right click to toggle a hold
    if @mouse.key_down.right && (ac = aircraft_clicked)
      if ac.holding?
        ac.cancel_hold
        play_sound(:click_aircraft)
      else
        ac.hold
        play_sound(ac.holding? ? :hold : :error)
      end
    end
  end

  # Returns whether or not the mouse is over a redirectable aircraft
  def aircraft_clicked
    @aircraft.select(&:redirectable?)
             .find { |ac| @mouse.intersect_rect?(ac.rect) }
  end

  def handle_kb_inputs
    if @kb.key_down.escape
      set_scene(:pause_menu)
      play_sound(:pause)
    end

    handle_dev_kb_inputs if development?
  end

  def handle_dev_kb_inputs
    if @kb.key_down.e
      set_scene(:map_editor)
    end

    if @kb.key_down.d
      @dev_mode = !@dev_mode
    end

    if @kb.key_down_or_held?(:ctrl) && @kb.key_down.s
      shake_screen
    end
  end

  def mouse_coords
    [@mouse.x, @mouse.y]
  end
end
