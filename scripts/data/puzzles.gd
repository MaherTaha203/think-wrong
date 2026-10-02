extends RefCounted
class_name Puzzles
## The five prototype puzzles, expressed purely as PuzzleDefinition data. Each
## challenges an obvious assumption fairly: every solving interaction is visible
## and clued; no invisible hitboxes, no pixel hunting, no arbitrary taps.

static func count() -> int:
	return _specs().size()

static func all() -> Array:
	var out := []
	for s in _specs():
		out.append(PuzzleDefinition.new(s))
	return out

static func get_def(level_id: int) -> PuzzleDefinition:
	for s in _specs():
		if int(s["id"]) == level_id:
			return PuzzleDefinition.new(s)
	return null

static func _specs() -> Array:
	return [
		# ---- Puzzle 01 — DON'T TOUCH ------------------------------------
		{
			"id": 1, "key": "dont_touch", "title": "DON'T TOUCH",
			"objective": "Open the door.",
			"assumption": "The big button is the way to progress.",
			"interactables": [
				{"id": "button", "label": "DO NOT TOUCH", "kind": "button", "action": "touch_button",
				 "position": Vector2(0.5, 0.42), "clue": "A loud warning — suspiciously attention-grabbing."},
				{"id": "door", "label": "Door", "kind": "door", "action": "open_door",
				 "position": Vector2(0.5, 0.74), "clue": "An ordinary closed door with a handle. The objective names it."},
			],
			"actions": {
				"touch_button": {"solves": false, "progress": false,
					"feedback": "A buzzer sounds. The door stays shut."},
				"open_door": {"solves": true, "progress": true,
					"effects": {"door_open": true}, "feedback": "You simply open the door."},
			},
			"completion": {"facts": {"door_open": true}, "min_elapsed": 0.0},
			"hints": [
				"The button is shouting for your attention. Re-read the objective — does it mention the button?",
				"You were asked to open the door. The door is right there, with a handle.",
				"Ignore the button. Tap the door itself to open it.",
			],
		},
		# ---- Puzzle 02 — THE KEY ----------------------------------------
		{
			"id": 2, "key": "the_key", "title": "THE KEY",
			"objective": "Unlock the lock.",
			"assumption": "The key must travel to the lock.",
			"interactables": [
				{"id": "key", "label": "Key", "kind": "key", "anchored": true, "action": "move_key_to_lock",
				 "position": Vector2(0.28, 0.5), "clue": "The key is bolted to the wall — it cannot move."},
				{"id": "lock", "label": "Lock", "kind": "lock", "movable": true, "action": "move_lock_to_key",
				 "position": Vector2(0.72, 0.5), "clue": "The lock sits on a sliding rail — it can be moved."},
			],
			"actions": {
				"move_key_to_lock": {"solves": false, "progress": false,
					"feedback": "The key is bolted down. It won't move."},
				"move_lock_to_key": {"solves": true, "progress": true,
					"effects": {"unlocked": true}, "feedback": "The lock slides onto the key. Click — unlocked."},
			},
			"completion": {"facts": {"unlocked": true}, "min_elapsed": 0.0},
			"hints": [
				"You assume the key is the thing that must move.",
				"Look at the affordances: the key is bolted; the lock is on a rail.",
				"Move the lock to the key, not the key to the lock.",
			],
		},
		# ---- Puzzle 03 — WAIT -------------------------------------------
		{
			"id": 3, "key": "wait", "title": "WAIT",
			"objective": "Get through the door before it's too late.",
			"assumption": "Urgency means you must act quickly.",
			"interactables": [
				{"id": "timer", "label": "Timer", "kind": "timer",
				 "position": Vector2(0.5, 0.36), "clue": "Counts down. The text says the door opens when it reaches zero."},
				{"id": "hurry", "label": "HURRY!", "kind": "button", "action": "tap_hurry",
				 "position": Vector2(0.5, 0.6), "clue": "A tempting 'skip' button — but nothing says it does anything."},
				{"id": "door", "label": "Door", "kind": "door",
				 "position": Vector2(0.5, 0.8), "clue": "Opens on its own when the timer ends."},
			],
			"actions": {
				"tap_hurry": {"solves": false, "progress": false,
					"feedback": "The timer can't be rushed."},
			},
			"completion": {"facts": {}, "min_elapsed": 3.0},
			"time_threshold": 3.0,
			"hints": [
				"Urgency is a feeling the scene is giving you — not a rule.",
				"Read it literally: the door opens when the timer ends. Do you need to do anything?",
				"Do nothing. Wait for the timer to reach zero; the door opens by itself.",
			],
		},
		# ---- Puzzle 04 — THE BOX ----------------------------------------
		{
			"id": 4, "key": "the_box", "title": "THE BOX",
			"objective": "Put the object in the box.",
			"assumption": "The object must move into the box.",
			"interactables": [
				{"id": "object", "label": "Object", "kind": "object", "anchored": true, "action": "move_object_to_box",
				 "position": Vector2(0.32, 0.55), "clue": "Pinned in place — it will not move."},
				{"id": "box", "label": "Box", "kind": "box", "movable": true, "action": "move_box_to_object",
				 "position": Vector2(0.7, 0.55), "clue": "On casters — it slides freely."},
			],
			"actions": {
				"move_object_to_box": {"solves": false, "progress": false,
					"feedback": "The object is pinned down. It won't budge."},
				"move_box_to_object": {"solves": true, "progress": true,
					"effects": {"in_box": true}, "feedback": "You slide the box over the object. It's in."},
			},
			"completion": {"facts": {"in_box": true}, "min_elapsed": 0.0},
			"hints": [
				"You assume the object goes to the box.",
				"Which one can actually move? The object is pinned; the box is on casters.",
				"Move the box onto the object.",
			],
		},
		# ---- Puzzle 05 — THE BUTTON -------------------------------------
		# Fairness redesign: the secondary control is VISIBLE (overlooked, not
		# hidden). The obvious button gives a logical "no power" clue pointing to
		# the clearly-shown lever. No pixel hunting, no invisible interaction.
		{
			"id": 5, "key": "the_button", "title": "THE BUTTON",
			"objective": "Press the button to open the door.",
			"assumption": "The labelled button is the control that works.",
			"interactables": [
				{"id": "button", "label": "OPEN", "kind": "button", "action": "press_button",
				 "position": Vector2(0.5, 0.45), "clue": "Labelled OPEN — but shows a dim 'no power' light."},
				{"id": "lever", "label": "Power", "kind": "lever", "movable": true, "action": "pull_lever",
				 "position": Vector2(0.78, 0.66), "clue": "A visible power lever on the wall, currently down."},
				{"id": "door", "label": "Door", "kind": "door",
				 "position": Vector2(0.5, 0.82), "clue": "Opens once power reaches the mechanism."},
			],
			"actions": {
				"press_button": {"solves": false, "progress": false,
					"feedback": "No power. The button is dead — something upstream is off."},
				"pull_lever": {"solves": true, "progress": true,
					"effects": {"door_open": true},
					"feedback": "The lever engages the power. The door slides open."},
			},
			"completion": {"facts": {"door_open": true}, "min_elapsed": 0.0},
			"hints": [
				"The obvious button isn't the only control on screen.",
				"The button told you 'no power'. What else, clearly visible, could supply it?",
				"Pull the power lever on the wall; that opens the door.",
			],
		},
	]
