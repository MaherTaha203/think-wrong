extends RefCounted
class_name HintController
## Progressive, offline, deterministic hints. Tier 1 challenges the assumption,
## tier 2 points at the relevant relationship, tier 3 is the explicit solution.
## Never reveals the solution immediately; never uses a network or AI.

var _hints: Array
var tier: int = 0   # 0 = none shown yet; 1..N revealed

func _init(hints: Array) -> void:
	_hints = hints.duplicate()

func total() -> int:
	return _hints.size()

func has_more() -> bool:
	return tier < _hints.size()

func is_solution_visible() -> bool:
	# The last tier is the explicit solution.
	return tier >= _hints.size() and _hints.size() > 0

## Reveal the next hint tier; returns the revealed text or "" if none remain.
func reveal_next() -> String:
	if tier >= _hints.size():
		return ""
	var text: String = _hints[tier]
	tier += 1
	return text

func revealed() -> Array:
	return _hints.slice(0, tier)

func used_count() -> int:
	return tier

func reset() -> void:
	tier = 0
