class ControllerGame
  def render_map_editor
    render_map
    render_runway_markers

    if @active_runway
      render_runway_input
    end

    if @heading_start_point
      render_heading_guide
    end
  end

  def render_runway_markers
    @map.runways.each do |runway|
      render_tdz(runway)
      render_heading(runway)
    end
  end

  def render_tdz(runway)
    size = runway.tdz_radius * 2

    @primitives << {
      x: runway.position.x, y: runway.position.y,
      w: size, h: size,
      anchor_x: 0.5, anchor_y: 0.5,
      path: "sprites/map_editor/circle.png",
      **(active?(runway) ? MAP_EDITOR_ACTIVE_COLOR : RUNWAY_COLORS[runway.type]),
      a: 150,
    }
  end

  def render_heading(runway)
    @primitives << {
      x: runway.position.x, y: runway.position.y,
      w: 75, h: 20,
      anchor_x: 0, anchor_y: 0.5,
      angle_anchor_x: 0, angle_anchor_y: 0.5,
      angle: runway.heading,
      path: "sprites/map_editor/arrow.png",
      **(active?(runway) ? MAP_EDITOR_ACTIVE_COLOR : RUNWAY_COLORS[runway.type]),
      a: 150,
    }
  end

  def render_runway_input
    @primitives << @runway_input_box
    @primitives << @runway_name_input

    { 11 => "Name:", 11.5 => "Color:" }.each do |row, text|
      @primitives << Layout.rect(row: row, col: 0.75).merge(
        text: text,
        anchor_x: 0.5,
        anchor_y: 0,
        **MAP_EDITOR_INPUT_TEXT_COLOR,
      )
    end
  end

  def render_heading_guide
    @primitives << {
      x: @heading_start_point.x,
      y: @heading_start_point.y,
      x2: @mouse.x,
      y2: @mouse.y,
      **MAP_EDITOR_ACTIVE_COLOR,
    }
  end
end
