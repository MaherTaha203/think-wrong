extends RefCounted
class_name Style
## Central design tokens and widget factories for one calm, premium, dark-first
## visual identity. State is never conveyed by colour alone (text/captions carry
## it), a high-contrast variant and a reduced-motion flag support accessibility.
##
## Pure: Style never reads persistence. The composition root (main.gd) pushes the
## player's settings in via apply_settings(), so Style is usable in headless tests.
##
## Sizes are logical px at the 720-wide base. The narrowest common phone is
## 360 dp wide => 2 logical px per dp, so MIN_TOUCH 96 = 48 dp (Material; above
## Apple's 44 pt) and SMALL_SIZE 28 = 14 sp. tests/visual/qa_tour enforces both.

# palette (standard) — WCAG ratios are asserted in tests/gdscript/run_tests.gd
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
const MIN_TOUCH := 96
const BUTTON_H := MIN_TOUCH
const CONTROL_H := 112          # puzzle interactables: larger than the minimum
const TITLE_SIZE := 64
const H2_SIZE := 40
const BODY_SIZE := 32
const SMALL_SIZE := 28
const OVERLAY_W := 520

# animation timings (seconds)
const T_FAST := 0.12
const T_MED := 0.22

static var _high_contrast := false
static var _reduced_motion := false

## Called by the composition root whenever settings load or change.
static func apply_settings(settings: Dictionary) -> void:
	_high_contrast = bool(settings.get("high_contrast", false))
	_reduced_motion = bool(settings.get("reduced_motion", false))

static func high_contrast() -> bool:
	return _high_contrast

static func reduced_motion() -> bool:
	return _reduced_motion

static func bg() -> Color:
	return HC_BG if _high_contrast else BG

static func ink() -> Color:
	return HC_INK if _high_contrast else INK

static func accent() -> Color:
	return HC_ACCENT if _high_contrast else ACCENT

static func muted() -> Color:
	return HC_INK if _high_contrast else MUTED

## WCAG 2.x contrast ratio between two colours (1..21).
static func contrast_ratio(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

static func _luminance(c: Color) -> float:
	var ch := [c.r, c.g, c.b]
	for i in 3:
		ch[i] = ch[i] / 12.92 if ch[i] <= 0.03928 else pow((ch[i] + 0.055) / 1.055, 2.4)
	return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2]

## Convert the OS safe area (physical px) into logical margins for a
## canvas_items-stretched viewport, never smaller than min_gap.
static func safe_margins(safe: Rect2i, win: Vector2i, vp: Vector2, min_gap: int) -> Dictionary:
	var k := vp.x / float(maxi(1, win.x))
	return {
		"left": maxi(min_gap, roundi(safe.position.x * k)),
		"top": maxi(min_gap, roundi(safe.position.y * k)),
		"right": maxi(min_gap, roundi((win.x - safe.end.x) * k)),
		"bottom": maxi(min_gap, roundi((win.y - safe.end.y) * k)),
	}

static func flat(color: Color, border := Color(0, 0, 0, 0), border_w := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(RADIUS)
	sb.content_margin_left = GAP_M
	sb.content_margin_right = GAP_M
	sb.content_margin_top = GAP_S
	sb.content_margin_bottom = GAP_S
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	return sb

static func make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(MIN_TOUCH, BUTTON_H)  # large touch target
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", BODY_SIZE)
	var normal := flat(SURFACE_2 if _high_contrast else SURFACE, ink() if _high_contrast else Color(0, 0, 0, 0), 2 if _high_contrast else 0)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	b.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = accent()
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	var focus := flat(Color(0, 0, 0, 0), accent(), 3)
	b.add_theme_stylebox_override("focus", focus)
	var disabled := normal.duplicate()
	disabled.bg_color = SURFACE.darkened(0.35)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", ink())
	b.add_theme_color_override("font_hover_color", ink())
	b.add_theme_color_override("font_focus_color", ink())
	b.add_theme_color_override("font_pressed_color", BG)        # 9.2:1 on ACCENT
	b.add_theme_color_override("font_hover_pressed_color", BG)
	b.add_theme_color_override("font_disabled_color", muted())
	return b

static func make_title(text: String, size: int = TITLE_SIZE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", ink())
	return l

static func make_body(text: String, size: int = BODY_SIZE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", muted())
	return l

## A modal overlay: dimmed backdrop that swallows taps + a centred panel.
## Returns [overlay_root, content_column].
static func make_overlay(title: String) -> Array:
	var ov := Control.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # block taps to the screen behind
	ov.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(center)
	var panel := PanelContainer.new()
	var sb := flat(SURFACE_2, ink() if _high_contrast else Color(0, 0, 0, 0), 2 if _high_contrast else 0)
	sb.set_content_margin_all(GAP_L)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", GAP_M)
	col.custom_minimum_size = Vector2(OVERLAY_W, 0)
	panel.add_child(col)
	col.add_child(make_title(title, H2_SIZE))
	return [ov, col]
