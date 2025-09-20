class ControllerGame
  def game_init
    @aircraft = [Aircraft.new]
  end

  def game_tick
    handle_mouse_inputs
    @aircraft.each(&:tick)
  end
end
