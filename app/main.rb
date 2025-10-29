SCENES = %w[game map_editor map_select_menu pause_menu]

%w[hash numeric object symbol].each { |f|  require "lib/core_ext/#{f}.rb" }
%w[tiled/tiled json input].each { |f| require "lib/#{f}.rb" }

%w[constants colors button controller
   aircraft audio birds exhaust_plume input map
   menu runway].each { |f| require "app/controller/#{f}.rb" }

require "app/controller/render/shared.rb"

%w[scenes render].each { |dir| SCENES.each { |f| require "app/controller/#{dir}/#{f}.rb" } }

# Disable warnings
%i[consider_smooth! use_audio_for_looping_tracks].each do |id|
  str = [id].to_s
  # Hack to make DRGTK think the warning has been displayed already
  once = GTK::Log.instance_variable_get("@once") || {}
  once[str] = str
  GTK::Log.instance_variable_set("@once", once)
end

def tick(args)
  args.state.game ||= ControllerGame.new(args)
  args.state.game.tick
end
