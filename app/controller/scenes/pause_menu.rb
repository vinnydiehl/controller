class ControllerGame
  def pause_menu_init
    choices = {
      main_menu: -> do
        set_scene(:map_select_menu, reset_stack: true)
        play_sound(:back)
      end,
      restart: -> do
        set_scene(:game, reset_stack: true)
        play_sound(:start_game)
      end,
      resume: method(:resume),
    }

    @menu = Menu.new(@args, choices)
  end

  def pause_menu_tick
    resume if @kb.key_down?(:escape)
    @menu.tick
  end

  def resume
    set_scene_back
    play_sound(:back)
  end
end
