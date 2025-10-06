class ControllerGame
  def map_select_menu_init
    @maps = @args.gtk.list_files("maps").reject { |f| f.include?("tiled-") }
                                        .map { |id| map_for_id(id) }

    # Index of currently selected map
    @map_i = 0
  end

  def map_select_menu_tick
    handle_map_select_menu_mouse_inputs
  end

  def handle_map_select_menu_mouse_inputs
    if @kb.key_down.right
      @map_i += 1 unless @map_i == @maps.size - 1
      return
    end

    if @kb.key_down.left
      @map_i -= 1 unless @map_i == 0
      return
    end

    if @kb.key_down.enter
      @map = @maps[@map_i]
      set_scene(:game)
    end
  end

  def selected_map
    @maps[@map_i]
  end
end
