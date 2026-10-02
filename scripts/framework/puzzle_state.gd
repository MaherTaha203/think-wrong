extends RefCounted
class_name PuzzleState
## Mutable per-attempt state for a puzzle: a flat bag of named facts plus an
## elapsed-time accumulator (driven by an injected clock so logic is testable
## without real time). Pure — no UI, no autoload dependencies.

var facts: Dictionary = {}
var elapsed: float = 0.0

func _init(initial: Dictionary = {}) -> void:
	facts = initial.duplicate(true)

func get_fact(key: String, default = null):
	return facts.get(key, default)

func set_fact(key: String, value) -> void:
	facts[key] = value

func has_fact(key: String) -> bool:
	return facts.has(key)

func advance_time(dt: float) -> void:
	elapsed += maxf(0.0, dt)

func snapshot() -> Dictionary:
	return {"facts": facts.duplicate(true), "elapsed": elapsed}
