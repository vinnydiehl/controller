class Runway
  attr_accessor *%i[type name position length tdz_radius
                    heading helipad surface hold_short]
  attr_reader :departure, :departure_spawned_at, :hold_short_point

  # Required kwargs:
  #  * type: Color of the runway
  #  * name: Name of the runway
  #  * position: Array [x, y] of the middle of the TDZ
  #  * length: End-to-end length in pixels
  #  * tdz_radius: Radius of the TDZ
  #  * heading: Direction the runway is pointing (screen angle)
  #  * helipad: nil if not, :circle or :square if so
  #  * surface: nil, or name of surface to render
  #  * hold_short: Side to render departures on, :left or :right
  def initialize(**kwargs)
    kwargs.each { |k, v| instance_variable_set("@#{k}", v) }

    @mouse = $gtk.args.inputs.mouse

    # This will get set if there's a pending departure
    @departure = nil
    # For starting sprite animation
    @departure_spawned_at = nil

    set_hold_short_point
  end

  def reset
    @departure = nil
  end

  def set_hold_short_point
    # Point just to the side of the runway where departures will appear
    distance_from_center = (RWY_WIDTH / 2) + HOLD_SHORT_DISTANCE
    angle = (@heading - (@hold_short == :right ? 90 : -90)).to_radians
    @hold_short_point = [
      @position.x + Math.cos(angle) * distance_from_center,
      @position.y + Math.sin(angle) * distance_from_center,
    ]
  end

  def hold_short_heading
    (@heading + (@hold_short == :right ? 90 : -90)) % 360
  end

  # A departure is a Hash containing the following data:
  #  * direction: The direction it wishes to depart; :up, :down, :right, :left
  #  * type: The type of aircraft
  #  * timer: How long you have (in ticks) to depart the aircraft
  def add_departure
    @departure = {
      direction: ANGLE.keys.sample,
      type: AIRCRAFT_TYPES.select { |t| t[:runway] == type }.sample.type,
      timer: DEPARTURE_TIME,
    }
    @departure_spawned_at = Kernel.tick_count
  end

  def depart
    @departure = nil
  end

  def departure_primitives
    x, y = @hold_short_point

    [
      # Direction arrow
      {
        x: x, y: y,
        w: 4, h: 10,
        angle: ANGLE[@departure[:direction]],
        path: "sprites/symbology/direction_small.png",
        # Anchor magic to get it to rotate around the aircraft
        anchor_x: -1.8,
        anchor_y: 0.5,
        angle_anchor_x: -1.8,
        angle_anchor_y: 0.5,
      },
      # Aircraft sprite
      hold_short_sprite(@departure[:type]),
    ]
  end

  # Sprite for the aircraft holding short. If one isn't specified, it'll
  # use the first one it can find that can land on that type of runway.
  def hold_short_sprite(ac_type = AIRCRAFT_TYPES.find { |t| t[:runway] == @type }.type)
    x, y = @hold_short_point
    sprite = {
      x: x, y: y,
      w: DEPARTURE_SIZE, h: DEPARTURE_SIZE,
      angle: @heading + (@hold_short == :right ? 90 : -90),
      path: "sprites/aircraft/#{ac_type}.png",
      anchor_x: 0.5,
      anchor_y: 0.5,
      **RUNWAY_COLORS[@type],
    }

    if ac_type == :helicopter
      # Animate helicopter rotor
      start = @departure_spawned_at || 0
      sprite.merge(
        tile_x: start.frame_index(3, 3, true) * AIRCRAFT_SIZE,
        tile_y: 0,
        tile_w: AIRCRAFT_SIZE,
        tile_h: AIRCRAFT_SIZE,
      )
    else
      sprite
    end
  end

  def hold_short_label(seconds = @departure.timer.to_seconds)
    x, y = @hold_short_point
    angle = @heading.to_radians
    x += Math.cos(angle) * HOLD_SHORT_LABEL_PADDING
    y += Math.sin(angle) * HOLD_SHORT_LABEL_PADDING

    {
      x: x, y: y,
      text: seconds,
      size_px: HOLD_SHORT_LABEL_SIZE,
      anchor_x: 0.5,
      anchor_y: 0.5,
      **(seconds > DEPARTURE_WARNING_TIME ? WHITE : RED),
    }
  end

  def mouse_in_tdz?
    @mouse.inside_circle?(@position, @tdz_radius)
  end

  def mouse_in_hold_short?
    @mouse.inside_circle?(@hold_short_point, DEPARTURE_SIZE / 2)
  end

  def to_h
    {
      type: @type,
      name: @name,
      position: @position,
      length: @length,
      tdz_radius: @tdz_radius,
      heading: @heading,
      helipad: @helipad,
      surface: @surface,
      hold_short: @hold_short,
    }
  end
end
