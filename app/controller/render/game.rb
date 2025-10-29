class ControllerGame
  def render_game_init
    reset_camera

    @runway_glow = @map.runways.map { |r| [r.type, 0] }.to_h
    reset_runway_glow
  end

  def render_game
    calc_camera

    render_map

    handle_runway_glow
    render_runways

    if @collisions.any?
      render_collisions
    elsif @warnings[:collision].any? || @warnings[:departure].values.any?(true)
      render_warnings
    end

    render_departures

    if @birds
      render_birds_shadows
      render_birds
    end

    render_paths

    render_exhaust_plumes
    render_aircraft_shadows
    render_aircraft

    render_incoming_alerts

    render_score
    render_dev_mode_label if @dev_mode

    if @game_over && @camera[:trauma] == 0
      render_game_over_modal
    end
  end

  # Apply screen shake
  def calc_camera
    next_camera_angle = 180.0 / 20.0 * @camera.trauma**2
    next_offset = 100.0 * @camera.trauma**2

    # Ensure that the camera angle always switches from positive to negative and
    # vice versa which gives the effect of shaking back and forth
    @camera[:angle] = @camera[:angle] > 0 ? next_camera_angle * -1 : next_camera_angle

    @camera[:x_offset] = next_offset.randomize(:sign, :ratio)
    @camera[:y_offset] = next_offset.randomize(:sign, :ratio)

    # Gracefully degrade trauma
    @camera[:trauma] *= 0.97
    if @camera[:trauma] < 0.05
      @camera[:trauma] = 0
    end
  end

  def shake_screen
    @camera.trauma = 0.5
  end

  def apply_screen_shake(primitive)
    primitive.tap do |p|
      p.x += @camera[:x_offset]
      p.y += @camera[:y_offset]

      p.angle ||= 0
      p.angle += @camera[:angle]
    end
  end

  def reset_runway_glow
    @runway_glow_start, @runway_glow_type = nil, nil
  end

  def handle_runway_glow
    if @runway_glow_type && @runway_glow_start
      # Cycle the appropriate color in a sine wave
      t = ((@ticks - @runway_glow_start - RUNWAY_GLOW_DELAY) / RUNWAY_GLOW_CYCLE) % 1
      glow = ((Math.sin(t * Math::PI * 2) + 1) / 2) * RUNWAY_MAX_GLOW
      @runway_glow[@runway_glow_type] = glow
    else
      # Fade all glow values smoothly back to 0 when inactive
      @runway_glow.each do |type, value|
        next if value.zero?
        new_value = value - RUNWAY_MAX_GLOW / RUNWAY_FADE_SPEED
        @runway_glow[type] = new_value.positive? ? new_value : 0
      end
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
    @primitives << @map.runways.select(&:departure).map do |runway|
      [
        runway.departure_primitives.map { |p| apply_screen_shake(p) },
        apply_screen_shake(runway.hold_short_label),
      ]
    end
  end

  def draw_warning_circle
    size = 96
    pulse_speed = 0.1

    # Sine wave from 0-1
    raw = (Math.sin(@ticks * pulse_speed) * 0.5 + 0.5)
    # Cubic ease-in-out
    scale = 3 * raw**2 - 2 * raw**3

    @outputs[:warning].w = size
    @outputs[:warning].h = size
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
  end

  def render_collisions
    draw_warning_circle

    @primitives << @collisions.map do |collision|
      {
        **apply_screen_shake(circle_to_rect(collision.dup.tap { |c| c.radius *= 2 })),
        path: :warning,
        a: WARNING_ALPHA,
      }
    end
  end

  def render_warnings
    draw_warning_circle

    render_collision_warnings if @warnings[:collision].any?
    render_departure_warnings if @warnings[:departure].values.any?(true)
  end

  def render_collision_warnings
    @primitives << @warnings[:collision].map do |warning|
      {
        **apply_screen_shake(circle_to_rect(warning)),
        path: :warning,
        a: WARNING_ALPHA,
      }
    end
  end

  def render_departure_warnings
    @warnings[:departure].select { |_, v| v }.each_key do |i|
      hold_short_point = @map.runways[i].hold_short_point
      @primitives << apply_screen_shake({
        x: hold_short_point.x, y: hold_short_point.y,
        w: DEPARTURE_WARNING_SIZE, h: DEPARTURE_WARNING_SIZE,
        anchor_x: 0.5, anchor_y: 0.5,
        path: :warning,
        a: WARNING_ALPHA,
      })
    end
  end

  def render_birds
    @primitives << apply_screen_shake(@birds.sprite)
  end

  def render_birds_shadows
    @primitives << apply_screen_shake(
      @birds.sprite.merge(a: SHADOW_ALPHA).tap do |sprite|
        sprite.x += SHADOW_OFFSET.x
        sprite.y -= SHADOW_OFFSET.y
      end
    )
  end

  def render_exhaust_plumes
    @primitives << @exhaust_plumes.select(&:sprite).map do |plume|
      apply_screen_shake(plume.sprite)
    end
  end

  def render_paths
    @primitives << @aircraft.flat_map do |ac|
      if ac.vectoring
        ac.dotted_path_primitives&.map { |p| apply_screen_shake(p.dup) }
      else
        ac.path_primitives&.map do |line|
          # Screen shake needs to be applied differently to line primitives
          line.tap do |l|
            l.x += @camera[:x_offset]
            l.x2 += @camera[:x_offset]
            l.y += @camera[:y_offset]
            l.y2 += @camera[:y_offset]
          end
        end
      end
    end
  end

  def render_aircraft
    @primitives << @aircraft.map(&:primitives).flatten.map do |p|
      apply_screen_shake(p)
    end
  end

  def render_aircraft_shadows
    @primitives << @aircraft.map do |ac|
      min_size = ac.departing ? DEPARTURE_SIZE : LANDING_SIZE

      apply_screen_shake(
        ac.sprite.merge(**BLACK, a: SHADOW_ALPHA).tap do |sprite|
          # Grow/shrink sprite during takeoff/landing
          scale = (sprite.w - min_size) / (AIRCRAFT_SIZE - min_size)

          sprite.x += SHADOW_OFFSET.x * scale
          sprite.y -= SHADOW_OFFSET.y * scale
        end
      )
    end
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

    @primitives << apply_screen_shake({
      x: aircraft.entry_point.x, y: aircraft.entry_point.y,
      w: 60, h: 40,
      angle: aircraft.incoming_marker_angle,
      anchor_x: 0,
      anchor_y: 0.5,
      angle_anchor_x: 0,
      angle_anchor_y: 0.5,
      path: target,
    })
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
