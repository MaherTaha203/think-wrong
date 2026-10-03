extends Node
## Autoload: local, versioned, corruption-resilient save (file I/O wrapper around
## the pure SaveModel). No backend. Writes are atomic (temp + rename) so an
## interrupted write never yields an empty save. A file that cannot be read as-is
## (corrupt, partial, or from a newer version) is copied to <save>.bak before it
## can be overwritten, so no player data is ever destroyed silently.

const DEFAULT_SAVE_PATH := "user://think_wrong_save.json"

# Overridable only so QA/test harnesses can use an isolated temporary file and
# never touch a real player's save. The game itself always uses the default.
var save_path := DEFAULT_SAVE_PATH
var data: Dictionary = {}

signal progress_changed()
signal settings_changed(key: String)

func _ready() -> void:
	load_game()

func load_game() -> Dictionary:
	var text := ""
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f != null:
			text = f.get_as_text()
			f.close()
	var outcome := SaveModel.load_from_string(text, Versions.SAVE_DATA_VERSION)
	data = outcome["save"]
	if outcome["recovered"]:
		_backup_unreadable(text)
	return outcome

func _backup_unreadable(text: String) -> void:
	var f := FileAccess.open(backup_path(), FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: could not back up unreadable save")
		return
	f.store_string(text)
	f.close()

func backup_path() -> String:
	return save_path + ".bak"

func save_game() -> bool:
	var text := JSON.stringify(data, "\t")
	var tmp_path := save_path + ".tmp"
	var tmp := FileAccess.open(tmp_path, FileAccess.WRITE)
	if tmp == null:
		push_error("SaveManager: cannot open temp save for writing")
		return false
	tmp.store_string(text)
	tmp.flush()
	tmp.close()
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp_path),
		ProjectSettings.globalize_path(save_path))
	if err != OK:
		var f := FileAccess.open(save_path, FileAccess.WRITE)
		if f == null:
			return false
		f.store_string(text)
		f.flush()
		f.close()
	return true

## Test support: switch to an isolated save file and reload from it.
func use_save_path(path: String, start_fresh: bool = false) -> Dictionary:
	save_path = path
	if start_fresh:
		discard_save_file()
	return load_game()

## Test support: delete the current save file (and its temp/backup files).
func discard_save_file() -> void:
	for p in [save_path, save_path + ".tmp", backup_path()]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

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
	settings_changed.emit(key)
