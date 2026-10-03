extends Control
## Settings: Sound, Haptics, Reduced Motion, High Contrast + Reset Progress
## (with an in-game confirmation overlay). All persist immediately. Each toggle
## is a full-width row, so the whole row is the touch target.

const TOGGLES := ["sound", "haptics", "reduced_motion", "high_contrast"]

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", Style.GAP_M)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", Style.GAP_S)
	var back := Style.make_button(Localization.t("back"))
	back.custom_minimum_size = Vector2(140, Style.BUTTON_H)
	back.pressed.connect(func():
		AudioManager.play("nav")
		ScreenManager.goto("menu"))
	header.add_child(back)
	var title := Style.make_title(Localization.t("settings"), Style.H2_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(140, 0)
	header.add_child(spacer)
	root.add_child(header)

	for key in TOGGLES:
		root.add_child(_toggle(key))

	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(gap)

	var reset := Style.make_button(Localization.t("reset_progress"))
	reset.add_theme_color_override("font_color", Style.DANGER)
	reset.pressed.connect(_confirm_reset)
	root.add_child(reset)

func _toggle(key: String) -> Control:
	var check := CheckButton.new()
	check.custom_minimum_size = Vector2(0, Style.BUTTON_H)
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check.add_theme_font_size_override("font_size", Style.BODY_SIZE)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		check.add_theme_color_override(c, Style.ink())
	var sb := Style.flat(Style.SURFACE)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		check.add_theme_stylebox_override(state, sb)
	check.add_theme_stylebox_override("focus", Style.flat(Color(0, 0, 0, 0), Style.accent(), 3))
	check.button_pressed = bool(SaveManager.settings().get(key, false))
	# State in words, not only the switch graphic.
	var label_for := func(on: bool) -> String:
		return "%s: %s" % [Localization.t(key), Localization.t("on" if on else "off")]
	check.text = label_for.call(check.button_pressed)
	check.toggled.connect(func(pressed: bool):
		AudioManager.play("nav")
		check.text = label_for.call(pressed)
		SaveManager.set_setting(key, pressed)
		if key == "high_contrast":
			ScreenManager.goto("settings"))   # rebuild with the new palette
	return check

func _confirm_reset() -> void:
	AudioManager.play("nav")
	var made := Style.make_overlay(Localization.t("reset_progress"))
	var col: VBoxContainer = made[1]
	var body := Style.make_body(Localization.t("reset_confirm"))
	body.add_theme_color_override("font_color", Style.ink())
	col.add_child(body)
	var cancel := Style.make_button(Localization.t("cancel"))
	cancel.pressed.connect(func():
		AudioManager.play("nav")
		ScreenManager.close_overlay())
	col.add_child(cancel)
	var confirm := Style.make_button(Localization.t("confirm"))
	confirm.add_theme_color_override("font_color", Style.DANGER)
	confirm.pressed.connect(func():
		AudioManager.play("nav")
		SaveManager.reset_progress()
		ScreenManager.goto("menu"))
	col.add_child(confirm)
	ScreenManager.show_overlay(made[0])
