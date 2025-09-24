class Runway
  attr_accessor :heading, :position, :type

  def initialize(type:, name:, position:, tdz_radius:, heading:)
    @type, @name, @position, @tdz_radius, @heading =
      type, name, position, tdz_radius, heading

    @mouse = $gtk.args.inputs.mouse
  end

  def mouse_in_tdz?
    @mouse.inside_circle?(@position, @tdz_radius)
  end
end
