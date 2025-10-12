class Birds
  attr_reader :position

  def initialize(position)
    @position = position

    @speed_px = BIRDS_SPEED / 60

    @screen = $gtk.args.grid.rect

    # Spawns pointing towards the center, +/- 45 degrees
    @course = @position.angle_to([@screen.w / 2, @screen.h / 2]) +
              Numeric.rand(-45..45)
    @course %= 360

    @offscreen = true
  end

  def tick
    @position = Geometry.vec2_add(
      @position,
      [
        Math.cos(@course.to_radians) * @speed_px,
        Math.sin(@course.to_radians) * @speed_px,
      ],
    )
    @offscreen = false if @offscreen && rect.inside_rect?(@screen)
  end

  def rect
    {
      x: @position.x, y: @position.y,
      w: BIRDS_SIZE, h: BIRDS_SIZE,
      anchor_x: 0.5, anchor_y: 0.5,
    }
  end

  def sprite
    {
      **rect,
      path: "sprites/hazards/birds.png",
      angle: @course,
      tile_x: 0.frame_index(6, 10, true) * BIRDS_SIZE,
      tile_w: BIRDS_SIZE,
      tile_h: BIRDS_SIZE,
    }
  end

  def hitbox
    Geometry.rect_to_circle(rect).tap { |c| c[:radius] /= 1.5 }
  end

  def offscreen?
    @offscreen
  end

  # Birds only affect a collision when they're at least halfway on-screen,
  # this prevents weird behavior around the edges e.g. with departures
  def collideable?
    @position.inside_rect?(@screen)
  end
end
