CHOICE_BOX_WIDTH = 400
CHOICE_BOX_HEIGHT = 100
CHOICES_PADDING = 50
CHOICE_TEXT_SIZE = 6
CHOICE_SUBTEXT_SIZE = 0
SUBTEXT_PADDING = 5

class Menu
  def initialize(args, choices)
    @primitives = args.outputs.primitives
    @mouse = args.inputs.mouse
    @sounds = args.outputs.sounds

    @screen_width = args.grid.w
    @cx = args.grid.w / 2
    @screen_height = args.grid.h
    @cy = args.grid.h / 2

    @choices = choices

    @sound_played = true
  end

  def tick
    mbp = mouse_box_pos
    if mbp && !@sound_played
      @sounds << { input: "sounds/button_hover.mp3" }
      @sound_played = true
    elsif !mbp
      @sound_played = false
    end

    if @mouse.key_down?(:left) && (i = mouse_box_pos)
      @choices.values[i].call
    end
  end

  def render_choices(subtext: nil)
    @choices.each_with_index do |(name, _), i|
      render_choice_box(i)
      render_choice_text(name.to_capitalized_str, i)
      render_choice_subtext(subtext[i], i) if subtext
    end
  end

  private

  # If over a choice box, return the index of that box, otherwise
  # return nil
  def mouse_box_pos
    (0...@choices.size).to_a.find do |i|
      @mouse.intersect_rect?(choice_rect(i))
    end
  end

  # The centerpoint of a choice box
  def choice_point(i)
    separation = (@screen_height - (CHOICES_PADDING * 2)) / @choices.count
    [
      @cx,
      @screen_height - (separation * i + separation / 2 + CHOICES_PADDING),
    ]
  end

  def choice_rect(i)
    x, y = choice_point(i)

    {
      x: x - CHOICE_BOX_WIDTH / 2, y: y - CHOICE_BOX_HEIGHT / 2,
      w: CHOICE_BOX_WIDTH, h: CHOICE_BOX_HEIGHT,
    }
  end

  def render_choice_box(i)
    @primitives << {
      primitive_marker: :solid,
      **choice_rect(i),
      **(mouse_box_pos == i ? MENU_BUTTON_HIGHLIGHT_COLOR : MENU_BUTTON_COLOR),
    }
    @primitives << {
      primitive_marker: :border,
      **choice_rect(i),
      **MENU_BUTTON_BORDER_COLOR,
    }
  end

  def render_choice_text(str, i)
    x, y = choice_point(i)

    @primitives << {
      x: x, y: y,
      text: str,
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      size_enum: CHOICE_TEXT_SIZE,
      r: 255, g: 255, b: 255,
    }
  end

  def render_choice_subtext(str, i)
    x, y = choice_point(i)

    @primitives << {
      x: x + (CHOICE_BOX_WIDTH / 2) - (SUBTEXT_PADDING * 1.5),
      y: y - (CHOICE_BOX_HEIGHT / 2) + SUBTEXT_PADDING,
      text: str,
      alignment_enum: 2,
      vertical_alignment_enum: 0,
      size_enum: CHOICE_SUBTEXT_SIZE,
      r: 255, g: 255, b: 255,
    }
  end
end
