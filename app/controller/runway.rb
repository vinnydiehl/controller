class Runway
  attr_accessor *%i[type name position length tdz_radius heading helipad surface]
  attr_reader :departure, :hold_short_point

  def initialize(type:, name:, position:, length:, tdz_radius:,
                 heading:, helipad:, surface:)
    @type, @name, @position, @length, @tdz_radius, @heading, @helipad, @surface=
      type, name, position, length, tdz_radius, heading, helipad, surface

    @mouse = $gtk.args.inputs.mouse

    # This will get set if there's a pending departure
    @departure = nil

    # Point just to the side of the runway where departures will appear
    distance_from_center = (RWY_WIDTH / 2) + HOLD_SHORT_DISTANCE
    angle = (@heading - 90).to_radians
    @hold_short_point = [
      @position.x + Math.cos(angle) * distance_from_center,
      @position.y + Math.sin(angle) * distance_from_center,
    ]
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
      {
        x: x, y: y,
        w: DEPARTURE_SIZE, h: DEPARTURE_SIZE,
        angle: @heading + 90,
        path: "sprites/aircraft/#{departure[:type]}.png",
        anchor_x: 0.5,
        anchor_y: 0.5,
        **RUNWAY_COLORS[type],
      },
    ]
  end

  def hold_short_label
    x, y = @hold_short_point
    angle = @heading.to_radians
    x += Math.cos(angle) * HOLD_SHORT_LABEL_PADDING
    y += Math.sin(angle) * HOLD_SHORT_LABEL_PADDING

    seconds = @departure.timer.to_seconds

    {
      x: x, y: y,
      text: seconds,
      size_px: HOLD_SHORT_LABEL_SIZE,
      anchor_x: 0.5,
      anchor_y: 0.5,
      **(seconds > 10 ? WHITE : RED),
    }
  end

  def mouse_in_tdz?
    @mouse.inside_circle?(@position, @tdz_radius)
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
    }
  end
end
