extends Node
## Autoload: session state and the bridge between screens and persistence.

var current_level_id: int = 1
var total_levels: int = 0
var last_result: Dictionary = {}

func _ready() -> void:
	total_levels = Puzzles.count()

func select_level(level_id: int) -> void:
	current_level_id = clampi(level_id, 1, maxi(1, total_levels))

func has_next_level() -> bool:
	return current_level_id < total_levels

func next_level_id() -> int:
	return mini(current_level_id + 1, total_levels)

## Record a solved puzzle. Returns the result dict stored in last_result.
func complete_level(level_id: int, hints_used: int) -> Dictionary:
	SaveManager.record_completion(level_id, hints_used, total_levels)
	last_result = {
		"level_id": level_id,
		"hints_used": hints_used,
		"has_next": has_next_level(),
	}
	return last_result
