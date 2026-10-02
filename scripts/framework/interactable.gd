extends RefCounted
class_name Interactable
## Declarative descriptor of a thing the player can act on. This is data (id,
## label, kind, affordances, a position for the UI, and an optional clue). It does
## not itself contain behavior — behavior lives in the puzzle's actions, so logic
## stays testable without instantiating UI.
##
## Fairness: every interactable that matters to a solution MUST be visible and
## carry a discoverable affordance/clue. There are no invisible interactables.

var id: String
var label: String
var kind: String              # "button", "door", "key", "lock", "box", "object", "lever", "timer"
var position: Vector2         # normalized [0,1] placement hint for the UI
var movable: bool             # shows drag affordance
var anchored: bool            # shows "fixed in place" affordance
var clue: String              # short, fair hint rendered subtly / in hints
var action: String            # action id this control triggers when tapped ("" = display-only)

func _init(data: Dictionary) -> void:
	id = str(data.get("id", ""))
	label = str(data.get("label", ""))
	kind = str(data.get("kind", "button"))
	var p = data.get("position", Vector2(0.5, 0.5))
	position = p if p is Vector2 else Vector2(0.5, 0.5)
	movable = bool(data.get("movable", false))
	anchored = bool(data.get("anchored", false))
	clue = str(data.get("clue", ""))
	action = str(data.get("action", ""))

func is_interactive() -> bool:
	return action != ""
