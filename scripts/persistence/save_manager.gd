extends Node
## Autoload: local, versioned, corruption-resilient save (file I/O wrapper around
## the pure SaveModel). No backend. Writes are atomic (temp + rename) so an
## interrupted write never yields an empty save.

const SAVE_PATH := "user://think_wrong_save.json"
const TMP_PATH := "user://think_wrong_save.json.tmp"

var data: Dictionary = {}

signal progress_changed()

func _ready() -> void:
	load_game()

func load_game() -> Dictionary:
	var text := ""
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			text = f.get_as_text()
			f.close()
	var outcome := SaveModel.load_from_string(text, Versions.SAVE_DATA_VERSION)
	data = outcome["save"]
	return outcome

func save_game() -> bool:
	var text := JSON.stringify(data, "\t")
	var tmp := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if tmp == null:
		push_error("SaveManager: cannot open temp save for writing")
		return false
	tmp.store_string(text)
	tmp.flush()
	tmp.close()
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH))
	if err != OK:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f == null:
			return false
		f.store_string(text)
		f.flush()
		f.close()
	return true

func settings() -> Dictionary:
	return data["settings"]

func unlocked_max() -> int:
	return int(data["progress"]["unlocked_max"])

func is_unlocked(level_id: int) -> bool:
	return SaveModel.is_unlocked(data, level_id)

func is_completed(level_id: int) -> bool:
	return SaveModel.is_completed(data, level_id)

func record_completion(level_id: int, hints_used: int, total_levels: int) -> void:
	data = SaveModel.record_completion(data, level_id, hints_used, total_levels)
	save_game()
	progress_changed.emit()

func reset_progress() -> void:
	var kept: Dictionary = data.get("settings", SaveModel.default_settings())
	data = SaveModel.default_save(Versions.SAVE_DATA_VERSION)
	data["settings"] = kept
	save_game()
	progress_changed.emit()

func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	save_game()
