AIRCRAFT_SIZE = 32
AIRCRAFT_RADIUS = AIRCRAFT_SIZE / 2
# Pixels/second
AIRCRAFT_SPEED = 25

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
