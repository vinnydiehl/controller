class ControllerGame
  def render_map_select_menu
    render_background

    render_name_label
    render_thumbnail
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

  def render_thumbnail
    size_dividend = 2
    @primitives << {
      x: @cx, y: @cy,
      w: @screen.w / size_dividend,
      h: @screen.h / size_dividend,
      path: "sprites/thumbnails/#{selected_map.id}.png",
      anchor_x: 0.5,
      anchor_y: 0.5,
    }
  end
end
