ARROW_ALPHA = 100
ARROW_GREY_OUT_ALPHA = 25
ARROW_BRIGHT_ALPHA = 255

class ControllerGame
  def render_map_select_menu
    render_background

    render_name_label
    render_arrows
    render_thumbnail

    render_buttons
  end

  def render_name_label
    @primitives << {
      x: @cx, y: @screen.h * 0.8,
      text: selected_map.name,
      size_enum: 10,
      **WHITE,
      anchor_x: 0.5,
      anchor_y: 0.5,
    }
  end

  def render_arrows
    @arrows.each do |button|
      if button[:grey_out] == @map_i
        button[:a] = ARROW_GREY_OUT_ALPHA
      else
        if button[:a] == ARROW_GREY_OUT_ALPHA
          button[:a] = ARROW_ALPHA
        end

        # We're going to be pulsing the arrows white on hover, this makes it fade back.
        # Doing this before setting bright alpha so there is no flickering
        button[:a] -= 1 if button[:a] > ARROW_ALPHA

        # Pulse button white on hover
        button[:a] = ARROW_BRIGHT_ALPHA if @mouse.intersect_rect?(button)
      end

      @primitives << button
    end
  end

  def render_thumbnail
    @primitives << {
      **@thumbnail_rect,
      path: "sprites/thumbnails/#{selected_map.id}.png",
    }
  end

  def render_buttons
    @primitives << @buttons
  end
end
