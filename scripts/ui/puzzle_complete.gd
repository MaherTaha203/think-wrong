extends Control
## Puzzle Complete: the "aha" beat (the puzzle's title is revealed here), then
## Next / Replay / Levels.

func _ready() -> void:
	var result := GameState.last_result
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.GAP_M)
	col.custom_minimum_size = Vector2(440, 0)
	center.add_child(col)

	col.add_child(Style.make_title(Localization.t("solved_title")))
	var def := Puzzles.get_def(int(result.get("level_id", GameState.current_level_id)))
	if def != null:
		var name_label := Style.make_title(def.title, Style.H2_SIZE)
		name_label.add_theme_color_override("font_color", Style.accent())
		col.add_child(name_label)
	col.add_child(Style.make_body(Localization.t("aha")))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, Style.GAP_M)
	col.add_child(spacer)

	if bool(result.get("has_next", false)):
		col.add_child(_btn(Localization.t("next"), func():
			GameState.select_level(GameState.next_level_id())
			ScreenManager.goto("puzzle")))
	col.add_child(_btn(Localization.t("replay"), func():
		ScreenManager.goto("puzzle")))
	col.add_child(_btn(Localization.t("levels"), func():
		ScreenManager.goto("levels")))

func _btn(text: String, action: Callable) -> Button:
	var b := Style.make_button(text)
	b.pressed.connect(func():
		AudioManager.play("nav")
		action.call())
	return b
