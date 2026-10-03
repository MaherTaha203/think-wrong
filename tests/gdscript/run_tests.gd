extends SceneTree
## Headless deterministic tests for THINK WRONG (no UI, no autoloads, no real
## time, no files). Covers the framework, all five puzzles, completion integrity
## (exhaustive action sequences), interaction bindings, determinism, the WAIT
## puzzle via an injected clock, the save model, string/glyph hygiene and data
## isolation.
##
## Every suite builds its own objects, so suites are order-independent; prove it:
##   godot --headless --path . --script tests/gdscript/run_tests.gd
##   godot --headless --path . --script tests/gdscript/run_tests.gd -- --order=reverse
##   godot --headless --path . --script tests/gdscript/run_tests.gd -- --order=shuffle:1234

var _checks := 0
var _failures := 0

func _init() -> void:
	var suites: Array[Callable] = [
		_test_framework, _test_each_puzzle, _test_wait_clock, _test_save,
		_test_determinism, _test_completion_integrity, _test_interaction_binding,
		_test_completion_once, _test_wait_edges, _test_objective_honesty,
		_test_save_extended, _test_data_isolation, _test_text_hygiene,
		_test_safe_area_math,
	]
	var order := "forward"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--order="):
			order = arg.trim_prefix("--order=")
	if order == "reverse":
		suites.reverse()
	elif order.begins_with("shuffle:"):
		var rng := RandomNumberGenerator.new()
		rng.seed = int(order.trim_prefix("shuffle:"))
		for i in range(suites.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := suites[i]
			suites[i] = suites[j]
			suites[j] = tmp
	for suite in suites:
		suite.call()
	print("THINK WRONG tests (order=%s): %d checks, %d failures" % [order, _checks, _failures])
	quit(1 if _failures > 0 else 0)

func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		print("FAIL: " + msg)
		push_error("FAIL: " + msg)

## The intended solution as an ordered list of action ids (empty for WAIT).
func _solution(def: PuzzleDefinition) -> Array:
	if "solution" in def:
		return def.get("solution")
	for aid in def.actions.keys():
		if bool(def.actions[aid].get("solves", false)):
			return [aid]
	return []

## Apply the intended solution (advancing the injected clock for timed puzzles).
func _play_solution(pc: PuzzleController) -> int:
	var last := PuzzleController.Result.NO_PROGRESS
	for aid in _solution(pc.definition):
		last = pc.attempt(aid)
	if pc.definition.time_threshold > 0.0:
		pc.advance_time(pc.definition.time_threshold)
	return last

## A bound action that is not part of the intended solution (a decoy).
func _wrong_action(def: PuzzleDefinition) -> String:
	var sol := _solution(def)
	for aid in def.actions.keys():
		if not sol.has(aid):
			return aid
	return ""

func _is_subsequence(needle: Array, hay: Array) -> bool:
	var i := 0
	for x in hay:
		if i < needle.size() and x == needle[i]:
			i += 1
	return i == needle.size()

# --------------------------------------------------------------------------
func _test_framework() -> void:
	var def := Puzzles.get_def(1)
	var pc := PuzzleController.new(def)
	_check(pc.wrong_attempts == 0, "fw: fresh wrong_attempts 0")
	_check(not pc.is_complete(), "fw: not complete at start")
	_check(pc.state.facts.size() == def.initial_facts.size(), "fw: initial state")

	# invalid interaction (unknown action)
	var r := pc.attempt("no_such_action")
	_check(r == PuzzleController.Result.INVALID, "fw: unknown action INVALID")
	_check(pc.wrong_attempts == 1, "fw: invalid increments wrong_attempts")
	_check(not pc.is_complete(), "fw: still not complete after invalid")

	# state mutation + completion
	_check(_play_solution(pc) == PuzzleController.Result.OK_COMPLETED, "fw: solve completes")
	_check(pc.is_complete(), "fw: is_complete true after solve")

	# reset
	pc.reset()
	_check(not pc.is_complete(), "fw: reset clears completion")
	_check(pc.wrong_attempts == 0, "fw: reset clears wrong_attempts")
	_check(pc.hints.used_count() == 0, "fw: reset clears hint tier")

	# hints progression
	_check(pc.hints.total() == 3, "fw: three hint tiers")
	_check(pc.reveal_hint() != "", "fw: hint 1 revealed")
	_check(pc.reveal_hint() != "", "fw: hint 2 revealed")
	_check(pc.reveal_hint() != "", "fw: hint 3 (solution) revealed")
	_check(not pc.hints.has_more(), "fw: no more hints after solution")
	_check(pc.reveal_hint() == "", "fw: revealing past end is empty")

	# progression (pure save model)
	var save := SaveModel.default_save(1)
	_check(SaveModel.is_unlocked(save, 1) and not SaveModel.is_unlocked(save, 2), "fw: only level 1 unlocked initially")
	save = SaveModel.record_completion(save, 1, 0, Puzzles.count())
	_check(SaveModel.is_unlocked(save, 2), "fw: completing 1 unlocks 2")

func _test_each_puzzle() -> void:
	for def in Puzzles.all():
		var tag := "P%02d(%s)" % [def.id, def.key]
		# 7. clue/interaction availability + 3 non-empty hints
		_check(def.hints.size() == 3, tag + ": 3 hints")
		var all_hints_nonempty := true
		for h in def.hints:
			if str(h).strip_edges() == "":
				all_hints_nonempty = false
		_check(all_hints_nonempty, tag + ": hints non-empty")
		_check(def.interactables.size() >= 2, tag + ": >=2 interactables")
		var clued := true
		for it in def.interactables:
			if str(it.clue).strip_edges() == "":
				clued = false
		_check(clued, tag + ": every interactable has a fair clue")

		var pc := PuzzleController.new(def)
		# 1. initial state
		_check(not pc.is_complete(), tag + ": not complete initially")

		# 3. incorrect action (skip for pure-time puzzles that have a wrong action anyway)
		var wrong := _wrong_action(def)
		if wrong != "":
			var rw := pc.attempt(wrong)
			_check(rw == PuzzleController.Result.NO_PROGRESS or rw == PuzzleController.Result.INVALID, tag + ": wrong action no progress")
			_check(not pc.is_complete(), tag + ": wrong action does not complete")
			_check(pc.wrong_attempts >= 1, tag + ": wrong action counted")

		# 2. valid solution
		if def.time_threshold > 0.0:
			pc.advance_time(def.time_threshold + 0.01)
			_check(pc.is_complete(), tag + ": completes after waiting")
		else:
			_check(not _solution(def).is_empty(), tag + ": has a solution")
			_check(_play_solution(pc) == PuzzleController.Result.OK_COMPLETED, tag + ": solution completes")
		# 6. completion flag
		_check(pc.is_complete(), tag + ": is_complete after solution")

		# 4. reset
		pc.reset()
		_check(not pc.is_complete(), tag + ": reset clears completion")
		_check(pc.wrong_attempts == 0, tag + ": reset clears attempts")

		# 5. replay
		_play_solution(pc)
		_check(pc.is_complete(), tag + ": replay completes")

func _test_wait_clock() -> void:
	var def := Puzzles.get_def(3)
	var pc := PuzzleController.new(def)
	# before threshold
	pc.advance_time(def.time_threshold - 0.1)
	_check(not pc.is_complete(), "WAIT: not complete before threshold")
	# tapping the decoy must not complete early and must not block completion
	var r := pc.attempt("tap_hurry")
	_check(r == PuzzleController.Result.NO_PROGRESS, "WAIT: hurry is a no-progress decoy")
	_check(not pc.is_complete(), "WAIT: hurry does not complete early")
	# cross the threshold
	pc.advance_time(0.2)
	_check(pc.is_complete(), "WAIT: completes at/after threshold")
	# reset zeroes the clock
	pc.reset()
	_check(pc.state.elapsed == 0.0 and not pc.is_complete(), "WAIT: reset zeroes clock")
	# replay
	pc.advance_time(def.time_threshold + 0.01)
	_check(pc.is_complete(), "WAIT: replay completes")

func _test_save() -> void:
	# first launch / missing
	var o := SaveModel.load_from_string("", 1)
	_check(not o["recovered"] and int(o["save"]["progress"]["unlocked_max"]) == 1, "save: first launch defaults")
	_check(SaveModel.validate(o["save"], 1), "save: default is valid")

	# valid roundtrip + completed unlocks next
	var s := SaveModel.default_save(1)
	s = SaveModel.record_completion(s, 1, 2, Puzzles.count())
	var text := JSON.stringify(s)
	var o2 := SaveModel.load_from_string(text, 1)
	_check(not o2["recovered"], "save: valid roundtrip not recovered")
	_check(int(o2["save"]["progress"]["unlocked_max"]) == 2, "save: completion persisted (unlock 2)")
	_check(SaveModel.is_completed(o2["save"], 1), "save: level 1 marked completed")

	# corrupted JSON
	var o3 := SaveModel.load_from_string("{not valid json", 1)
	_check(o3["recovered"] and SaveModel.validate(o3["save"], 1), "save: corrupt recovers to valid default")

	# unknown future version
	var fut := JSON.stringify({"save_data_version": 99, "progress": {"unlocked_max": 5, "levels": {}}, "settings": {}})
	var o4 := SaveModel.load_from_string(fut, 1)
	_check(o4["recovered"] and int(o4["save"]["progress"]["unlocked_max"]) == 1, "save: future version recovers safely")

	# reset progress
	var reset := SaveModel.default_save(1)
	_check(int(reset["progress"]["unlocked_max"]) == 1 and reset["progress"]["levels"].is_empty(), "save: reset clears progress")

	# salvage: valid progress, broken settings
	var broken := JSON.stringify({
		"save_data_version": 1,
		"progress": {"unlocked_max": 3, "levels": {"2": {"completed": true, "hints_used": 1}}},
		"settings": {"sound": "yes"}})  # invalid type
	var o5 := SaveModel.load_from_string(broken, 1)
	_check(o5["recovered"], "save: broken settings triggers salvage")
	_check(SaveModel.is_completed(o5["save"], 2), "save: salvage keeps valid completed level")
	_check(int(o5["save"]["progress"]["unlocked_max"]) >= 3, "save: salvage preserves unlocked_max")
	_check(SaveModel.validate(o5["save"], 1), "save: salvaged result is valid")

# --------------------------------------------------------------------------
# Audit suites (Phase 1 final verification)
# --------------------------------------------------------------------------

## Same input sequence => identical results, feedback, facts and clock.
func _test_determinism() -> void:
	for def in Puzzles.all():
		var runs := []
		for _i in 2:
			var pc := PuzzleController.new(Puzzles.get_def(def.id))
			var log := []
			pc.feedback.connect(func(m, k): log.append([m, k]))
			var seq: Array = def.action_ids() + ["no_such_action"] + _solution(def)
			for aid in seq:
				log.append(pc.attempt(aid))
				pc.advance_time(0.75)
			runs.append([log, pc.state.snapshot(), pc.is_complete(), pc.wrong_attempts])
		_check(str(runs[0]) == str(runs[1]), "P%02d: identical input => identical outcome" % def.id)

## Exhaustive: every action sequence up to length 4 (incl. an unknown action).
## Without time, a puzzle completes iff the sequence contains the intended
## solution in order; a timed puzzle never completes from actions alone and
## always completes once the threshold has elapsed. No side paths.
func _test_completion_integrity() -> void:
	for def in Puzzles.all():
		var alphabet: Array = def.action_ids() + ["no_such_action"]
		var sol := _solution(def)
		var seqs := [[]]
		var frontier := [[]]
		for _depth in 4:
			var nxt := []
			for prefix in frontier:
				for a in alphabet:
					nxt.append(prefix + [a])
			seqs.append_array(nxt)
			frontier = nxt
		var bad := []
		for seq in seqs:
			var pc := PuzzleController.new(def)
			for a in seq:
				pc.attempt(a)
			var expected := false if def.time_threshold > 0.0 else _is_subsequence(sol, seq)
			if pc.is_complete() != expected:
				bad.append(seq)
			if def.time_threshold > 0.0:
				pc.advance_time(def.time_threshold)
				if not pc.is_complete():
					bad.append(["(time)"] + seq)
		_check(bad.is_empty(), "P%02d: no completion side paths across %d sequences %s" % [def.id, seqs.size(), str(bad.slice(0, 3))])

## Every action is reachable from exactly one visible, labelled, clued control;
## every control's action exists; ids are unique.
func _test_interaction_binding() -> void:
	for def in Puzzles.all():
		var tag := "P%02d" % def.id
		var ids := {}
		var bound := {}
		for it in def.interactables:
			_check(not ids.has(it.id), "%s: unique interactable id '%s'" % [tag, it.id])
			ids[it.id] = true
			_check(it.label.strip_edges() != "", "%s: '%s' has a label" % [tag, it.id])
			_check(it.position.x >= 0.15 and it.position.x <= 0.85 and it.position.y >= 0.1 and it.position.y <= 0.9,
				"%s: '%s' placed well inside the field" % [tag, it.id])
			if it.is_interactive():
				_check(def.actions.has(it.action), "%s: '%s' action '%s' exists" % [tag, it.id, it.action])
				bound[it.action] = int(bound.get(it.action, 0)) + 1
		for aid in def.action_ids():
			_check(int(bound.get(aid, 0)) == 1, "%s: action '%s' bound to exactly one control" % [tag, aid])
		for aid in _solution(def):
			_check(bound.has(aid), "%s: solution step '%s' is a visible control" % [tag, aid])

## completed fires exactly once per attempt-run (actions and time alike), and
## nothing after completion changes the outcome.
func _test_completion_once() -> void:
	for def in Puzzles.all():
		var pc := PuzzleController.new(def)
		var fired := [0]
		pc.completed.connect(func(): fired[0] += 1)
		_play_solution(pc)
		_play_solution(pc)
		pc.advance_time(10.0)
		for aid in def.action_ids():
			pc.attempt(aid)
		_check(fired[0] == 1, "P%02d: completed emitted exactly once (got %d)" % [def.id, fired[0]])
		_check(pc.is_complete(), "P%02d: stays complete after extra input" % def.id)
		pc.reset()
		_play_solution(pc)
		_check(fired[0] == 2, "P%02d: replay after reset emits completed again" % def.id)

## WAIT edge cases on the injected clock.
func _test_wait_edges() -> void:
	var def := Puzzles.get_def(3)
	var t := def.time_threshold
	var pc := PuzzleController.new(def)
	_check(pc.state.elapsed == 0.0 and not pc.is_complete(), "WAIT: t=0 not complete")
	pc.advance_time(t - 0.001)
	_check(not pc.is_complete(), "WAIT: just before threshold not complete")
	pc.reset()
	pc.advance_time(t)
	_check(pc.is_complete(), "WAIT: exactly at threshold completes")
	pc.reset()
	pc.advance_time(t + 5.0)
	_check(pc.is_complete(), "WAIT: well after threshold completes")
	pc.reset()
	pc.advance_time(-100.0)
	_check(pc.state.elapsed == 0.0, "WAIT: negative dt ignored")
	pc.advance_time(NAN)
	pc.advance_time(INF)
	_check(is_finite(pc.state.elapsed) and pc.state.elapsed == 0.0, "WAIT: NaN/INF dt ignored")
	pc.advance_time(t)
	_check(pc.is_complete(), "WAIT: still completes after bad dt values")
	for _i in 10:
		pc.attempt("tap_hurry")
	_check(pc.is_complete(), "WAIT: decoy taps after completion keep it complete")
	pc.reset()
	_check(pc.state.elapsed == 0.0 and not pc.is_complete() and pc.wrong_attempts == 0, "WAIT: reset restores t=0")
	var steps := int(ceil(t / 0.016)) + 1
	for _i in steps:
		pc.advance_time(0.016)
	_check(pc.is_complete(), "WAIT: replay with 60 fps steps completes")
	# No puzzle logic reads the system clock directly.
	for path in ["res://scripts/framework/puzzle_controller.gd", "res://scripts/framework/puzzle_state.gd",
			"res://scripts/framework/puzzle_definition.gd", "res://scripts/data/puzzles.gd"]:
		var src := FileAccess.get_file_as_string(path)
		var uses_clock := src.find("Time.") != -1 or src.find("OS.get_ticks") != -1 or src.find("get_unix_time") != -1
		_check(not uses_clock, "WAIT: %s does not read the system clock" % path.get_file())

## Objectives must be literally true (fairness): no promised failure that does
## not exist, and a named control must actually be part of the solution.
func _test_objective_honesty() -> void:
	var wait := Puzzles.get_def(3)
	var o := wait.objective.to_lower()
	_check(o.find("too late") == -1 and o.find("before") == -1,
		"P03: objective threatens no deadline (there is no fail state)")
	var btn := Puzzles.get_def(5)
	_check(_solution(btn).has("press_button"),
		"P05: objective says 'press the button' => pressing it is part of the solution")
	var pc := PuzzleController.new(btn)
	pc.attempt("press_button")
	_check(not pc.is_complete(), "P05: button alone (no power) does not open the door")
	pc.reset()
	pc.attempt("pull_lever")
	_check(not pc.is_complete(), "P05: the lever alone does not open the door")

func _test_save_extended() -> void:
	# partial settings: keep the valid keys, default only the missing one
	var partial := JSON.stringify({"save_data_version": 1,
		"progress": {"unlocked_max": 2, "levels": {"1": {"completed": true, "hints_used": 0}}},
		"settings": {"sound": false, "haptics": true, "reduced_motion": true, "high_contrast": false}})
	var o := SaveModel.load_from_string(partial, 1)
	_check(o["recovered"] and SaveModel.validate(o["save"], 1), "save: partial settings recover to valid")
	_check(o["save"]["settings"]["sound"] == false and o["save"]["settings"]["reduced_motion"] == true,
		"save: partial settings keep the player's valid choices")
	_check(SaveModel.is_completed(o["save"], 1) and int(o["save"]["progress"]["unlocked_max"]) == 2,
		"save: partial settings keep progress")
	# levels missing: unlocked_max must survive
	var no_levels := JSON.stringify({"save_data_version": 1, "progress": {"unlocked_max": 3},
		"settings": SaveModel.default_settings()})
	var o2 := SaveModel.load_from_string(no_levels, 1)
	_check(int(o2["save"]["progress"]["unlocked_max"]) == 3, "save: missing levels keeps unlocked_max")
	# one bad record among good ones
	var mixed := JSON.stringify({"save_data_version": 1, "progress": {"unlocked_max": 3, "levels": {
		"1": {"completed": true, "hints_used": 0}, "2": {"completed": "yes", "hints_used": -4}}},
		"settings": SaveModel.default_settings()})
	var o3 := SaveModel.load_from_string(mixed, 1)
	_check(SaveModel.is_completed(o3["save"], 1) and not o3["save"]["progress"]["levels"].has("2"),
		"save: bad level record dropped, good one kept")
	# unknown older / non-numeric version
	for v in [0, "1", null]:
		var txt := JSON.stringify({"save_data_version": v, "progress": {"unlocked_max": 2, "levels": {}},
			"settings": SaveModel.default_settings()})
		var ov := SaveModel.load_from_string(txt, 1)
		_check(ov["recovered"] and SaveModel.validate(ov["save"], 1), "save: version %s recovers to valid" % str(v))
	# non-object JSON
	for txt in ["[]", "42", "\"text\"", "null", "{\"save_data_version\": 1"]:
		var on := SaveModel.load_from_string(txt, 1)
		_check(SaveModel.validate(on["save"], 1), "save: '%s' recovers to valid default" % txt)
	# replay never regresses progression; best hint count is kept
	var s := SaveModel.default_save(1)
	s = SaveModel.record_completion(s, 1, 0, 5)
	s = SaveModel.record_completion(s, 2, 1, 5)
	s = SaveModel.record_completion(s, 1, 3, 5)
	_check(int(s["progress"]["unlocked_max"]) == 3, "save: replaying level 1 keeps unlocked_max")
	_check(int(s["progress"]["levels"]["1"]["hints_used"]) == 0, "save: replay keeps best hint count")
	s = SaveModel.record_completion(s, 5, 0, 5)
	_check(int(s["progress"]["unlocked_max"]) <= 5, "save: last level never unlocks beyond total")
	# record_completion is pure (input not mutated)
	var before := SaveModel.default_save(1)
	var snap := JSON.stringify(before)
	SaveModel.record_completion(before, 1, 0, 5)
	_check(JSON.stringify(before) == snap, "save: record_completion does not mutate its input")

## Definitions are rebuilt per call: mutating one never leaks into another test.
func _test_data_isolation() -> void:
	var a := Puzzles.get_def(1)
	a.actions.clear()
	a.initial_facts["tampered"] = true
	a.hints.clear()
	var b := Puzzles.get_def(1)
	_check(not b.actions.is_empty() and not b.initial_facts.has("tampered") and b.hints.size() == 3,
		"data: definitions are independent copies")
	var pc := PuzzleController.new(b)
	pc.state.set_fact("x", 1)
	pc.reset()
	_check(not pc.state.has_fact("x"), "data: reset discards ad-hoc facts")
	var c := PuzzleController.new(Puzzles.get_def(1))
	_check(not c.state.has_fact("x"), "data: controllers do not share state")

## Every shipped string renders with the bundled font (no tofu on devices that
## lack a system fallback), and UI code takes strings from Localization.
func _test_text_hygiene() -> void:
	var font: Font = ThemeDB.fallback_font
	var texts := []
	for key in Localization.STRINGS["en"].keys():
		texts.append(Localization.STRINGS["en"][key])
	for def in Puzzles.all():
		texts.append_array([def.title, def.objective])
		texts.append_array(def.hints)
		for it in def.interactables:
			texts.append_array([it.label, it.clue])
		for aid in def.actions.keys():
			for k in ["feedback", "fail_feedback"]:
				texts.append(str(def.actions[aid].get(k, "")))
	var missing := {}
	for t in texts:
		for ch in str(t):
			if ch.strip_edges() != "" and not font.has_char(ch.unicode_at(0)):
				missing[ch] = true
	_check(missing.is_empty(), "text: all data/locale glyphs in bundled font, missing=%s" % str(missing.keys()))
	# UI scripts: every Localization key exists; no hard-coded user-facing literals.
	var re_key := RegEx.create_from_string("Localization\\.t\\(\"([a-z_]+)\"\\)")
	var re_lit := RegEx.create_from_string("(make_title|make_body|make_button)\\(\"[A-Za-z]|\\.text = \"[A-Za-z]")
	var dir := DirAccess.open("res://scripts/ui")
	for f in dir.get_files():
		if not f.ends_with(".gd"):
			continue
		var src := FileAccess.get_file_as_string("res://scripts/ui/" + f)
		for m in re_key.search_all(src):
			_check(Localization.STRINGS["en"].has(m.get_string(1)), "text: key '%s' (%s) exists" % [m.get_string(1), f])
		_check(re_lit.search(src) == null, "text: %s has no hard-coded user-facing strings" % f)

## Safe-area insets are physical pixels; margins are logical (stretched) units.
func _test_safe_area_math() -> void:
	var style: GDScript = load("res://scripts/ui/style.gd")
	var names := style.get_script_method_list().map(func(d): return d["name"])
	if not names.has("safe_margins"):
		_check(false, "safe area: Style.safe_margins converts physical insets to logical units")
		return
	# 1080x2400 phone, 1.5x stretch => 720x1600 logical; 120 px notch, 60 px home bar.
	var m: Dictionary = style.call("safe_margins", Rect2i(0, 120, 1080, 2220), Vector2i(1080, 2400), Vector2(720, 1600), 12)
	_check(int(m["top"]) == 80 and int(m["bottom"]) == 40 and int(m["left"]) == 12 and int(m["right"]) == 12,
		"safe area: physical insets scaled to logical units %s" % str(m))
	var m2: Dictionary = style.call("safe_margins", Rect2i(0, 0, 720, 1280), Vector2i(720, 1280), Vector2(720, 1280), 12)
	_check(int(m2["top"]) == 12 and int(m2["bottom"]) == 12, "safe area: no inset => minimum gap")
