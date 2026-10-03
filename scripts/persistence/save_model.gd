extends RefCounted
class_name SaveModel
## Pure, dependency-free save-data logic for THINK WRONG (no autoloads), so it is
## fully verifiable in headless tests. SaveManager (autoload) wraps this with file
## I/O. Robust against first launch, missing/corrupt/partial/future saves; keeps
## every valid piece of progress and settings it can (salvage).

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

const BOOL_SETTINGS := ["sound", "haptics", "reduced_motion", "high_contrast"]

static func _valid_settings(v) -> bool:
	if typeof(v) != TYPE_DICTIONARY:
		return false
	for k in BOOL_SETTINGS:
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
	var json := JSON.new()   # instance parse: reports errors without log spam
	if json.parse(text) != OK:
		return {"save": default_save(version), "recovered": true, "migrated": false}
	var parsed = json.data
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

## Rebuild a valid save from whatever is usable: each valid level record, the
## unlock frontier (stored or implied by completions), and each valid setting.
static func _salvage(data, version: int) -> Dictionary:
	var save := default_save(version)
	if typeof(data) != TYPE_DICTIONARY:
		return save
	var progress = data.get("progress")
	if typeof(progress) == TYPE_DICTIONARY:
		var max_unlocked := 1
		var um = progress.get("unlocked_max", 1)
		if (um is int or um is float) and is_finite(float(um)):
			max_unlocked = maxi(1, int(um))
		var levels = progress.get("levels")
		if typeof(levels) == TYPE_DICTIONARY:
			var good := {}
			for k in levels.keys():
				var rec = levels[k]
				if _valid_level_record(rec):
					good[str(k)] = {"completed": rec["completed"], "hints_used": int(rec["hints_used"])}
					if bool(rec["completed"]) and str(k).is_valid_int():
						max_unlocked = maxi(max_unlocked, int(k) + 1)
			save["progress"]["levels"] = good
		save["progress"]["unlocked_max"] = max_unlocked
	var settings = data.get("settings")
	if typeof(settings) == TYPE_DICTIONARY:
		for k in BOOL_SETTINGS:
			if typeof(settings.get(k)) == TYPE_BOOL:
				save["settings"][k] = settings[k]
		if typeof(settings.get("language")) == TYPE_STRING:
			save["settings"]["language"] = settings["language"]
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
