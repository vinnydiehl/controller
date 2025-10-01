class ControllerGame
  def render_game
    render_map
    render_score

    render_runways
    render_departures

    if @collisions.any?
      render_collisions
    elsif @warnings.any?
      render_warnings
    end

    render_paths
    render_aircraft

    render_incoming_alerts
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

  def render_departures
    @primitives << @map.runways.select(&:departure).map(&:departure_sprite)
    @primitives << @map.runways.select(&:departure).map(&:hold_short_label)
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

  def render_warnings
    @primitives << @warnings.map do |warning|
      {
        **circle_to_rect(warning),
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

  def render_incoming_alerts
    @aircraft.reject { |ac| ac.rect.intersect_rect?(@screen) }
             .each_with_index do |aircraft, i|
      render_incoming_alert(aircraft, i)
    end
  end

  def render_incoming_alert(aircraft, id)
    target = "incoming_alert_#{id}"
    @outputs[target].w = 60
    @outputs[target].h = 40

    ac_padding = (40 - AIRCRAFT_SIZE) / 2
    @outputs[target].primitives << [
      {
        x: 0, y: 0,
        w: 60, h: 40,
        path: "sprites/symbology/incoming.png",
      },
      aircraft.sprite[0].merge(x: 20 + ac_padding, y: ac_padding, angle: 0),
    ]

    # We need to figure out where on the screen the aircraft is going
    # to appear based on the angle... we'll use line intersection.
    # Here's a line from aircraft to center of screen
    ac_line = {
      x: aircraft.position.x,
      y: aircraft.position.y,
      x2: @cx, y2: @cy,
    }
    # Lines for the edges of the screen, the order of these matters
    # for setting the angle later
    screen_lines = [
      # Left
      {
        x: 0, y: 0,
        x2: 0, y2: @screen.h,
      },
      # Bottom
      {
        x: 0, y: 0,
        x2: @screen.w, y2: 0,
      },
      # Right
      {
        x: @screen.w, y: 0,
        x2: @screen.w, y2: @screen.h,
      },
      # Top
      {
        x: 0, y: @screen.h,
        x2: @screen.w, y2: @screen.h,
      },
    ]
    # Now find the first intersection
    intersection = nil
    angle = 0
    screen_lines.each_with_index do |sl, i|
      if (intersection = Geometry.line_intersect(sl, ac_line))
        angle = i * 90
        break
      end
    end

    # Aaaand finally we can draw it
    @primitives << {
      x: intersection.x, y: intersection.y,
      w: 60, h: 40,
      angle: angle,
      anchor_x: 0,
      anchor_y: 0.5,
      angle_anchor_x: 0,
      angle_anchor_y: 0.5,
      path: target,
    }
  end
end
