class Runway
  attr_accessor :heading, :position, :type

  def initialize(name, heading, width, length, position, type)
    @name = name
    @heading = heading
    @width = width
    @length = length
    @position = position
    @type = type

    @mouse = $gtk.args.inputs.mouse

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
    border_color = case type
    when :blue
      { r: 0, g: 0, b: 255 }
    when :yellow
      { r: 255, g: 255, b: 0 }
    when :orange
      { r: 255, g: 92, b: 0 }
    end
    @outputs[:"runway_#{name}"].primitives << {
      primitive_marker: :border,
      x: 0, y: 0,
      w: length, h: width,
      **border_color,
    }
  end

  def sprite
    anchor_x = (@width / 2) / @length

    {
      x: @position.x, y: @position.y,
      w: @length, h: @width,
      angle: @heading,
      path: :"runway_#{@name}",
      # Anchor at the touchdown zone center
      anchor_x: anchor_x,
      anchor_y: 0.5,
      angle_anchor_x: anchor_x,
      angle_anchor_y: 0.5,
    }
  end

  def mouse_in_tdz?
    @mouse.inside_circle?(@position, @width / 2)
  end
end
