# Direction lookup table for keyboard commands
KB_DIRECTIONS = {
  right: [1, 0],
  left: [-1, 0],
  up: [0, 1],
  down: [0, -1],
}

class ControllerGame
  def map_editor_init
    @runway_held = nil
    @active_runway = nil

    @hold_delay = 0

    # Map input
    @map_input_box = Layout.rect(
      row: -0.5,
      col: 0,
      w: 4,
      h: 1,
      include_row_gutter: true,
      include_col_gutter: true
    ).merge(primitive_marker: :solid, **MAP_EDITOR_INPUT_BG_COLOR)
    @map_name_input = Input::Text.new(
      **Layout.rect(
        row: -0.5,
        col: 1.5,
        w: 2.5,
        h: 0.5,
      ),
      prompt: "Name",
      value: @map.name,
      size_px: 20,
      **INPUT_COLORS,
      on_unhandled_key: lambda do |key, input|
        case key
        when :enter
          input.blur
        when :tab
          input.blur
          @map_id_input.focus
          @map_id_input.select_all
        end
      end,
      on_clicked: lambda do |_mouse, input|
        input.focus
        @map_id_input.blur
      end,
      max_length: 40,
    )
    @map_id_input = Input::Text.new(
      **Layout.rect(
        row: 0,
        col: 1.5,
        w: 2.5,
        h: 0.5,
      ),
      prompt: "ID",
      value: @map.id,
      size_px: 20,
      **INPUT_COLORS,
      on_unhandled_key: lambda do |key, input|
        case key
        when :enter
          input.blur
        end
      end,
      on_clicked: lambda do |_mouse, input|
        input.focus
        @map_name_input.blur
      end,
      max_length: 40,
    )

    # Runway input
    @runway_input_box = Layout.rect(
      row: 11.5,
      col: 0,
      w: 4,
      h: 1,
      include_row_gutter: true,
      include_col_gutter: true
    ).merge(primitive_marker: :solid, **MAP_EDITOR_INPUT_BG_COLOR)
    @runway_name_input = Input::Text.new(
      **Layout.rect(
        row: 11.5,
        col: 1.5,
        w: 2.5,
        h: 0.5,
      ),
      prompt: "Name",
      value: "",
      size_px: 20,
      **INPUT_COLORS,
      on_unhandled_key: lambda do |key, input|
        case key
        when :enter
          input.blur
        end
      end,
      on_clicked: lambda do |_mouse, input|
        input.focus
      end,
      max_length: 40,
    )
    @runway_type_buttons = RUNWAY_COLORS.map.with_index do |(type, color), i|
      Layout.rect(
        row: 12,
        col: 1.5 + (0.5 * i),
        w: 0.5,
        h: 0.5,
      ).merge(primitive_marker: :solid, type: type, **color)
    end

    # Runway info
    @runway_info_box = Layout.rect(
      row: 11.25,
      col: 21,
      w: 3,
      h: 1.25,
      include_row_gutter: true,
      include_col_gutter: true
    ).merge(primitive_marker: :solid, **MAP_EDITOR_INPUT_BG_COLOR)

    # Save modal
    @display_save_modal = false
    @exit_button = Button.new(
      **Layout.rect(
        row: -0.5, col: 23.25, w: 0.75, h: 0.75,
      ).slice(:x, :y, :w, :h),
      on_click: -> { @display_save_modal = true },
      path: "sprites/map_editor/x.png",
    )
    @save_modal = Layout.rect(
      row: 5, col: 9,
      w: 6, h: 2,
      include_row_gutter: true,
      include_col_gutter: true
    ).merge(primitive_marker: :solid, **MAP_EDITOR_INPUT_BG_COLOR)
    @save_buttons = [
      Button.new(
        **Layout.rect(
          row: 6, col: 9.25, w: 2.75, h: 0.75,
        ).slice(:x, :y, :w, :h),
        on_click: -> do
          save_map
          set_scene_back
        end,
        text: "Save",
      ),
      Button.new(
        **Layout.rect(
          row: 6, col: 12, w: 2.75, h: 0.75,
        ).slice(:x, :y, :w, :h),
        on_click: -> { set_scene_back },
        text: "Discard",
      ),
      # Exit modal and do nothing
      Button.new(
        **Layout.rect(
          row: 5, col: 14.5, w: 0.5, h: 0.5,
        ).slice(:x, :y, :w, :h),
        on_click: -> { @display_save_modal = false },
        path: "sprites/map_editor/x_black.png",
      ),
    ]
  end

  def map_editor_tick
    if @display_save_modal
      @save_buttons.each(&:tick)
    else
      @exit_button.tick
    end

    @map_name_input.tick
    @map_id_input.tick
    # Edit map name/ID immediately on change
    if @map_name_input.value_changed?
      @map.name = @map_name_input.value.to_s
    end
    if @map_id_input.value_changed?
      @map.id = @map_id_input.value.to_s
    end

    if @active_runway
      @runway_name_input.tick
      # Edit runway name immediately on change
      if @runway_name_input.value_changed?
        @active_runway.name = @runway_name_input.value.to_s
      end
    end

    @hold_delay -= 1
    handle_map_editor_mouse_inputs
    handle_map_editor_kb_inputs
  end

  def handle_map_editor_mouse_inputs
    # Save modal should ignore all other inputs
    return if @display_save_modal

    if @mouse.intersect_rect?(@map_input_box)
      return
    elsif @mouse.key_down.left
      # Clicking outside the box blurs the inputs
      @map_name_input.blur
      @map_id_input.blur
    end

    if @active_runway
      # Runway type button click
      if @mouse.key_down.left &&
         (type = @runway_type_buttons.find { |b| @mouse.intersect_rect?(b) }&.type)
        @active_runway.type = type
      end

      # We're clicking within the box, don't do anything else
      if [@runway_input_box, @runway_info_box].any? { |b| @mouse.intersect_rect?(b) }
        return
      end
    end

    # Set active/held runway
    if @mouse.key_down.left
      # Unset active runway if we didn't click on one
      unless (runway = @map.runways.find(&:mouse_in_tdz?))
        @active_runway = nil
      end

      if active?(runway)
        # Runway already needs to be active to pick it up,
        # to prevent unintentional dragging
        @runway_held = runway
      else
        @active_runway = runway
        @runway_name_input.value = runway.name
        @runway_name_input.blur
      end
    end

    # Drag held runway
    if @mouse.key_held.left && @runway_held
      @runway_held.position = [@mouse.x, @mouse.y]
    end

    # Release held runway
    if @mouse.key_up.left && @runway_held
      @runway_held = nil
    end

    # Start drawing a heading line
    if @mouse.key_down.right && @active_runway
      @heading_start_point = [@mouse.x, @mouse.y]
    end

    # Release heading line
    if @mouse.key_up.right && @heading_start_point
      @active_runway.heading = @heading_start_point.angle_to(@mouse.position)
      @heading_start_point = nil
    end

    # Scroll to change TDZ radius
    if @active_runway && (d = @mouse.wheel&.y)
      @active_runway.tdz_radius += d
    end
  end

  def handle_map_editor_kb_inputs
    # Escape toggles save modal
    if @kb.key_down.escape
      @display_save_modal = !@display_save_modal
    end

    # Insert new runway
    if @kb.key_down.space
      @map.runways << Runway.new(
        type: :blue,
        name: "00",
        position: [@mouse.x, @mouse.y],
        tdz_radius: DEFAULT_TDZ_RADIUS,
        heading: DEFAULT_RWY_HEADING,
      )
      @active_runway = @map.runways.last
      return
    end

    # Tab to switch runways
    if @kb.key_down.tab
      # Select first runway if none is selected
      if !@active_runway
        @active_runway = @map.runways.first
        return
      end

      i = @map.runways.find_index(@active_runway)
      @active_runway = @map.runways[(i + 1) % @map.runways.size]
    end

    if @active_runway
      # Delete runway
      if @kb.key_down.delete
        @map.runways.delete(@active_runway)
        @active_runway = nil
        return
      end

      # Arrow key down
      KB_DIRECTIONS.each do |key, (dx, dy)|
        if @kb.key_down.send(key)
          @hold_delay = KEY_HOLD_DELAY
          @active_runway.position.x += dx
          @active_runway.position.y += dy
          return
        end
      end
      # Arrow key held
      if @hold_delay <= 0
        KB_DIRECTIONS.each do |key, (dx, dy)|
          if @kb.key_held.send(key)
            @active_runway.position.x += dx
            @active_runway.position.y += dy
            return
          end
        end
      end

      # Z and X for rotating heading
      if @kb.key_down.z
        @hold_delay = KEY_HOLD_DELAY
        @active_runway.heading = (@active_runway.heading + 1) % 360
      elsif @kb.key_down.x
        @hold_delay = KEY_HOLD_DELAY
        @active_runway.heading = (@active_runway.heading - 1) % 360
      end
      # Z/X held
      if @hold_delay <= 0
        if @kb.key_held.z
          @active_runway.heading = (@active_runway.heading + 1) % 360
        elsif @kb.key_held.x
          @active_runway.heading = (@active_runway.heading - 1) % 360
        end
      end
    end
  end

  def active?(runway)
    @active_runway == runway
  end
end
