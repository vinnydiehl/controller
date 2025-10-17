class ControllerGame
  def render_game
    render_map
    render_score
    render_dev_mode_label if @dev_mode

    render_runways
    render_departures

    if @collisions.any?
      render_collisions
    elsif @warnings.any?
      render_warnings
    end

    render_birds if @birds

    render_exhaust_plumes
    render_paths
    render_aircraft

    render_incoming_alerts

    if @game_over
      render_game_over_modal
    end
  end

  def render_score
    @primitives << Layout.point(
      row: -0.75,
      col: -0.5,
      row_anchor: 0.5,
      col_anchor: 0.5,
    ).merge(
      text: score,
      size_enum: 10,
      anchor_x: 0,
      anchor_y: 0.5,
      **WHITE,
    )
  end

  def render_dev_mode_label
    @primitives << Layout.point(
      row: 12.25,
      col: 23.25,
      row_anchor: 0.5,
      col_anchor: 1,
    ).merge(
      text: "Development Mode",
      size_px: 20,
      anchor_x: 1,
      anchor_y: 0,
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
    size = 96
    pulse_speed = 0.1

    # Sine wave from 0-1
    raw = (Math.sin(@ticks * pulse_speed) * 0.5 + 0.5)
    # Cubic ease-in-out
    scale = 3 * raw**2 - 2 * raw**3

    @outputs[:warning].w ||= size
    @outputs[:warning].h ||= size
    @outputs[:warning].primitives << {
      x: 0, y: 0, w: size, h: size,
      path: "sprites/symbology/warning/bg.png",
      **WARNING_COLORS[:background],
    }
    @outputs[:warning].primitives << {
      x: size / 2, y: size / 2,
      # Ease the blur
      w: size * scale, h: size * scale,
      path: "sprites/symbology/warning/blur.png",
      anchor_x: 0.5, anchor_y: 0.5,
      **WARNING_COLORS[:blur],
    }
    @outputs[:warning].primitives << {
      x: 0, y: 0, w: size, h: size,
      path: "sprites/symbology/warning/border.png",
      **WARNING_COLORS[:border],
    }

    @primitives << @warnings.map do |warning|
      {
        **circle_to_rect(warning),
        path: :warning,
        a: 150,
      }
    end
  end

  def render_birds
    @primitives << @birds.sprite
  end

  def render_exhaust_plumes
    @primitives << @exhaust_plumes.map(&:sprite)
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

  def render_game_over_modal
    @primitives << [
      @game_over_modal,
      @game_over_modal.merge(primitive_marker: :border, **BORDER_COLOR),
      @game_over_buttons,
    ]

    @primitives << {
      **Layout.point(
        row: 4.4, col: 12,
      ),
      anchor_x: 0.5,
      anchor_y: 0.5,
      text: "Game Over",
      size_enum: 6,
      **WHITE,
    }
    @primitives << {
      **Layout.point(
        row: 5, col: 12,
      ),
      anchor_x: 0.5,
      anchor_y: 0.5,
      text: GAME_OVER[@game_over],
      size_px: 15,
      **WHITE,
    }
  end
end
