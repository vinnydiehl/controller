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
    @primitives << @map.runways.select(&:departure).map(&:departure_primitives)
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
    @primitives << @aircraft.flat_map do |ac|
      ac.vectoring ? ac.dotted_path_primitives : ac.path_primitives
    end
  end

  def render_aircraft
    @primitives << @aircraft.map(&:primitives)
  end

  def render_incoming_alerts
    @aircraft.reject { |ac| ac.rect.intersect_rect?(@screen) || ac.departing || ac.nordo }
             .each_with_index { |ac, i| render_incoming_alert(ac, i) }
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
        **(aircraft.emergency ? INCOMING_EMERGENCY_COLOR : INCOMING_COLOR),
      },
      aircraft.sprite.merge(x: 20 + ac_padding, y: ac_padding, angle: 0),
    ]

    @primitives << {
      x: aircraft.entry_point.x, y: aircraft.entry_point.y,
      w: 60, h: 40,
      angle: aircraft.incoming_marker_angle,
      anchor_x: 0,
      anchor_y: 0.5,
      angle_anchor_x: 0,
      angle_anchor_y: 0.5,
      path: target,
    }
  end
end
