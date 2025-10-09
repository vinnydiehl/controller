def grayscale(v)
  { r: v, g: v, b: v }
end

WHITE = grayscale(255)
BLACK = grayscale(0)
RED = {
  r: 255, g: 0, b: 0,
}

BORDER_COLOR = grayscale(40)

BACKGROUND_COLOR = grayscale(63)

# Grayscale values for button colors
BUTTON_COLOR_VALUE = 45
BUTTON_HIGHLIGHT_VALUE = 70
BUTTON_TEXT_VALUE = 255
BUTTON_BORDER_VALUE = 0

MENU_BUTTON_COLOR = grayscale(BUTTON_COLOR_VALUE)
MENU_BUTTON_BORDER_COLOR = grayscale(BUTTON_BORDER_VALUE)
MENU_BUTTON_HIGHLIGHT_COLOR = grayscale(BUTTON_HIGHLIGHT_VALUE)

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
MAP_EDITOR_INPUT_BG_COLOR = BACKGROUND_COLOR
MAP_EDITOR_INPUT_TEXT_COLOR = WHITE

RUNWAY_COLORS = {
  blue: { r: 0, g: 0, b: 255 },
  red: RED,
  yellow: { r: 253, g: 209, b: 40 },
  green: { r: 151, g: 220, b: 33 },
  orange: { r: 255, g: 128, b: 0 },
}

THUMBNAIL_SIZE_DIVIDEND = 2
THUMBNAIL_PADDING = 20
