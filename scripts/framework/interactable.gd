extends RefCounted
class_name Interactable
## Declarative descriptor of a thing the player can act on. This is data (id,
## label, kind, affordances, a position for the UI, and an optional clue). It does
## not itself contain behavior — behavior lives in the puzzle's actions, so logic
## stays testable without instantiating UI.
##
## Fairness: every interactable that matters to a solution MUST be visible and
## carry a discoverable affordance/clue. There are no invisible interactables.
## The clue is rendered on screen as a caption under the control; `clue_on` lets
## the caption follow the puzzle state (e.g. a power light turning on) so the
## screen never shows stale information.

var id: String
var label: String
var kind: String              # "button", "door", "key", "lock", "box", "object", "lever", "timer"
var position: Vector2         # normalized [0,1] placement hint for the UI
var movable: bool             # semantic: this thing can be moved (caption says how)
var anchored: bool            # semantic: fixed in place, never the thing to move
var clue: String              # short, fair, always-visible caption
var clue_on: Dictionary       # fact -> caption shown instead while that fact is true
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
	clue_on = data.get("clue_on", {}).duplicate()
	action = str(data.get("action", ""))

func is_interactive() -> bool:
	return action != ""

## The caption to show for the given puzzle facts (pure).
func caption(facts: Dictionary) -> String:
	for fact in clue_on.keys():
		if bool(facts.get(fact, false)):
			return str(clue_on[fact])
	return clue
