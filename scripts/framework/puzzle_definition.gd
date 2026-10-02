extends RefCounted
class_name PuzzleDefinition
## Data-driven definition of one puzzle. The controller is generic; a puzzle is
## just this data, so new content is added without touching core code.
##
## actions: id -> {
##     "label": String,
##     "requires": {fact: value, ...}      # optional preconditions
##     "effects":  {fact: value, ...}      # applied on a successful attempt
##     "solves":   bool                    # whether it can complete the puzzle
##     "feedback": String                  # message shown to the player
##     "progress": bool                    # true if it legitimately changes state
## }
## completion: { "facts": {fact: value, ...}, "min_elapsed": float }
## A puzzle is solved when every required fact matches AND elapsed >= min_elapsed.

var id: int
var key: String
var title: String
var objective: String
var assumption: String           # the obvious (wrong) assumption — design note
var interactables: Array = []    # Array[Interactable]
var actions: Dictionary = {}
var initial_facts: Dictionary = {}
var completion: Dictionary = {"facts": {}, "min_elapsed": 0.0}
var hints: Array = []            # [assumption-challenge, relationship, solution]
var time_threshold: float = 0.0  # > 0 for time-based puzzles (WAIT)

func _init(data: Dictionary) -> void:
	id = int(data.get("id", 0))
	key = str(data.get("key", ""))
	title = str(data.get("title", ""))
	objective = str(data.get("objective", ""))
	assumption = str(data.get("assumption", ""))
	for it in data.get("interactables", []):
		interactables.append(it if it is Interactable else Interactable.new(it))
	actions = data.get("actions", {}).duplicate(true)
	initial_facts = data.get("initial_facts", {}).duplicate(true)
	completion = data.get("completion", {"facts": {}, "min_elapsed": 0.0}).duplicate(true)
	if not completion.has("facts"):
		completion["facts"] = {}
	if not completion.has("min_elapsed"):
		completion["min_elapsed"] = 0.0
	hints = data.get("hints", []).duplicate(true)
	time_threshold = float(data.get("time_threshold", 0.0))

func action_ids() -> Array:
	return actions.keys()

func interactable_ids() -> Array:
	var out := []
	for it in interactables:
		out.append(it.id)
	return out
