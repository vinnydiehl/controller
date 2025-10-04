AIRCRAFT_TYPES = [
  {
    type: :widebody,
    speed: 30,
    runway: :blue,
    vtol: false,
  },
  {
    type: :turboprop,
    speed: 20,
    runway: :red,
    vtol: false,
  },
  {
    type: :single_engine_piston,
    speed: 15,
    runway: :yellow,
    vtol: false,
  },
  {
    type: :seaplane,
    speed: 15,
    runway: :green,
    vtol: false,
  },
  {
    type: :helicopter,
    speed: 10,
    runway: :orange,
    vtol: true,
  },
]

# Size of runway surface middle sprites
SURFACE_INCREMENT = {
  nil => 1,
  cement: 4,
  grass: 8,
}

AIRCRAFT_SIZE = 32
AIRCRAFT_RADIUS = AIRCRAFT_SIZE / 2

# Path smoothing:
# Below this angle triggers smoothing with min points
MIN_ANGLE_THRESHOLD = 120.0
# Below this angle inserts max points (between these two it interpolates)
MAX_ANGLE_THRESHOLD = 70.0
# Min points to insert
MIN_CURVE_STEPS = 2
# Max points to insert
MAX_CURVE_STEPS = 10
# How much to flatten the corner, from 0-1
CORNER_FLATTEN = 0.5

# How far off the screen an aircraft spawns
SPAWN_PADDING = AIRCRAFT_SIZE * 3
# For spacing out spawns. Testing with a retry limit of 10 I could
# always get 20 aircraft spawned at once, and when trying to spawn
# 50 I always got at least 30, which is more than good enough.
SPAWN_RETRY_LIMIT = 10
SPAWN_BUFFER = AIRCRAFT_RADIUS * 4

# Pixels between points in an aircraft's path (for path smoothing)
MIN_DIST = 8.0

# Number of path waypoints reserved for final approach
# (used for determining runway alignment and smoothing the last
# segment of the path when an aircraft is cleared for landing)
FINAL_APPROACH_BUFFER = 5
# +/- degrees for acceptable final approach runway alignment
FINAL_APPROACH_TOLERANCE = 45

# We calculate how much time it takes an emergency aircraft to reach
# the nearest runway. This is how much extra time the player should get,
# in seconds
EMERGENCY_TIME_BUFFER = 5

# Runway rendering
RWY_WIDTH = 32

# Departing aircraft
DEPARTURE_TIME = 60.seconds
DEPARTURE_SIZE = AIRCRAFT_SIZE / 2
HOLD_SHORT_DISTANCE = 15
HOLD_SHORT_LABEL_SIZE = 15
HOLD_SHORT_LABEL_PADDING = 20

# Map editor stuff
KEY_HOLD_DELAY = 0.5.seconds
RWY_DEFAULTS = {
  tdz_radius: 20,
  heading: 0,
  length: RWY_WIDTH * 6,
  surface: :cement,
}
RWY_MIN_LENGTH = RWY_WIDTH * 3
HELI_OPTIONS = [nil, :square, :circle]

# Translates a direction to an angle
ANGLE = {
  right: 0,
  up: 90,
  left: 180,
  down: 270,
}
