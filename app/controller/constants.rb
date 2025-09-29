AIRCRAFT_TYPES = [
  {
    type: :widebody,
    speed: 30,
    runway: :blue,
    vtol: false,
    sprite: "sprites/circle/blue.png",
  },
  {
    type: :single_engine_piston,
    speed: 15,
    runway: :yellow,
    vtol: false,
    sprite: "sprites/circle/yellow.png",
  },
  {
    type: :helicopter,
    speed: 10,
    runway: :orange,
    vtol: true,
    sprite: "sprites/circle/orange.png",
  },
]

AIRCRAFT_SIZE = 32
AIRCRAFT_RADIUS = AIRCRAFT_SIZE / 2

# How far off the screen an aircraft spawns
SPAWN_PADDING = AIRCRAFT_SIZE * 3

# Pixels between points in an aircraft's path (for path smoothing)
MIN_DIST = 8.0

# Number of path waypoints reserved for final approach
# (used for determining runway alignment and smoothing the last
# segment of the path when an aircraft is cleared for landing)
FINAL_APPROACH_BUFFER = 5
# +/- degrees for acceptable final approach runway alignment
FINAL_APPROACH_TOLERANCE = 45

# Runway rendering
RWY_WIDTH = 32
RWY_MIDDLE_TILE_WIDTH = RWY_WIDTH / 8

# Map editor stuff
KEY_HOLD_DELAY = 0.5.seconds
RWY_DEFAULTS = {
  tdz_radius: 20,
  heading: 0,
  length: RWY_WIDTH * 6,
  surface: :cement,
}
RWY_MIN_LENGTH = RWY_WIDTH * 3
RWY_SURFACES = [nil, :cement]
HELI_OPTIONS = [nil, :square, :circle]
