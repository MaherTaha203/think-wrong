extends Control
## Level Select: a grid of the prototype puzzles with locked / completed state
## shown by glyph + label (never colour alone). Locked puzzles are non-interactive.

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", Style.GAP_M)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", Style.GAP_S)
	var back := Style.make_button(Localization.t("back"))
	back.custom_minimum_size = Vector2(120, Style.BUTTON_H)
	back.pressed.connect(func():
		AudioManager.play("nav")
		ScreenManager.goto("menu"))
	header.add_child(back)
	var title := Style.make_title(Localization.t("levels"), Style.H2_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var spacer := Control.new(); spacer.custom_minimum_size = Vector2(120, 0)
	header.add_child(spacer)
	root.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", Style.GAP_S)
	grid.add_theme_constant_override("v_separation", Style.GAP_S)
	root.add_child(grid)

	for def in Puzzles.all():
		grid.add_child(_cell(def))

func _cell(def: PuzzleDefinition) -> Control:
	var unlocked := SaveManager.is_unlocked(def.id)
	var done := SaveManager.is_completed(def.id)
	var cell := Button.new()
	cell.custom_minimum_size = Vector2(0, 110)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.disabled = not unlocked
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.SURFACE if unlocked else Style.SURFACE.darkened(0.4)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		sb.set(c, Style.RADIUS)
	cell.add_theme_stylebox_override("normal", sb)
	cell.add_theme_stylebox_override("disabled", sb)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(vb)

	var num := Label.new()
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", Style.H2_SIZE)
	num.add_theme_color_override("font_color", Style.ink() if unlocked else Style.MUTED)
	num.text = str(def.id) if unlocked else "✖"
	vb.add_child(num)

	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 18)
	if not unlocked:
		status.text = Localization.t("locked")
		status.add_theme_color_override("font_color", Style.MUTED)
	elif done:
		status.text = "✓ " + def.title
		status.add_theme_color_override("font_color", Style.SUCCESS)
	else:
		status.text = def.title
		status.add_theme_color_override("font_color", Style.MUTED)
	vb.add_child(status)

	if unlocked:
		cell.pressed.connect(func():
			AudioManager.play("nav")
			GameState.select_level(def.id)
			ScreenManager.goto("puzzle"))
	return cell
