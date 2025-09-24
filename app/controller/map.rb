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
    { name: @name, runways: @runways.map(&:to_h) }
  end
end

# Map serialization/deserialization
class ControllerGame
  def load_map(name)
    map_data = Argonaut::JSON.parse(
      @args.gtk.read_file("data/maps/#{name}/map.dat"),
      symbolize_keys: true,
      extensions: true,
    )
    map_data[:runways].map! { |r| Runway.new(**r) }
    @map = Map.new(image: "data/maps/#{name}/image.png", **map_data)
  end

  def save_map(name)
    @args.gtk.write_file(
      "data/maps/#{name}/map.dat",
      @map.to_h.to_json(indent_size: 2, extensions: true),
    )
  end
end
