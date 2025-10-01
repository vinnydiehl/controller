class ControllerGame
  def play_sound(name)
    @args.audio[GTK.create_uuid] = { input: "sounds/#{name}.mp3" }
  end
end
