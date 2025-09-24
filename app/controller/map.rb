class Map
  attr_accessor :name, :image, :runways

  def initialize(name:, image:, runways: [])
    @name, @image, @runways = name, image, runways

    @grid = $args.grid
  end

  def sprite
    {
      x: 0, y: 0,
      w: @grid.w, h: @grid.h,
      path: image,
    }
  end

  def to_h
    { name: @name, image: @image, runways: @runways.map(&:to_h) }
  end
end
