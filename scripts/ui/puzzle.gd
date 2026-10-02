extends Control
## Puzzle screen. Renders the current puzzle's interactables as large, visible,
## labelled controls (no invisible hitboxes, no pixel hunting), drives the generic
## PuzzleController, and hosts Pause and Hint overlays. For the time-based puzzle
## it advances the controller's clock in _process and shows a countdown.

var _def: PuzzleDefinition
var _pc: PuzzleController
var _field: Control
var _feedback: Label
var _timer_label: Button    # the (disabled) timer display; only .text is updated
var _finished := false

func _ready() -> void:
	_def = Puzzles.get_def(GameState.current_level_id)
	if _def == null:
		_error()
		return
	_pc = PuzzleController.new(_def)
	_pc.completed.connect(_on_completed)
	_pc.feedback.connect(_on_feedback)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", Style.GAP_S)
	add_child(root)

	root.add_child(_hud())

	var objective := Style.make_body("%s: %s" % [Localization.t("objective"), _def.objective])
	objective.add_theme_color_override("font_color", Style.ink())
	root.add_child(objective)

	_field = Control.new()
	_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field.clip_contents = true
	root.add_child(_field)
	_build_interactables()

	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size = Vector2(0, 44)
	_feedback.add_theme_color_override("font_color", Style.MUTED)
	_feedback.add_theme_font_size_override("font_size", 20)
	root.add_child(_feedback)

	set_process(_def.time_threshold > 0.0)

func _hud() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Style.GAP_S)
	row.add_child(_chip(Localization.t("menu"), _open_pause))
	var title := Style.make_title("%s %d" % [Localization.t("level"), _def.id], Style.H2_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(_chip(Localization.t("hint"), _open_hint))
	row.add_child(_chip(Localization.t("restart"), _restart))
	return row

func _chip(text: String, action: Callable) -> Button:
	var b := Style.make_button(text)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(func():
		AudioManager.play("nav")
		action.call())
	return b

func _build_interactables() -> void:
	for it in _def.interactables:
		var node := _make_interactable(it)
		_field.add_child(node)

func _make_interactable(it: Interactable) -> Control:
	var holder := Control.new()
	# Position by normalized coordinates, responsive to the field size.
	holder.anchor_left = it.position.x
	holder.anchor_right = it.position.x
	holder.anchor_top = it.position.y
	holder.anchor_bottom = it.position.y
	holder.offset_left = -110
	holder.offset_right = 110
	holder.offset_top = -44
	holder.offset_bottom = 44

	if it.is_interactive():
		var b := Style.make_button(_interactable_label(it))
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.pressed.connect(func(): _on_interact(it))
		holder.add_child(b)
	else:
		var panel := Style.make_button(_interactable_label(it))
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.disabled = true
		holder.add_child(panel)
		if it.kind == "timer":
			_timer_label = panel

	return holder

func _interactable_label(it: Interactable) -> String:
	var affordance := ""
	if it.anchored:
		affordance = "  ⚓"       # anchor glyph = fixed (not colour-only)
	elif it.movable:
		affordance = "  ↔"       # arrows = movable
	return it.label + affordance

func _on_interact(it: Interactable) -> void:
	if _finished:
		return
	var r := _pc.attempt(it.action)
	match r:
		PuzzleController.Result.OK_COMPLETED:
			AudioManager.play("success"); Haptics.success()
		PuzzleController.Result.OK:
			AudioManager.play("tap"); Haptics.light()
		_:
			AudioManager.play("invalid"); Haptics.warning()

func _process(delta: float) -> void:
	if _finished or _pc == null:
		return
	_pc.advance_time(delta)
	if _timer_label != null:
		var remain: float = maxf(0.0, _def.time_threshold - _pc.state.elapsed)
		_timer_label.text = "%.1f" % remain
	if _pc.is_complete():
		_on_completed()

func _on_feedback(message: String, _kind: String) -> void:
	if _feedback != null:
		_feedback.text = message

func _on_completed() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	AudioManager.play("success"); Haptics.success()
	GameState.complete_level(_def.id, _pc.hints_used())
	var delay := 0.0 if Style.reduced_motion() else 0.5
	await get_tree().create_timer(delay).timeout
	ScreenManager.goto("complete")

# --- overlays -------------------------------------------------------------
func _open_pause() -> void:
	var made := _make_overlay()
	var ov: Control = made[0]
	var col: VBoxContainer = made[1]
	col.add_child(Style.make_title(Localization.t("pause"), Style.H2_SIZE))
	col.add_child(_ov_btn(Localization.t("resume"), func(): ScreenManager.close_overlay()))
	col.add_child(_ov_btn(Localization.t("restart"), func():
		ScreenManager.close_overlay(); _restart()))
	col.add_child(_ov_btn(Localization.t("menu"), func():
		ScreenManager.close_overlay(); ScreenManager.goto("menu")))
	ScreenManager.show_overlay(ov)

func _open_hint() -> void:
	var made := _make_overlay()
	var ov: Control = made[0]
	var col: VBoxContainer = made[1]
	col.add_child(Style.make_title(Localization.t("hint"), Style.H2_SIZE))
	var body := Style.make_body("")
	body.add_theme_color_override("font_color", Style.ink())
	col.add_child(body)
	var reveal_btn := _ov_btn(Localization.t("next_hint"), Callable())
	var refresh := func():
		var shown: Array = _pc.hints.revealed()
		if shown.is_empty():
			body.text = "Tap below for a nudge. Hints never solve it for you at first."
		else:
			var lines := PackedStringArray()
			for i in shown.size():
				var prefix := Localization.t("solution") + ": " if i == shown.size() - 1 and not _pc.hints.has_more() else "%d. " % (i + 1)
				lines.append(prefix + str(shown[i]))
			body.text = "\n\n".join(lines)
		reveal_btn.text = Localization.t("next_hint") if _pc.hints.has_more() else Localization.t("show_solution")
		reveal_btn.disabled = not _pc.hints.has_more()
	reveal_btn.pressed.connect(func():
		AudioManager.play("nav")
		_pc.reveal_hint()
		refresh.call())
	col.add_child(reveal_btn)
	col.add_child(_ov_btn(Localization.t("back"), func(): ScreenManager.close_overlay()))
	refresh.call()
	ScreenManager.show_overlay(ov)

## Returns [overlay_root, content_column].
func _make_overlay() -> Array:
	var ov := Control.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # block taps to the screen behind
	ov.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.GAP_S)
	col.custom_minimum_size = Vector2(340, 0)
	panel.add_child(col)
	return [ov, col]

func _ov_btn(text: String, action: Callable) -> Button:
	var b := Style.make_button(text)
	b.custom_minimum_size = Vector2(300, Style.BUTTON_H)
	if action.is_valid():
		b.pressed.connect(func():
			AudioManager.play("nav")
			action.call())
	return b

func _restart() -> void:
	_pc.reset()
	_finished = false
	if _feedback != null:
		_feedback.text = ""
	set_process(_def.time_threshold > 0.0)

func _error() -> void:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var col := VBoxContainer.new()
	c.add_child(col)
	col.add_child(Style.make_title("Puzzle unavailable", Style.H2_SIZE))
	var back := Style.make_button(Localization.t("back"))
	back.pressed.connect(func(): ScreenManager.goto("levels"))
	col.add_child(back)
