class ExhaustPlume
  EXHAUST_PLUME_FRAMES = 16

  def initialize(start_tick, position, angle)
    @start_tick, @position, @angle = start_tick, position, angle
  end

  def sprite
    frame_index = @start_tick.frame_index(EXHAUST_PLUME_FRAMES, 10, false)

    # Kill the exhaust plume if the sprite is done animating
    if !frame_index
      dead = true
      return
    end

    {
      x: @position.x, y: @position.y,
      w: AIRCRAFT_SIZE, h: AIRCRAFT_SIZE,
      anchor_x: 0.5, anchor_y: 0.5,
      path: "sprites/aircraft/exhaust.png",
      angle: @angle,
      tile_x: frame_index * AIRCRAFT_SIZE,
      tile_w: AIRCRAFT_SIZE, tile_h: AIRCRAFT_SIZE,
    }
  end

  def dead?
    !!@dead
  end
end
