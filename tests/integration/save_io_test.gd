extends Node
## Headless integration test for SaveManager file I/O with the real autoloads:
## fresh install, valid round-trip, corrupted / partial / unknown-version files,
## backup of unreadable saves, reset, replay, atomic writes, settings signal, and
## booting the real Main scene on a corrupted save.
##
## Isolated: uses a temporary user:// file, verifies the real player save is
## untouched, and deletes everything it created. Exit code 1 on any failure.
##   godot --headless --path . res://tests/integration/save_io_test.tscn

const TEST_SAVE := "user://it_save_io_test.json"

var _checks := 0
var _failures := 0

func _ready() -> void:
	var real_before := _md5(SaveManager.DEFAULT_SAVE_PATH)
	await _run()
	_cleanup()
	_check(_md5(SaveManager.DEFAULT_SAVE_PATH) == real_before, "isolation: real player save untouched")
	_check(not FileAccess.file_exists(TEST_SAVE), "isolation: test save removed")
	SaveManager.save_path = SaveManager.DEFAULT_SAVE_PATH
	print("THINK WRONG save I/O tests: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)

func _run() -> void:
	var v := Versions.SAVE_DATA_VERSION
	var total := Puzzles.count()

	# Fresh install: no file => defaults, nothing written until a save happens.
	var o := SaveManager.use_save_path(TEST_SAVE, true)
	_check(not o["recovered"] and SaveManager.unlocked_max() == 1, "fresh: defaults, not 'recovered'")
	_check(not FileAccess.file_exists(TEST_SAVE), "fresh: loading creates no file")

	# Valid save round-trip.
	SaveManager.record_completion(1, 2, total)
	SaveManager.set_setting("sound", false)
	_check(FileAccess.file_exists(TEST_SAVE), "valid: record_completion writes the file")
	_check(not FileAccess.file_exists(TEST_SAVE + ".tmp"), "valid: atomic write leaves no temp file")
	SaveManager.data = {}
	o = SaveManager.load_game()
	_check(not o["recovered"] and SaveManager.is_completed(1) and SaveManager.unlocked_max() == 2,
		"valid: progress restored")
	_check(SaveManager.settings()["sound"] == false, "valid: settings restored")

	# Replay keeps progression and the best hint count.
	SaveManager.record_completion(1, 3, total)
	_check(SaveManager.unlocked_max() == 2 and int(SaveManager.data["progress"]["levels"]["1"]["hints_used"]) == 2,
		"replay: progression and best hints unchanged")

	# Corrupted file => no crash, defaults, original bytes preserved as a backup.
	var garbage := "{\"save_data_version\": 1, \"progress\": {\"unlocked_max\": 4,"
	_write(TEST_SAVE, garbage)
	o = SaveManager.load_game()
	_check(o["recovered"] and SaveModel.validate(SaveManager.data, v), "corrupt: recovers to a valid save")
	_check(FileAccess.file_exists(TEST_SAVE + ".bak") and FileAccess.get_file_as_string(TEST_SAVE + ".bak") == garbage,
		"corrupt: unreadable original kept as .bak before any overwrite")

	# Partial file: valid progress, incomplete settings => progress + valid settings kept.
	_write(TEST_SAVE, JSON.stringify({"save_data_version": v,
		"progress": {"unlocked_max": 3, "levels": {"1": {"completed": true, "hints_used": 0},
			"2": {"completed": true, "hints_used": 1}}},
		"settings": {"sound": false, "haptics": false}}))
	o = SaveManager.load_game()
	_check(o["recovered"] and SaveManager.unlocked_max() == 3 and SaveManager.is_completed(2), "partial: progress kept")
	_check(SaveManager.settings()["sound"] == false and SaveManager.settings()["haptics"] == false
		and SaveManager.settings()["language"] == "en", "partial: valid settings kept, missing ones defaulted")

	# Unknown (future) version => safe defaults, and the newer file is preserved.
	var future := JSON.stringify({"save_data_version": v + 7, "progress": {"unlocked_max": 5, "levels": {}}, "settings": {}})
	_write(TEST_SAVE, future)
	o = SaveManager.load_game()
	_check(o["recovered"] and SaveManager.unlocked_max() == 1, "future version: safe defaults")
	SaveManager.save_game()
	_check(FileAccess.get_file_as_string(TEST_SAVE + ".bak") == future,
		"future version: newer data preserved in .bak after the next save")

	# Reset progress => clean progress, settings kept, persisted.
	SaveManager.record_completion(1, 0, total)
	SaveManager.set_setting("reduced_motion", true)
	SaveManager.reset_progress()
	SaveManager.data = {}
	SaveManager.load_game()
	_check(SaveManager.unlocked_max() == 1 and SaveManager.data["progress"]["levels"].is_empty(),
		"reset: progress cleared on disk")
	_check(SaveManager.settings()["reduced_motion"] == true, "reset: settings survive")

	# Settings changes are broadcast so already-built UI (background) can update.
	_check(SaveManager.has_signal("settings_changed"), "settings: settings_changed signal exists")
	if SaveManager.has_signal("settings_changed"):
		var seen := []
		var cb := func(key): seen.append(key)
		SaveManager.connect("settings_changed", cb)
		SaveManager.set_setting("high_contrast", true)
		SaveManager.disconnect("settings_changed", cb)
		_check(seen == ["high_contrast"], "settings: change emitted once with its key")
		SaveManager.set_setting("high_contrast", false)

	# Boot the real Main scene on a corrupted save: must reach the menu, no crash.
	_write(TEST_SAVE, "\u0000\u0001 not json at all")
	SaveManager.load_game()
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	for _i in 30:
		await get_tree().process_frame
	var cur = ScreenManager._current
	_check(cur != null and cur.get_script() != null
		and cur.get_script().resource_path.ends_with("main_menu.gd"), "boot: corrupted save still reaches the main menu")
	main.queue_free()
	await get_tree().process_frame

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _md5(path: String) -> String:
	return FileAccess.get_md5(path) if FileAccess.file_exists(path) else "<absent>"

func _cleanup() -> void:
	SaveManager.discard_save_file()
	for p in [TEST_SAVE + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		print("FAIL: " + msg)
