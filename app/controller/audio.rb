class ControllerGame
  def play_sound(name)
    @outputs.sounds << { input: "sounds/#{name}.mp3" }
  end
end
