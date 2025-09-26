class Map
  attr_accessor :name, :id, :image, :runways

  def initialize(name:, id:, image:, runways: [])
    @name, @id, @image, @runways = name, id, image, runways

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
    { name: @name, id: @id, runways: @runways.map(&:to_h) }
  end
end

# Map serialization/deserialization
class ControllerGame
  def load_map(id)
    map_data = Argonaut::JSON.parse(
      @args.gtk.read_file("data/maps/#{id}/map.dat"),
      symbolize_keys: true,
      extensions: true,
    )
    map_data[:runways].map! { |r| Runway.new(**r) }
    @map = Map.new(image: "data/maps/#{id}/image.png", **map_data)
  end

  def save_map(id)
    @args.gtk.write_file(
      "data/maps/#{id}/map.dat",
      @map.to_h.to_json(indent_size: 2, extensions: true),
    )
  end
end
