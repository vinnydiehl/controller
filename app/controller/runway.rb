class Runway
  attr_accessor :heading

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
    tdz_radius = @width / 2
    tdz_x = @position.x + Math.cos(@heading.to_radians) * tdz_radius
    tdz_y = @position.y + Math.sin(@heading.to_radians) * tdz_radius

    [
      {
        x: @position.x, y: @position.y,
        w: @length, h: @width,
        angle: @heading,
        path: :"runway_#{@name}",
        anchor_x: 0,
        anchor_y: 0.5,
        angle_anchor_x: 0,
        angle_anchor_y: 0.5,
      },
      # Touchdown zone (this is just for testing)
      {
        x: tdz_x, y: tdz_y,
        w: @width, h: @width,
        path: "sprites/circle/blue.png",
        r: 255, g: 0, b: 0,
        anchor_x: 0.5,
        anchor_y: 0.5,
      },
    ]
  end
end
