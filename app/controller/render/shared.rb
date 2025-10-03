class ControllerGame
  def render_map
    @primitives << @map.sprite
  end

  def render_runways
    @map.runways.each_with_index { |r, i| render_runway(r, i) }
  end

  # Renders an individual runway. +id+ needs to be unique, we can just
  # use the index (since names might not be set or might be the same
  # it's unwise to use that).
  def render_runway(runway, id)
    target = "runway_#{id}"

    @outputs[target].w = runway.length
    @outputs[target].h = RWY_WIDTH
    middle_length = runway.length - (RWY_WIDTH * 2)

    # Surface
    if runway.surface
      if runway.helipad
        @outputs[target].primitives << {
          x: 0, y: 0,
          w: RWY_WIDTH, h: RWY_WIDTH,
          path: "sprites/runway/surfaces/#{runway.surface}/#{runway.helipad}.png"
        }
      else
        middle_width = SURFACE_INCREMENT[runway.surface]

        @outputs[target].primitives << [
          # Approach end
          {
            x: 0, y: 0,
            w: RWY_WIDTH, h: RWY_WIDTH,
            path: "sprites/runway/surfaces/#{runway.surface}/aer.png",
          },
          # Departure end
          {
            x: runway.length - RWY_WIDTH, y: 0,
            w: RWY_WIDTH, h: RWY_WIDTH,
            path: "sprites/runway/surfaces/#{runway.surface}/der.png",
          },
        ]
        (middle_length / middle_width).to_i.times do |i|
          @outputs[target].primitives << {
            x: RWY_WIDTH + (middle_width * i), y: 0,
            w: middle_width, h: RWY_WIDTH,
            path: "sprites/runway/surfaces/#{runway.surface}/middle.png",
          }
        end
      end
    end

    # Outline
    if runway.helipad
      @outputs[target].primitives << {
        x: 0, y: 0,
        w: RWY_WIDTH, h: RWY_WIDTH,
        path: "sprites/runway/outline/heli_#{runway.helipad}.png",
        **RUNWAY_COLORS[runway.type],
      }
    else
      @outputs[target].primitives << [
        # Threshold
        {
          x: 0, y: 0,
          w: RWY_WIDTH, h: RWY_WIDTH,
          path: "sprites/runway/outline/threshold.png",
          **RUNWAY_COLORS[runway.type],
        },
        # Middle
        {
          x: RWY_WIDTH, y: 0,
          w: middle_length, h: RWY_WIDTH,
          path: "sprites/runway/outline/middle.png",
          **RUNWAY_COLORS[runway.type],
        },
        # Departure end
        {
          x: runway.length - RWY_WIDTH, y: 0,
          w: RWY_WIDTH, h: RWY_WIDTH,
          path: "sprites/runway/outline/der.png",
          **RUNWAY_COLORS[runway.type],
        },
      ]
    end

    anchor_x = (RWY_WIDTH / 2) / runway.length

    @primitives << {
      x: runway.position.x, y: runway.position.y,
      w: runway.length, h: RWY_WIDTH,
      angle: runway.heading,
      anchor_x: anchor_x, anchor_y: 0.5,
      angle_anchor_x: anchor_x, angle_anchor_y: 0.5,
      path: target,
    }
  end
end
