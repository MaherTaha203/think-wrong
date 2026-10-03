extends Control
## Level Select: a grid of the prototype puzzles. State is shown in words
## (Locked / Not solved / Solved), never by colour or symbol alone. A puzzle's
## title is revealed only once it is solved, because titles such as "WAIT" give
## the answer away. Locked puzzles are non-interactive.

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
	var title := Style.make_title(Localization.t("levels"), Style.H2_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(140, 0)
	header.add_child(spacer)
	root.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", Style.GAP_S)
	grid.add_theme_constant_override("v_separation", Style.GAP_S)
	root.add_child(grid)

	for def in Puzzles.all():
		grid.add_child(_cell(def))

func _cell(def: PuzzleDefinition) -> Control:
	var unlocked := SaveManager.is_unlocked(def.id)
	var done := SaveManager.is_completed(def.id)
	var cell := Button.new()
	cell.custom_minimum_size = Vector2(0, 168)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.disabled = not unlocked
	var sb := Style.flat(Style.SURFACE if unlocked else Style.SURFACE.darkened(0.4),
		Style.ink() if Style.high_contrast() and unlocked else Color(0, 0, 0, 0), 2 if Style.high_contrast() else 0)
	for state in ["normal", "disabled", "hover", "focus"]:
		cell.add_theme_stylebox_override(state, sb)
	var pressed := sb.duplicate()
	pressed.bg_color = Style.SURFACE_2
	cell.add_theme_stylebox_override("pressed", pressed)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(vb)

	var num := Style.make_title(str(def.id), Style.H2_SIZE)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		num.add_theme_color_override("font_color", Style.muted())
	vb.add_child(num)

	var status_key := "solved" if done else ("not_solved" if unlocked else "locked")
	var status := Style.make_body(Localization.t(status_key), Style.SMALL_SIZE)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if done:
		status.add_theme_color_override("font_color", Style.SUCCESS)
	vb.add_child(status)

	if done:
		var name_label := Style.make_body(def.title, Style.SMALL_SIZE)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.add_theme_color_override("font_color", Style.ink())
		vb.add_child(name_label)

	if unlocked:
		cell.pressed.connect(func():
			AudioManager.play("nav")
			GameState.select_level(def.id)
			ScreenManager.goto("puzzle"))
	return cell
