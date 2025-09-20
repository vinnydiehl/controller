SCENES = %w[game].freeze

%w[constants colors controller aircraft].each { |f| require "app/controller/#{f}.rb" }

%w[scenes render].each { |dir| SCENES.each { |f| require "app/controller/#{dir}/#{f}.rb" } }

def tick(args)
  args.state.game ||= ControllerGame.new(args)
  args.state.game.tick
end
