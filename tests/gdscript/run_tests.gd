extends SceneTree
## Headless deterministic tests for THINK WRONG (no UI, no autoloads, no real
## time). Covers the framework, all five puzzles (7 checks each), the save model
## (first launch / missing / valid / completed / corrupt / future / reset /
## salvage) and the WAIT puzzle via an injected clock.
##
## Run: godot --headless --path . --script tests/gdscript/run_tests.gd

var _checks := 0
var _failures := 0

func _init() -> void:
	_test_framework()
	_test_each_puzzle()
	_test_wait_clock()
	_test_save()
	print("THINK WRONG tests: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		print("FAIL: " + msg)
		push_error("FAIL: " + msg)

func _solving_action(def: PuzzleDefinition) -> String:
	for aid in def.actions.keys():
		if bool(def.actions[aid].get("solves", false)):
			return aid
	return ""

func _wrong_action(def: PuzzleDefinition) -> String:
	for aid in def.actions.keys():
		if not bool(def.actions[aid].get("solves", false)):
			return aid
	return ""

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
	var solve := _solving_action(def)
	_check(pc.attempt(solve) == PuzzleController.Result.OK_COMPLETED, "fw: solve completes")
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
			var solve := _solving_action(def)
			_check(solve != "", tag + ": has a solving action")
			_check(pc.attempt(solve) == PuzzleController.Result.OK_COMPLETED, tag + ": solving action completes")
		# 6. completion flag
		_check(pc.is_complete(), tag + ": is_complete after solution")

		# 4. reset
		pc.reset()
		_check(not pc.is_complete(), tag + ": reset clears completion")
		_check(pc.wrong_attempts == 0, tag + ": reset clears attempts")

		# 5. replay
		if def.time_threshold > 0.0:
			pc.advance_time(def.time_threshold + 0.01)
		else:
			pc.attempt(_solving_action(def))
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
