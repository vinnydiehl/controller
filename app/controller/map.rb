class Map
  attr_accessor :name, :id, :path, :runways

  def initialize(path:, type:, name: "", id: "", runways: [])
    @name, @id, @path, @type, @runways = name, id, path, type, runways

    @grid = $args.grid

    if type == :tiled
      @tmx = Tiled::Map.new(path).tap(&:load)
    end
  end

  def sprite
    if @type == :tiled
      @tmx.layers.map(&:sprites)
    else
      {
        x: 0, y: 0,
        w: @grid.w, h: @grid.h,
        path: path,
      }
    end
  end

  def to_h
    { name: @name, id: @id, runways: @runways.map(&:to_h) }
  end

  def deep_dup
    dup.tap { |m| m.runways = m.runways.map(&:dup) }
  end
end

# Map serialization/deserialization
class ControllerGame
  def load_map(id)
    @map = map_for_id(filename)

    load_aircraft_types
  end

  def save_map
    @args.gtk.write_file(
      "maps/#{@map.id}/#{@map.id}.dat",
      @map.to_h.to_json(indent_size: 2, extensions: true),
    )
  end

  def map_for_id(id)
    # Path including filename without extension
    filename = "maps/#{id}/#{id}"

    # TMX or PNG?
    if @args.gtk.stat_file("#{filename}.tmx")
      type = :tiled
      path = "#{filename}.tmx"
    elsif @args.gtk.stat_file("#{filename}.png")
      type = :image
      path = "#{filename}.png"
    else
      raise StandardError.new("Map image/TMX not found.")
    end


    if @args.gtk.stat_file("#{filename}.dat")
      map_data = Argonaut::JSON.parse(
        @args.gtk.read_file("#{filename}.dat"),
        symbolize_keys: true,
        extensions: true,
      )
      map_data[:runways].map! { |r| Runway.new(**r) }
      Map.new(path: path, type: type, **map_data)
    else
      # No .dat file is fine, we might want to make one with
      # the map editor
      Map.new(path: path, type: type, id: id)
    end
  end

  # Load the aircraft types that are able to land on the current map
  def load_aircraft_types
    colors = @map.runways.map { |r| r.type }.uniq
    @aircraft_types = AIRCRAFT_TYPES.select { |t| colors.include?(t[:runway]) }
  end
end
