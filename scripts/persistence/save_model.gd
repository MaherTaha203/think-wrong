extends RefCounted
class_name SaveModel
## Pure, dependency-free save-data logic for THINK WRONG (no autoloads), so it is
## fully verifiable in headless tests. SaveManager (autoload) wraps this with file
## I/O. Robust against first launch, missing/corrupt/future saves; never destroys
## valid progress silently.

const MAX_LEVELS_GUARD := 10000

static func default_settings() -> Dictionary:
	return {
		"sound": true, "haptics": true,
		"reduced_motion": false, "high_contrast": false, "language": "en",
	}

static func default_save(version: int) -> Dictionary:
	return {
		"save_data_version": version,
		"progress": {"unlocked_max": 1, "levels": {}},
		"settings": default_settings(),
	}

# --- validation -----------------------------------------------------------
static func validate(data, version: int) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if int(data.get("save_data_version", -1)) != version:
		return false
	var progress = data.get("progress")
	if typeof(progress) != TYPE_DICTIONARY:
		return false
	if int(progress.get("unlocked_max", 0)) < 1:
		return false
	if typeof(progress.get("levels")) != TYPE_DICTIONARY:
		return false
	for k in progress["levels"].keys():
		if not _valid_level_record(progress["levels"][k]):
			return false
	return _valid_settings(data.get("settings"))

static func _valid_level_record(v) -> bool:
	if typeof(v) != TYPE_DICTIONARY:
		return false
	if typeof(v.get("completed")) != TYPE_BOOL:
		return false
	if not (v.get("hints_used") is int or v.get("hints_used") is float):
		return false
	return int(v.get("hints_used", 0)) >= 0

static func _valid_settings(v) -> bool:
	if typeof(v) != TYPE_DICTIONARY:
		return false
	for k in ["sound", "haptics", "reduced_motion", "high_contrast"]:
		if typeof(v.get(k)) != TYPE_BOOL:
			return false
	return typeof(v.get("language")) == TYPE_STRING

# --- migration (chain; none needed yet at v1, structure ready) ------------
static func migrate(data: Dictionary, version: int) -> Dictionary:
	var v := int(data.get("save_data_version", 0))
	# Future migration steps go here: while v < version: ... ; v += 1
	# At v1 there are no prior versions to upgrade from.
	if v == version:
		return data
	# Unknown/older with no defined step: signal caller to recover.
	return {}

# --- resilient load -------------------------------------------------------
# Returns {"save": Dictionary, "recovered": bool, "migrated": bool}
static func load_from_string(text: String, version: int) -> Dictionary:
	if text == null or text.strip_edges() == "":
		return {"save": default_save(version), "recovered": false, "migrated": false}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"save": default_save(version), "recovered": true, "migrated": false}

	var migrated := false
	var v = parsed.get("save_data_version")
	if not (v is int or v is float):
		return {"save": _salvage(parsed, version), "recovered": true, "migrated": false}
	v = int(v)
	if v > version:
		# Unknown future version — do not risk misreading it.
		return {"save": default_save(version), "recovered": true, "migrated": false}
	if v < version:
		var m := migrate(parsed, version)
		if m.is_empty():
			return {"save": _salvage(parsed, version), "recovered": true, "migrated": false}
		parsed = m
		migrated = true

	if validate(parsed, version):
		return {"save": parsed, "recovered": false, "migrated": migrated}
	return {"save": _salvage(parsed, version), "recovered": true, "migrated": migrated}

static func _salvage(data, version: int) -> Dictionary:
	var save := default_save(version)
	if typeof(data) == TYPE_DICTIONARY and typeof(data.get("progress")) == TYPE_DICTIONARY:
		var levels = data["progress"].get("levels")
		if typeof(levels) == TYPE_DICTIONARY:
			var good := {}
			var max_unlocked := 1
			for k in levels.keys():
				var rec = levels[k]
				if _valid_level_record(rec):
					good[k] = rec
					if bool(rec.get("completed", false)) and str(k).is_valid_int():
						max_unlocked = max(max_unlocked, int(k) + 1)
			save["progress"]["levels"] = good
			var um = data["progress"].get("unlocked_max", 1)
			save["progress"]["unlocked_max"] = max(max_unlocked, int(um) if (um is int or um is float) else 1)
	if _valid_settings(data.get("settings") if typeof(data) == TYPE_DICTIONARY else null):
		save["settings"] = data["settings"]
	return save

# --- progression (pure) ---------------------------------------------------
static func record_completion(save: Dictionary, level_id: int, hints_used: int, total_levels: int) -> Dictionary:
	save = save.duplicate(true)
	var key := str(level_id)
	var levels: Dictionary = save["progress"]["levels"]
	var prev: Dictionary = levels.get(key, {"completed": false, "hints_used": -1})
	var best_hints := hints_used
	if int(prev.get("hints_used", -1)) >= 0:
		best_hints = min(int(prev["hints_used"]), hints_used)
	levels[key] = {"completed": true, "hints_used": best_hints}
	var next_level := level_id + 1
	if next_level <= total_levels:
		save["progress"]["unlocked_max"] = max(int(save["progress"]["unlocked_max"]), next_level)
	return save

static func is_unlocked(save: Dictionary, level_id: int) -> bool:
	return level_id <= int(save["progress"]["unlocked_max"])

static func is_completed(save: Dictionary, level_id: int) -> bool:
	var rec = save["progress"]["levels"].get(str(level_id), {})
	return bool(rec.get("completed", false))
