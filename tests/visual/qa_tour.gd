extends Node
## Graphical QA tour: boots the real Main scene (all autoloads), drives it with
## injected touch/mouse input, screenshots every screen, and audits layout.
##
## Needs a display (e.g. Xvfb + OpenGL 3 compatibility renderer):
##   TW_QA_OUT=/abs/out xvfb-run -a -s "-screen 0 1280x1800x24" \
##     godot --path . --display-driver x11 --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 720x1280 res://tests/visual/qa_tour.tscn
##
## Never touches a real player's save: it switches SaveManager to an isolated
## temporary file, verifies the real save path is byte-identical afterwards, and
## deletes its own file on exit. Exit code is 1 if any check FAILs.
##
## Thresholds (logical px at the 720-wide base; the narrowest common phone is
## 360 dp wide, i.e. 2 logical px per dp):
##   MIN_TOUCH 96 px  = 48 dp (Material) / > 44 pt (Apple HIG)
##   MIN_TEXT  28 px  = 14 sp (Material body-medium)

const QA_SAVE := "user://qa_tour_save.json"
const MIN_TOUCH := 96.0
const MIN_TEXT := 28

var _out_dir := ""
var _tag := ""
var _results: Array = []
var _main: Control
var _shot_index := 0
var _real_save_before := ""
var _touch_ok := true   # false => remaining taps fall back to mouse (recorded as FAIL)

func _ready() -> void:
	var win := DisplayServer.window_get_size()
	_tag = "%dx%d" % [win.x, win.y]
	var base := OS.get_environment("TW_QA_OUT")
	if base != "":
		_out_dir = base.path_join(_tag)
		DirAccess.make_dir_recursive_absolute(_out_dir)
	_real_save_before = _fingerprint(SaveManager.DEFAULT_SAVE_PATH)
	SaveManager.use_save_path(QA_SAVE, true)
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	await _tour()
	_finish()

# --- the tour ---------------------------------------------------------------
func _tour() -> void:
	await _settle()
	_check("viewport == window (input coords are identity)",
		Vector2i(get_viewport().get_visible_rect().size) == DisplayServer.window_get_size(),
		"vp=%s win=%s" % [get_viewport().get_visible_rect().size, DisplayServer.window_get_size()])

	# 1. Main menu
	await _capture("01_main_menu")
	_audit("main_menu")

	# Touch input must reach Buttons exactly as a phone delivers it.
	var levels_btn := _find_button(Localization.t("levels"))
	_check("menu: Levels button exists", levels_btn != null, "")
	if levels_btn == null:
		return
	var touched := [false]
	levels_btn.pressed.connect(func(): touched[0] = true)
	await _touch(levels_btn)
	await _settle()
	_check("touch: InputEventScreenTouch presses a Button", touched[0],
		"emulate_mouse_from_touch=%s" % Input.is_emulating_mouse_from_touch())
	if not touched[0]:
		_touch_ok = false
		await _click(levels_btn)   # fall back to mouse so the tour can continue
		await _settle()

	# 2. Level select (fresh save: only puzzle 1 unlocked)
	_check("levels: on level select", _screen_is("level_select"), _screen_name())
	await _capture("02_level_select_fresh")
	_audit("level_select_fresh")
	_check("levels: unsolved titles are not shown (no spoilers)",
		not _screen_has_text(Puzzles.get_def(1).title), "")

	var cell := _find_button("1")
	_check("levels: puzzle 1 cell exists", cell != null, "")
	if cell == null:
		return
	await _tap(cell)
	await _settle()

	# 3–7. Each puzzle: screenshot, audit, wrong attempt, hint for P02, solve.
	for id in range(1, Puzzles.count() + 1):
		var def := Puzzles.get_def(id)
		_check("P%02d: puzzle screen shown" % id, _screen_is("puzzle"), _screen_name())
		await _capture("%02d_puzzle_%02d" % [2 + id, id])
		_audit("puzzle_%02d" % id)
		_audit_puzzle(def)
		if id == 2:
			await _hint_walkthrough(def)
		if id == 1:
			await _pause_walkthrough()
		await _play_wrong(def)
		await _capture("%02d_puzzle_%02d_feedback" % [2 + id, id])
		if def.time_threshold > 0.0:
			await _wait_puzzle(def)
		else:
			await _solve(def)
		await _settle(0.9)
		_check("P%02d: completion screen shown" % id, _screen_is("puzzle_complete"), _screen_name())
		_check("P%02d: completion persisted" % id, SaveManager.is_completed(id), "")
		if id == 1:
			await _capture("08_puzzle_complete")
			_audit("puzzle_complete")
		if id < Puzzles.count():
			var nxt := _find_button(Localization.t("next"))
			_check("P%02d: Next button on completion" % id, nxt != null, "")
			if nxt == null:
				return
			await _tap(nxt)
			await _settle()

	# Replay a completed puzzle must not break progression.
	var unlocked_before := SaveManager.unlocked_max()
	var replay := _find_button(Localization.t("replay"))
	_check("complete: Replay button", replay != null, "")
	if replay != null:
		await _tap(replay)
		await _settle()
		await _solve(Puzzles.get_def(Puzzles.count()))
		await _settle(0.9)
		_check("replay: progression unchanged", SaveManager.unlocked_max() == unlocked_before,
			"%d -> %d" % [unlocked_before, SaveManager.unlocked_max()])

	var to_levels := _find_button(Localization.t("levels"))
	if to_levels != null:
		await _tap(to_levels)
		await _settle()
		await _capture("09_level_select_all_solved")
		_audit("level_select_all_solved")
		_check("levels: solved titles revealed", _screen_has_text(Puzzles.get_def(3).title), "")
		var back := _find_button(Localization.t("back"))
		if back != null:
			await _tap(back)
			await _settle()

	await _settings_walkthrough()

# --- puzzle helpers -----------------------------------------------------------
func _solution(def: PuzzleDefinition) -> Array:
	if "solution" in def and not def.get("solution").is_empty():
		return def.get("solution")
	for aid in def.actions.keys():
		if bool(def.actions[aid].get("solves", false)):
			return [aid]
	return []

func _button_for_action(def: PuzzleDefinition, action_id: String) -> Button:
	for it in def.interactables:
		if it.action == action_id:
			return _find_button(it.label, true)
	return null

func _audit_puzzle(def: PuzzleDefinition) -> void:
	var tag := "P%02d" % def.id
	for it in def.interactables:
		_check("%s: clue for '%s' visible on screen" % [tag, it.id], _screen_has_text(it.clue),
			"clue=\"%s\"" % it.clue)
		if it.is_interactive():
			var b := _find_button(it.label, true)
			_check("%s: '%s' rendered as an enabled button" % [tag, it.id],
				b != null and not b.disabled, "")
		else:
			var b2 := _find_button(it.label, true, true)
			_check("%s: display-only '%s' not rendered as a button" % [tag, it.id], b2 == null,
				"a disabled Button looks like a broken control")
	for aid in _solution(def):
		_check("%s: solution step '%s' has a visible control" % [tag, aid],
			_button_for_action(def, aid) != null, "")

func _play_wrong(def: PuzzleDefinition) -> void:
	var sol := _solution(def)
	for it in def.interactables:
		if it.is_interactive() and not sol.has(it.action):
			var b := _find_button(it.label, true)
			if b != null:
				await _tap(b)
				await _settle(0.2)
				_check("P%02d: wrong tap on '%s' does not complete" % [def.id, it.id],
					_screen_is("puzzle"), _screen_name())
				_check("P%02d: wrong tap gives visible feedback" % def.id,
					_screen_has_text(str(def.actions[it.action].get("feedback", "")).left(12)), "")
			return

func _solve(def: PuzzleDefinition) -> void:
	for aid in _solution(def):
		var b := _button_for_action(def, aid)
		if b == null:
			_check("P%02d: control for '%s'" % [def.id, aid], false, "missing")
			return
		await _tap(b)
		await _settle(0.15)

func _wait_puzzle(def: PuzzleDefinition) -> void:
	# Opening Pause must stop the clock: the puzzle may not finish behind it.
	await _settle(0.5)
	var pause := _find_button(_pause_label())
	if pause != null:
		await _tap(pause)
		await _settle(0.3)
		await _capture("05b_puzzle_03_paused")
		await _settle(def.time_threshold + 1.0)
		_check("WAIT: clock does not run while paused", _screen_is("puzzle"), _screen_name())
		var resume := _find_button(Localization.t("resume"))
		if resume != null:
			await _tap(resume)
	await _settle(def.time_threshold + 0.5)

func _pause_label() -> String:
	return Localization.t("pause") if _find_button(Localization.t("pause")) != null else Localization.t("menu")

func _pause_walkthrough() -> void:
	var pause := _find_button(_pause_label())
	_check("HUD: pause control exists", pause != null, "")
	if pause == null:
		return
	await _tap(pause)
	await _settle(0.3)
	_check("Pause overlay shown", ScreenManager.has_overlay(), "")
	await _capture("10_pause_overlay")
	_audit("pause_overlay")
	var resume := _find_button(Localization.t("resume"))
	if resume != null:
		await _tap(resume)
		await _settle(0.3)
	_check("Pause: Resume closes overlay", not ScreenManager.has_overlay(), "")

func _hint_walkthrough(def: PuzzleDefinition) -> void:
	var hint := _find_button(Localization.t("hint"))
	_check("HUD: hint control exists", hint != null, "")
	if hint == null:
		return
	await _tap(hint)
	await _settle(0.3)
	await _capture("11_hint_tier0")
	_audit("hint_tier0")
	var labels := []
	for tier in range(1, def.hints.size() + 1):
		var reveal := _overlay_primary_button()
		if reveal == null:
			break
		labels.append(reveal.text)
		await _tap(reveal)
		await _settle(0.2)
		_check("Hint tier %d text visible" % tier, _screen_has_text(str(def.hints[tier - 1]).left(20)), "")
		await _capture("11_hint_tier%d" % tier)
	_audit("hint_all_tiers")
	# The control that reveals the final tier is the one that must say "solution".
	var last_reveal: String = labels[labels.size() - 1] if not labels.is_empty() else ""
	_check("Hint: the button that reveals the solution is labelled as such",
		last_reveal == Localization.t("show_solution"), "labels=%s" % [labels])
	var back := _find_button(Localization.t("back"))
	if back != null:
		await _tap(back)
		await _settle(0.3)

func _overlay_primary_button() -> Button:
	for b in _buttons_in(_audit_root()):
		if b.text != Localization.t("back") and not b.disabled:
			return b
	return null

func _settings_walkthrough() -> void:
	var settings := _find_button(Localization.t("settings"))
	_check("menu: Settings button", settings != null, "")
	if settings == null:
		return
	await _tap(settings)
	await _settle()
	await _capture("12_settings")
	_audit("settings")
	var hc := _find_toggle(Localization.t("high_contrast"))
	_check("settings: high-contrast toggle", hc != null, "")
	if hc != null:
		await _tap(hc)
		await _settle()
		await _capture("12b_settings_high_contrast")
		var bg := _main.get_child(0) as ColorRect
		_check("high contrast: app background switches", bg != null and bg.color == Style.HC_BG,
			"bg=%s" % (bg.color if bg != null else Color()))
		hc = _find_toggle(Localization.t("high_contrast"))
		if hc != null:
			await _tap(hc)
			await _settle()
	var reset := _find_button(Localization.t("reset_progress"))
	_check("settings: Reset Progress button", reset != null, "")
	if reset == null:
		return
	await _tap(reset)
	await _settle(0.4)
	await _capture("13_reset_confirm")
	_audit("reset_confirm")
	var confirm := _find_button(Localization.t("confirm"))
	_check("reset: confirm control visible", confirm != null, "")
	if confirm != null:
		await _tap(confirm)
		await _settle()
		_check("reset: progress cleared", SaveManager.unlocked_max() == 1 and not SaveManager.is_completed(1), "")
		_check("reset: back on main menu", _screen_is("main_menu"), _screen_name())

# --- layout audit -------------------------------------------------------------
func _audit_root() -> Control:
	if ScreenManager.has_overlay():
		return ScreenManager._overlay
	return ScreenManager._current

func _audit(screen: String) -> void:
	var root := _audit_root()
	var vp := get_viewport().get_visible_rect().grow(1.0)
	var problems := {"touch": [], "offscreen": [], "overlap": [], "text_size": [],
		"overflow": [], "glyphs": []}
	var interactive: Array = []
	for node in _controls(root):
		var c: Control = node
		var r := c.get_global_rect()
		if c is BaseButton and not (c as BaseButton).disabled:
			interactive.append(c)
			if r.size.y < MIN_TOUCH or r.size.x < MIN_TOUCH:
				problems["touch"].append("%s %s" % [_desc(c), r.size])
			if not vp.encloses(r):
				problems["offscreen"].append(_desc(c))
		var text := _text_of(c)
		if text != "":
			var fs: int = c.get_theme_font_size("font_size")
			if fs < MIN_TEXT:
				problems["text_size"].append("%s fs=%d" % [_desc(c), fs])
			var font: Font = c.get_theme_font("font")
			var missing := ""
			for ch in text:
				if ch.strip_edges() != "" and not font.has_char(ch.unicode_at(0)):
					missing += ch
			if missing != "":
				problems["glyphs"].append("%s missing '%s'" % [_desc(c), missing])
			if not vp.encloses(r):
				problems["offscreen"].append(_desc(c))
			var min_w: float = c.get_combined_minimum_size().x
			if c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
				min_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if c is Button:
				var sb := (c as Button).get_theme_stylebox("normal")
				min_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
			if min_w > r.size.x + 1.0:
				problems["overflow"].append("%s needs %d > %d" % [_desc(c), min_w, r.size.x])
	for i in interactive.size():
		for j in range(i + 1, interactive.size()):
			var a: Rect2 = interactive[i].get_global_rect()
			var b: Rect2 = interactive[j].get_global_rect()
			if a.intersects(b) and a.intersection(b).get_area() > 1.0 \
					and not interactive[i].is_ancestor_of(interactive[j]) \
					and not interactive[j].is_ancestor_of(interactive[i]):
				problems["overlap"].append("%s x %s" % [_desc(interactive[i]), _desc(interactive[j])])
	_check("%s: touch targets >= %d px" % [screen, MIN_TOUCH], problems["touch"].is_empty(), str(problems["touch"]))
	_check("%s: nothing off-screen / clipped by viewport" % screen, problems["offscreen"].is_empty(), str(problems["offscreen"]))
	_check("%s: no overlapping controls" % screen, problems["overlap"].is_empty(), str(problems["overlap"]))
	_check("%s: text >= %d px" % [screen, MIN_TEXT], problems["text_size"].is_empty(), str(problems["text_size"]))
	_check("%s: no text overflow" % screen, problems["overflow"].is_empty(), str(problems["overflow"]))
	_check("%s: every glyph in the bundled font" % screen, problems["glyphs"].is_empty(), str(problems["glyphs"]))

func _controls(root: Node) -> Array:
	var out := []
	if root == null:
		return out
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.is_visible_in_tree() and c.get_global_rect().size.x > 0.0:
			out.append(c)
	return out

func _buttons_in(root: Node) -> Array:
	var out := []
	for c in _controls(root):
		if c is Button:
			out.append(c)
	return out

func _text_of(c: Control) -> String:
	if c is Label:
		return (c as Label).text
	if c is Button:
		return (c as Button).text
	return ""

func _desc(c: Control) -> String:
	var t := _text_of(c).replace("\n", " ")
	return "%s'%s'" % [c.get_class(), t.left(24)]

# --- finding things -----------------------------------------------------------
func _find_button(text: String, prefix := false, include_disabled := false) -> Button:
	for b in _buttons_in(_audit_root()):
		if b is CheckButton:
			continue
		if b.disabled and not include_disabled:
			continue
		var t: String = b.text.strip_edges()
		if t == text or (prefix and t.begins_with(text)):
			return b
	# Fallback: a Button whose label is a child Label (e.g. level cells).
	for b in _buttons_in(_audit_root()):
		if b.disabled and not include_disabled:
			continue
		for l in b.find_children("*", "Label", true, false):
			if (l as Label).text.strip_edges() == text:
				return b
	return null

func _find_toggle(text: String) -> BaseButton:
	for c in _controls(_audit_root()):
		if c is CheckButton:
			var cb := c as CheckButton
			if cb.text.begins_with(text):
				return cb
			var row := cb.get_parent()
			for l in row.find_children("*", "Label", true, false):
				if (l as Label).text.begins_with(text):
					return cb
	return null

func _screen_has_text(fragment: String) -> bool:
	if fragment.strip_edges() == "":
		return false
	for c in _controls(_audit_root()):
		if _text_of(c).find(fragment) != -1:
			return true
	return false

func _screen_name() -> String:
	var cur: Node = ScreenManager._current
	if cur == null or cur.get_script() == null:
		return "?"
	return cur.get_script().resource_path.get_file().get_basename()

func _screen_is(script_name: String) -> bool:
	return _screen_name() == script_name

# --- input --------------------------------------------------------------------
func _tap(c: Control) -> void:
	if _touch_ok:
		await _touch(c)
	else:
		await _click(c)

func _touch(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = p
	down.pressed = true
	Input.parse_input_event(down)
	await _frames(2)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = p
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)

func _click(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = p
		e.global_position = p
		e.pressed = pressed
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(e)
		await _frames(2)

# --- infrastructure -----------------------------------------------------------
func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _settle(seconds := 0.5) -> void:
	await get_tree().create_timer(seconds).timeout
	await _frames(2)

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	if _out_dir == "":
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png(_out_dir.path_join("%s.png" % name))
	_shot_index += 1

func _check(name: String, ok: bool, detail: String) -> void:
	_results.append({"check": name, "status": "PASS" if ok else "FAIL", "detail": detail})

func _fingerprint(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "<absent>"
	return FileAccess.get_md5(path)

func _finish() -> void:
	SaveManager.discard_save_file()
	_check("isolation: QA save removed", not FileAccess.file_exists(QA_SAVE), "")
	_check("isolation: real player save untouched",
		_fingerprint(SaveManager.DEFAULT_SAVE_PATH) == _real_save_before,
		"before=%s after=%s" % [_real_save_before, _fingerprint(SaveManager.DEFAULT_SAVE_PATH)])
	SaveManager.save_path = SaveManager.DEFAULT_SAVE_PATH
	var fails := 0
	var lines := PackedStringArray()
	for r in _results:
		if r["status"] == "FAIL":
			fails += 1
		lines.append("%s | %s | %s" % [r["status"], r["check"], r["detail"]])
	print("\n".join(lines))
	print("QA tour %s: %d checks, %d failures, %d screenshots" % [_tag, _results.size(), fails, _shot_index])
	if _out_dir != "":
		var f := FileAccess.open(_out_dir.path_join("results.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify({"resolution": _tag, "checks": _results,
				"failures": fails, "build": Versions.build_info()}, "\t"))
			f.close()
	get_tree().quit(1 if fails > 0 else 0)
