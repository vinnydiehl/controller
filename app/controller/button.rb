class Button
  attr_sprite
  attr_reader :on_click

  def initialize(x:, y:, w:, h:, on_click:, text: nil, path: nil)
    options = [text, path]
    if options.all? || options.none?
      raise StandardError.new(
        "Either text or path must be set for a Button (but not both)"
      )
    end

    @x, @y, @w, @h, @on_click, @text, @path = x, y, w, h, on_click, text, path
    @cx, @cy = @x + @w / 2, @y + @h / 2,

    @mouse_over = false
  end

  def tick
    handle_mouse
  end

  def handle_mouse
    mouse = $args.inputs.mouse
    @mouse_over = mouse.inside_rect?(self)
    return unless @mouse_over

    @on_click.call if mouse.up
  end

  def draw_override(ffi)
    if @mouse_over
      ffi.draw_solid(
        @x, @y, @w, @h,
        BUTTON_HIGHLIGHT_VALUE,
        BUTTON_HIGHLIGHT_VALUE,
        BUTTON_HIGHLIGHT_VALUE,
        255
      )
    else
      ffi.draw_solid(
        @x, @y, @w, @h,
        BUTTON_COLOR_VALUE,
        BUTTON_COLOR_VALUE,
        BUTTON_COLOR_VALUE,
        255
      )
    end

    if @text
      # ffi.draw_label_5(
      #   x, y,
      #   text, size_enum, alignment_enum,
      #   r,
      #   g,
      #   b,
      #   a,
      #   font,
      #   vertical_alignment_enum,
      #   blendmode_enum,
      #   size_px,
      #   angle_anchor_x, angle_anchor_y
      # )
      ffi.draw_label_5(
        @cx, @cy,
        @text, nil, 1,
        BUTTON_TEXT_VALUE,
        BUTTON_TEXT_VALUE,
        BUTTON_TEXT_VALUE,
        255,
        "",
        1,
        1,
        @h - 10,
        0.5, 0.5,
      )
    elsif @path
      ffi.draw_sprite(@x, @y, @w, @h, @path)
    end
  end
end
