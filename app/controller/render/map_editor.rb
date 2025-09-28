class ControllerGame
  def render_map_editor
    render_map
    render_runway_markers

    render_map_input
    if @active_runway
      render_runway_input
    end

    if @heading_start_point
      render_heading_guide
    end

    render_exit_button
    if @display_save_modal
      render_save_modal
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

  def render_map_input
    @primitives << [
      @map_input_box,
      @map_name_input,
      @map_id_input,
      # Border
      @map_input_box.merge(primitive_marker: :border, **BORDER_COLOR),
    ]

    # Labels
    { -1 => "Name:", -0.5 => "ID:" }.each do |row, text|
      @primitives << Layout.rect(row: row, col: 1.3).merge(
        text: text,
        anchor_x: 1,
        anchor_y: 0,
        **MAP_EDITOR_INPUT_TEXT_COLOR,
      )
    end
  end

  def render_runway_input
    @primitives << [
      @runway_input_box,
      @runway_name_input,
      @runway_type_buttons,
      # Border
      @runway_input_box.merge(primitive_marker: :border, **BORDER_COLOR),
    ]

    # Border around active runway type
    @primitives << Layout.rect(
      row: 12,
      col: 1.5 + (0.5 * RUNWAY_COLORS.keys.find_index { |t| t == @active_runway.type }),
      w: 0.5,
      h: 0.5,
    ).merge(primitive_marker: :border, **WHITE)

    # Labels
    { 11 => "Name:", 11.5 => "Color:" }.each do |row, text|
      @primitives << Layout.rect(row: row, col: 1.3).merge(
        text: text,
        anchor_x: 1,
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

  def render_exit_button
    @primitives << @exit_button
  end

  def render_save_modal
    @primitives << [
      @save_modal,
      @save_modal.merge(primitive_marker: :border, **BORDER_COLOR),
      @save_buttons,
    ]

    @primitives << {
      **Layout.rect(
        row: 4.5, col: 12,
      ),
      anchor_x: 0.5,
      anchor_y: 0.5,
      text: "Save changes?",
      **WHITE,
    }
  end
end
