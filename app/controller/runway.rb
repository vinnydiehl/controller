class Runway
  attr_accessor *%i[type name position length tdz_radius heading helipad surface]

  def initialize(type:, name:, position:, length:, tdz_radius:,
                 heading:, helipad:, surface:)
    @type, @name, @position, @length, @tdz_radius, @heading, @helipad, @surface=
      type, name, position, length, tdz_radius, heading, helipad, surface

    @mouse = $gtk.args.inputs.mouse
  end

  def mouse_in_tdz?
    @mouse.inside_circle?(@position, @tdz_radius)
  end

  def to_h
    {
      type: @type,
      name: @name,
      position: @position,
      length: @length,
      tdz_radius: @tdz_radius,
      heading: @heading,
      helipad: @helipad,
      surface: @surface,
    }
  end
end
