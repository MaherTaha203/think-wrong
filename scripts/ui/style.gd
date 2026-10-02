extends RefCounted
class_name Style
## Central design tokens for a single, calm, premium visual identity. Dark-first.
## State is never conveyed by color alone (shape/label cues accompany color), and
## a high-contrast variant plus reduced-motion flag support accessibility.

# palette (standard)
const BG := Color("15131c")
const SURFACE := Color("201c2b")
const SURFACE_2 := Color("2b2640")
const INK := Color("e9e6f2")
const MUTED := Color("9a93b3")
const ACCENT := Color("c9a7ff")
const SUCCESS := Color("7ee0b0")
const DANGER := Color("ff8a8a")

# palette (high contrast)
const HC_BG := Color("000000")
const HC_INK := Color("ffffff")
const HC_ACCENT := Color("ffe14d")

# spacing / geometry
const GAP_S := 12
const GAP_M := 20
const GAP_L := 32
const RADIUS := 16
const BUTTON_H := 64
const TITLE_SIZE := 56
const H2_SIZE := 32
const BODY_SIZE := 24

# animation timings (seconds)
const T_FAST := 0.12
const T_MED := 0.22

static func high_contrast() -> bool:
	return bool(SaveManager.settings().get("high_contrast", false))

static func reduced_motion() -> bool:
	return bool(SaveManager.settings().get("reduced_motion", false))

static func bg() -> Color:
	return HC_BG if high_contrast() else BG

static func ink() -> Color:
	return HC_INK if high_contrast() else INK

static func accent() -> Color:
	return HC_ACCENT if high_contrast() else ACCENT

static func make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, BUTTON_H)  # large touch target
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", BODY_SIZE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = SURFACE
	for c in ["corner_radius_top_left", "corner_radius_top_right",
			"corner_radius_bottom_left", "corner_radius_bottom_right"]:
		sb.set(c, RADIUS)
	sb.content_margin_left = GAP_M
	sb.content_margin_right = GAP_M
	b.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = SURFACE.lightened(0.08)
	b.add_theme_stylebox_override("hover", hover)
	var pressed := sb.duplicate()
	pressed.bg_color = accent()
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_color_override("font_color", ink())
	return b

static func make_title(text: String, size: int = TITLE_SIZE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", ink())
	return l

static func make_body(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", BODY_SIZE)
	l.add_theme_color_override("font_color", MUTED)
	return l
