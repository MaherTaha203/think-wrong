extends Control
## Puzzle screen. Renders the current puzzle's interactables as large, visible,
## labelled controls with an always-visible caption (the fair clue), drives the
## generic PuzzleController, and hosts the Pause and Hint overlays.
##
## The controller owns completion; this screen only forwards taps and, for the
## timed puzzle, real frame time. The clock is frozen while an overlay is open,
## and a single frame never advances it by more than MAX_FRAME_DT (so returning
## from the background cannot skip the wait).

const MAX_FRAME_DT := 0.1
const FIELD_ITEM_W := 0.40       # interactable width as a fraction of the field

var _def: PuzzleDefinition
var _pc: PuzzleController
var _field: Control
var _feedback: Label
var _timer_value: Label          # big countdown number (timed puzzles only)
var _captions := {}              # interactable id -> caption Label
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
	root.add_theme_constant_override("separation", Style.GAP_M)
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
	for it in _def.interactables:
		_field.add_child(_make_interactable(it))

	_feedback = Style.make_body("")
	_feedback.custom_minimum_size = Vector2(0, 2 * Style.BODY_SIZE + Style.GAP_M)
	_feedback.add_theme_color_override("font_color", Style.ink())
	root.add_child(_feedback)

	_refresh()
	set_process(_def.time_threshold > 0.0)

func _hud() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Style.GAP_S)
	row.add_child(_chip(Localization.t("pause"), _open_pause))
	var title := Style.make_title("%s %d" % [Localization.t("level"), _def.id], Style.H2_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(title)
	row.add_child(_chip(Localization.t("hint"), _open_hint))
	row.add_child(_chip(Localization.t("restart"), _restart))
	return row

func _chip(text: String, action: Callable) -> Button:
	var b := Style.make_button(text)
	b.add_theme_font_size_override("font_size", Style.SMALL_SIZE)
	b.pressed.connect(func():
		if _finished:
			return
		AudioManager.play("nav")
		action.call())
	return b

## A control (or display panel) plus its caption, placed by normalized position.
func _make_interactable(it: Interactable) -> Control:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", Style.GAP_S / 2)
	holder.anchor_left = clampf(it.position.x - FIELD_ITEM_W / 2.0, 0.0, 1.0)
	holder.anchor_right = clampf(it.position.x + FIELD_ITEM_W / 2.0, 0.0, 1.0)
	holder.anchor_top = it.position.y
	holder.anchor_bottom = it.position.y
	var half_h := (Style.CONTROL_H + Style.SMALL_SIZE * 2 + Style.GAP_S) / 2
	holder.offset_top = -half_h
	holder.offset_bottom = half_h
	holder.grow_vertical = Control.GROW_DIRECTION_BOTH
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH   # a wide label grows from the centre

	if it.is_interactive():
		var b := _make_action_button(it)
		b.pressed.connect(func(): _on_interact(it))
		holder.add_child(b)
	else:
		# Display-only: a framed panel, deliberately not button-shaped.
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, Style.CONTROL_H)
		var panel_style := Style.flat(Color(0, 0, 0, 0), Style.muted(), 2)
		if _def.id == 3 and it.kind == "timer":
			# Make the countdown the visual anchor without implying a penalty.
			panel_style = Style.flat(Style.SURFACE_2, Style.accent(), 3)
		panel.add_theme_stylebox_override("panel", panel_style)
		var text := Style.make_title(it.label, Style.H2_SIZE if it.kind == "timer" else Style.BODY_SIZE)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(text)
		holder.add_child(panel)
		if it.kind == "timer":
			_timer_value = text

	var caption := Style.make_body(it.clue, Style.SMALL_SIZE)
	holder.add_child(caption)
	_captions[it.id] = caption
	return holder

func _on_interact(it: Interactable) -> void:
	if _finished:
		return
	var r := _pc.attempt(it.action)
	match r:
		PuzzleController.Result.OK_COMPLETED:
			pass  # _on_completed plays the success cue exactly once
		PuzzleController.Result.OK:
			AudioManager.play("tap"); Haptics.light()
		_:
			AudioManager.play("invalid"); Haptics.warning()
	_refresh()

func _process(delta: float) -> void:
	if _finished or _pc == null or ScreenManager.has_overlay():
		return
	_pc.advance_time(minf(delta, MAX_FRAME_DT))
	_refresh()

## Give each puzzle object a visual grammar that matches its semantic role.
## Puzzle 01 deliberately makes the door read as an object to operate, while the
## buzzer button reads as a tempting but secondary control. Both remain large and
## keyboard/touch accessible; the distinction is never colour-only.
func _make_action_button(it: Interactable) -> Button:
	var b := Style.make_button(it.label)
	b.custom_minimum_size = Vector2(0, Style.CONTROL_H)
	if it.kind == "door":
		var normal := Style.flat(Color(0, 0, 0, 0), Style.accent(), 3)
		var hover := normal.duplicate()
		hover.bg_color = Style.SURFACE if not Style.high_contrast() else Style.SURFACE_2
		var pressed := normal.duplicate()
		pressed.bg_color = Style.accent()
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", pressed)
		b.add_theme_stylebox_override("hover_pressed", pressed)
		b.add_theme_color_override("font_color", Style.ink())
		b.add_theme_color_override("font_hover_color", Style.ink())
		b.add_theme_color_override("font_pressed_color", Style.BG)
		b.add_theme_font_size_override("font_size", Style.H2_SIZE)
	elif _def.id == 3 and it.id == "hurry":
		# The oversized urgency cue is intentionally tempting, but remains a
		# secondary action rather than the visual owner of the scene.
		var normal := Style.flat(Style.SURFACE_2, Style.DANGER, 3)
		var hover := normal.duplicate()
		hover.bg_color = Style.SURFACE if not Style.high_contrast() else Style.SURFACE_2
		var pressed := normal.duplicate()
		pressed.bg_color = Style.DANGER
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", pressed)
		b.add_theme_stylebox_override("hover_pressed", pressed)
		b.add_theme_color_override("font_color", Style.ink())
		b.add_theme_color_override("font_hover_color", Style.ink())
		b.add_theme_color_override("font_pressed_color", Style.BG)
		b.add_theme_font_size_override("font_size", Style.H2_SIZE)
	elif it.kind == "key":
		# Anchored object: read as a fixed reference, not as the control to move.
		var normal := Style.flat(Color(0, 0, 0, 0), Style.muted(), 2)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", normal.duplicate())
		b.add_theme_stylebox_override("pressed", normal.duplicate())
		b.add_theme_color_override("font_color", Style.muted())
		b.add_theme_color_override("font_hover_color", Style.ink())
		b.add_theme_color_override("font_pressed_color", Style.ink())
		b.add_theme_font_size_override("font_size", Style.H2_SIZE)
	elif it.kind == "lock":
		# Movable object: stronger affordance so the rail-mounted lock reads as the
		# thing to move, without relying on colour alone.
		var normal := Style.flat(Style.SURFACE_2, Style.accent(), 3)
		var hover := normal.duplicate()
		hover.bg_color = Style.SURFACE if not Style.high_contrast() else Style.SURFACE_2
		var pressed := normal.duplicate()
		pressed.bg_color = Style.accent()
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", pressed)
		b.add_theme_stylebox_override("hover_pressed", pressed)
		b.add_theme_color_override("font_color", Style.ink())
		b.add_theme_color_override("font_hover_color", Style.ink())
		b.add_theme_color_override("font_pressed_color", Style.BG)
		b.add_theme_font_size_override("font_size", Style.H2_SIZE)
	elif it.kind == "box":
		# Puzzle 04: the box is the movable solution object. Give it the same
		# strong affordance grammar as the movable lock, while keeping the pinned
		# object visually quiet so the intended movement is readable at a glance.
		var normal := Style.flat(Style.SURFACE_2, Style.accent(), 3)
		var hover := normal.duplicate()
		hover.bg_color = Style.SURFACE if not Style.high_contrast() else Style.SURFACE_2
		var pressed := normal.duplicate()
		pressed.bg_color = Style.accent()
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", pressed)
		b.add_theme_stylebox_override("hover_pressed", pressed)
		b.add_theme_color_override("font_color", Style.ink())
		b.add_theme_color_override("font_hover_color", Style.ink())
		b.add_theme_color_override("font_pressed_color", Style.BG)
		b.add_theme_font_size_override("font_size", Style.H2_SIZE)
	elif it.kind == "object":
		# Anchored object: visually subordinate to the movable box without making
		# its fixed state depend on colour alone; the caption remains authoritative.
		var normal := Style.flat(Color(0, 0, 0, 0), Style.muted(), 2)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", normal.duplicate())
		b.add_theme_stylebox_override("pressed", normal.duplicate())
		b.add_theme_color_override("font_color", Style.muted())
		b.add_theme_color_override("font_hover_color", Style.ink())
		b.add_theme_color_override("font_pressed_color", Style.ink())
		b.add_theme_font_size_override("font_size", Style.H2_SIZE)
	return b

## Re-render everything that depends on puzzle state.
func _refresh() -> void:
	for it in _def.interactables:
		(_captions[it.id] as Label).text = it.caption(_pc.state.facts)
	if _timer_value != null:
		var remain: float = maxf(0.0, _def.time_threshold - _pc.state.elapsed)
		_timer_value.text = "%.1f" % remain

func _on_feedback(message: String, _kind: String) -> void:
	if _feedback != null:
		_feedback.text = message

func _on_completed() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	_refresh()
	AudioManager.play("success"); Haptics.success()
	GameState.complete_level(_def.id, _pc.hints_used())
	if Style.reduced_motion():
		_go_complete.call_deferred()
	else:
		# Bound to this node: if the player leaves first, the call never fires.
		get_tree().create_timer(0.5).timeout.connect(_go_complete)

func _go_complete() -> void:
	if is_inside_tree():
		ScreenManager.goto("complete")

# --- overlays -------------------------------------------------------------
func _open_pause() -> void:
	var made := Style.make_overlay(Localization.t("pause"))
	var col: VBoxContainer = made[1]
	col.add_child(_ov_btn(Localization.t("resume"), func(): ScreenManager.close_overlay()))
	col.add_child(_ov_btn(Localization.t("restart"), func():
		ScreenManager.close_overlay(); _restart()))
	col.add_child(_ov_btn(Localization.t("main_menu"), func():
		ScreenManager.goto("menu")))
	ScreenManager.show_overlay(made[0])

func _open_hint() -> void:
	var made := Style.make_overlay(Localization.t("hint"))
	var col: VBoxContainer = made[1]
	var body := Style.make_body("")
	body.add_theme_color_override("font_color", Style.ink())
	col.add_child(body)
	var reveal_btn := _ov_btn("", Callable())
	var refresh := func():
		var shown: Array = _pc.hints.revealed()
		if shown.is_empty():
			body.text = Localization.t("hint_intro")
		else:
			var lines := PackedStringArray()
			for i in shown.size():
				var is_solution: bool = i == _pc.hints.total() - 1
				var prefix: String = Localization.t("solution") + ": " if is_solution else "%d. " % (i + 1)
				lines.append(prefix + str(shown[i]))
			body.text = "\n\n".join(lines)
		var remaining: int = _pc.hints.total() - _pc.hints.tier
		if remaining <= 0:
			reveal_btn.text = Localization.t("no_more_hints")
		elif remaining == 1:
			reveal_btn.text = Localization.t("show_solution")
		elif shown.is_empty():
			reveal_btn.text = Localization.t("show_hint")
		else:
			reveal_btn.text = Localization.t("next_hint")
		reveal_btn.disabled = remaining <= 0
		if reveal_btn.disabled:
			reveal_btn.release_focus()   # a focus ring on a dead button reads as "selected"
	reveal_btn.pressed.connect(func():
		AudioManager.play("nav")
		_pc.reveal_hint()
		refresh.call())
	col.add_child(reveal_btn)
	col.add_child(_ov_btn(Localization.t("back"), func(): ScreenManager.close_overlay()))
	refresh.call()
	ScreenManager.show_overlay(made[0])

func _ov_btn(text: String, action: Callable) -> Button:
	var b := Style.make_button(text)
	if action.is_valid():
		b.pressed.connect(func():
			AudioManager.play("nav")
			action.call())
	return b

func _restart() -> void:
	if _finished:
		return
	_pc.reset()
	if _feedback != null:
		_feedback.text = ""
	_refresh()
	set_process(_def.time_threshold > 0.0)

func _error() -> void:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.GAP_M)
	c.add_child(col)
	col.add_child(Style.make_title(Localization.t("puzzle_unavailable"), Style.H2_SIZE))
	var back := Style.make_button(Localization.t("back"))
	back.pressed.connect(func(): ScreenManager.goto("levels"))
	col.add_child(back)
