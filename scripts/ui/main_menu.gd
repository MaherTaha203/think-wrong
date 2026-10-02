extends Control
## Main Menu: title, tagline, Continue (when progress exists), Play, Levels, Settings.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.GAP_M)
	col.custom_minimum_size = Vector2(360, 0)
	center.add_child(col)

	col.add_child(Style.make_title(Localization.t("app_title")))
	col.add_child(Style.make_body(Localization.t("tagline")))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, Style.GAP_L)
	col.add_child(spacer)

	var has_progress := SaveManager.unlocked_max() > 1
	if has_progress:
		col.add_child(_btn(Localization.t("continue"), func():
			GameState.select_level(SaveManager.unlocked_max())
			ScreenManager.goto("puzzle")))

	col.add_child(_btn(Localization.t("play"), func():
		GameState.select_level(1 if not has_progress else SaveManager.unlocked_max())
		ScreenManager.goto("puzzle")))
	col.add_child(_btn(Localization.t("levels"), func(): ScreenManager.goto("levels")))
	col.add_child(_btn(Localization.t("settings"), func(): ScreenManager.goto("settings")))

func _btn(text: String, action: Callable) -> Button:
	var b := Style.make_button(text)
	b.pressed.connect(func():
		AudioManager.play("nav")
		action.call())
	return b
