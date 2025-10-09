class ControllerGame
  def map_select_menu_init
    # Index of currently selected map
    @map_i = 0

    @thumbnail_rect = {
      x: @cx, y: @cy,
      w: @screen.w / THUMBNAIL_SIZE_DIVIDEND,
      h: @screen.h / THUMBNAIL_SIZE_DIVIDEND,
      anchor_x: 0.5,
      anchor_y: 0.5,
    }

    # Forward and back buttons
    @arrows = [
      {
        x: @cx + (@screen.w / THUMBNAIL_SIZE_DIVIDEND / 2) + THUMBNAIL_PADDING,
        y: @cy,
        w: 40,
        h: 100,
        path: "sprites/ui/chevron.png",
        a: ARROW_ALPHA,
        anchor_x: 0,
        anchor_y: 0.5,
        value: 1,
        grey_out: @maps.size - 1,
      },
      {
        x: @cx - (@screen.w / THUMBNAIL_SIZE_DIVIDEND / 2) - THUMBNAIL_PADDING,
        y: @cy,
        w: 40,
        h: 100,
        path: "sprites/ui/chevron.png",
        a: ARROW_ALPHA,
        anchor_x: 1,
        anchor_y: 0.5,
        flip_horizontally: true,
        value: -1,
        grey_out: 0,
      },
    ]
  end

  def map_select_menu_tick
    handle_map_select_menu_mouse_inputs
    handle_map_select_menu_kb_inputs
  end

  def handle_map_select_menu_mouse_inputs
    if @mouse.key_down?(:left)
      handle_map_select_menu_click
    end

    handle_map_select_menu_scroll
  end

  def handle_map_select_menu_click
    @arrows.each do |button|
      if @mouse.intersect_rect?(button)
        scroll_map(button[:value])
        return
      end
    end
  end

  def handle_map_select_menu_scroll
    return unless (d = @mouse.wheel&.y) && @mouse.intersect_rect?(@thumbnail_rect)

    orig = @map_i
    # Invert sign so scrolling down increases map index
    if scroll_map(d * -1)
      # Pulse the arrow in the direction that we scrolled
      button_i = @map_i > orig ? 0 : 1
      @arrows[button_i][:a] = ARROW_BRIGHT_ALPHA
    end
  end

  def handle_map_select_menu_kb_inputs
    if @kb.key_down.right
      scroll_map(1)
      return
    end

    if @kb.key_down.left
      scroll_map(-1)
      return
    end

    if @kb.key_down.enter
      @map = selected_map
      load_aircraft_types
      play_sound(:start_game)
      set_scene(:game)
    end
  end

  # Adjusts @map_i by +delta+, not exceeding the bounds of the indices of @maps.
  # Returns the new @map_i if successful, nil if unsuccessful.
  def scroll_map(delta)
    orig = @map_i
    @map_i = (@map_i + delta).clamp(0, @maps.size - 1)

    if @map_i == orig
      nil
    else
      play_sound(:scroll)
      @map_i
    end
  end

  def selected_map
    @maps[@map_i]
  end
end
