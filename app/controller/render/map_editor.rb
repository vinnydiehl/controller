class ControllerGame
  def render_map_editor
    render_map

    render_runways
    render_runway_markers

    render_map_input
    if @active_runway
      render_runway_input
      render_runway_info
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
      # First surface is nil so only render 1..-1
      @runway_surface_buttons[1..-1].map do |btn|
        btn.merge(path: "sprites/runway/#{btn.surface}/square.png")
      end,
      # Border
      @runway_input_box.merge(primitive_marker: :border, **BORDER_COLOR),
    ]

    # Border around active runway type
    @primitives << Layout.rect(
      row: 11,
      col: 1.5 + (0.5 * RUNWAY_COLORS.keys.find_index { |t| t == @active_runway.type }),
      w: 0.5,
      h: 0.5,
    ).merge(primitive_marker: :border, **WHITE)

    # Border around active runway surface (appears under surface button)
    @primitives << Layout.rect(
      row: 11.5,
      col: 1.5 + (0.5 * RWY_SURFACES.find_index { |t| t == @active_runway.surface }),
      w: 0.5,
      h: 0.5,
    ).merge(primitive_marker: :border, **WHITE)
    # Render color for current runway type over each surface
    @runway_surface_buttons.each do |button|
      @primitives << button.merge(
        path: "sprites/runway/outline/square.png",
        **RUNWAY_COLORS[@active_runway.type],
      )
    end

    # Helipad button
    heli_path = if @active_runway.helipad
      "sprites/runway/outline/#{@active_runway.helipad}.png"
    else
      "sprites/map_editor/x.png"
    end
    heli_color = @active_runway.helipad ? RUNWAY_COLORS[@active_runway.type] : WHITE
    @primitives << @heli_button.merge(path: heli_path, **heli_color)

    # Labels
    %w[Name Color Surface Heli].each_with_index do |text, i|
      @primitives << Layout.point(row: 9.8 + (0.5 * i), col: 1.3).merge(
        text: "#{text}:",
        size_px: 15,
        anchor_x: 1,
        anchor_y: 0.5,
        **MAP_EDITOR_INPUT_TEXT_COLOR,
      )
    end
  end

  def render_runway_info
    # Box
    @primitives << [
      @runway_info_box,
      @runway_info_box.merge(primitive_marker: :border, **BORDER_COLOR),
    ]

    # Labels
    {
      "Position" => @active_runway.position.map(&:to_i),
      "Heading" => @active_runway.heading.to_i,
      "Length" => @active_runway.helipad ? "N/A" : @active_runway.length.to_i,
      "TDZ Radius" => @active_runway.tdz_radius.to_i,
    }.each_with_index do |(label, value), i|
      @primitives << Layout.point(
        row: 10.55 + (0.4 * i),
        col: 22,
        row_anchor: 0.5,
        col_anchor: 0.5,
      ).merge(
        text: "#{label}: #{value}",
        size_px: 15,
        anchor_x: 0.5,
        anchor_y: 0.5,
        **WHITE,
      )
    end
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
