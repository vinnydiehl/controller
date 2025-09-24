SCENES = %w[game map_editor].freeze

require "lib/json.rb"

%w[constants colors controller
   aircraft input map runway].each { |f| require "app/controller/#{f}.rb" }

require "app/controller/render/shared.rb"

%w[scenes render].each { |dir| SCENES.each { |f| require "app/controller/#{dir}/#{f}.rb" } }

def tick(args)
  args.state.game ||= ControllerGame.new(args)
  args.state.game.tick
end
