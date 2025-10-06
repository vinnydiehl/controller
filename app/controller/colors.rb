def grayscale(v)
  { r: v, g: v, b: v }
end

WHITE = grayscale(255)
RED = {
  r: 255, g: 0, b: 0,
}

BORDER_COLOR = grayscale(40)

BACKGROUND_COLOR = grayscale(63)

PATH_COLOR = WHITE
CLEARED_TO_LAND_PATH_COLOR = RED
HOLD_PATH_COLOR = {
  r: 199, g: 110, b: 0,
}

INCOMING_COLOR = {
  r: 89, g: 86, b: 82,
}
INCOMING_EMERGENCY_COLOR = {
  r: 125, g: 22, b: 22,
}

COLLISION_COLOR = {
  **RED, a: 150,
}

INPUT_COLORS = {
  background_color: grayscale(80),
  blurred_background_color: grayscale(80),
  cursor_color: grayscale(150),
  text_color: grayscale(230),
  selection_color: grayscale(30),
}

MAP_EDITOR_ACTIVE_COLOR = WHITE
MAP_EDITOR_INPUT_BG_COLOR = grayscale(50)
MAP_EDITOR_INPUT_TEXT_COLOR = WHITE

RUNWAY_COLORS = {
  blue: { r: 0, g: 0, b: 255 },
  red: RED,
  yellow: { r: 253, g: 209, b: 40 },
  green: { r: 151, g: 220, b: 33 },
  orange: { r: 255, g: 128, b: 0 },
}

# Grayscale values for button colors
BUTTON_COLOR_VALUE = 100
BUTTON_HIGHLIGHT_VALUE = 150
BUTTON_TEXT_VALUE = 0
