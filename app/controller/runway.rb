class Runway
  def initialize(name, heading, width, length, position)
    @name = name
    @heading = heading
    @width = width
    @length = length
    @position = position

    # Temporary sprite (just a gray solid render target)
    @outputs = $gtk.args.outputs
    @outputs[:"runway_#{name}"].width = length
    @outputs[:"runway_#{name}"].height = width
    @outputs[:"runway_#{name}"].primitives << {
      primitive_marker: :solid,
      x: 0, y: 0,
      w: length, h: width,
      r: 150, g: 150, b: 150,
    }
  end

  def sprite
    {
      x: @position.x, y: @position.y,
      w: @length, h: @width,
      angle: @heading,
      path: :"runway_#{@name}",
      angle_anchor_x: 0,
      angle_anchor_y: 0.5,
    }
  end
end
