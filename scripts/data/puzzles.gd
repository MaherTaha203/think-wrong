extends RefCounted
class_name Puzzles
## The five prototype puzzles, expressed purely as PuzzleDefinition data. Each
## challenges an obvious assumption fairly: every solving interaction is a
## visible, labelled control; every clue is an on-screen caption; objectives are
## literally true; no invisible hitboxes, no pixel hunting, no outside knowledge.
##
## Captions ("clue") are short, factual observations of the scene — never
## designer commentary — so showing them is honest without solving the puzzle.

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
				 "position": Vector2(0.5, 0.3), "clue": "Wired to a buzzer."},
				{"id": "door", "label": "Door", "kind": "door", "action": "open_door",
				 "position": Vector2(0.5, 0.72), "clue": "Closed. It has a handle.",
				 "clue_on": {"door_open": "Open."}},
			],
			"actions": {
				"touch_button": {"solves": false, "progress": false,
					"feedback": "A buzzer sounds. The door stays shut."},
				"open_door": {"solves": true, "progress": true,
					"effects": {"door_open": true}, "feedback": "You simply open the door."},
			},
			"completion": {"facts": {"door_open": true}, "min_elapsed": 0.0},
			"solution": ["open_door"],
			"hints": [
				"The button is shouting for your attention. Re-read the objective: does it mention the button?",
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
				 "position": Vector2(0.28, 0.5), "clue": "Bolted to the wall."},
				{"id": "lock", "label": "Lock", "kind": "lock", "movable": true, "action": "move_lock_to_key",
				 "position": Vector2(0.72, 0.5), "clue": "On a sliding rail.",
				 "clue_on": {"unlocked": "Unlocked."}},
			],
			"actions": {
				"move_key_to_lock": {"solves": false, "progress": false,
					"feedback": "The key is bolted down. It won't move."},
				"move_lock_to_key": {"solves": true, "progress": true,
					"effects": {"unlocked": true}, "feedback": "The lock slides onto the key. Click: unlocked."},
			},
			"completion": {"facts": {"unlocked": true}, "min_elapsed": 0.0},
			"solution": ["move_lock_to_key"],
			"hints": [
				"You assume the key is the thing that must move.",
				"Read the captions: the key is bolted; the lock is on a rail.",
				"Move the lock to the key: tap the lock.",
			],
		},
		# ---- Puzzle 03 — WAIT -------------------------------------------
		# The countdown and the HURRY! button create urgency; nothing is at stake
		# and nothing fails. The objective is honest ("get through the door"), and
		# the timer's caption states literally what happens at zero.
		{
			"id": 3, "key": "wait", "title": "WAIT",
			"objective": "Get through the door.",
			"assumption": "A countdown means you must act quickly.",
			"interactables": [
				{"id": "timer", "label": "Timer", "kind": "timer",
				 "position": Vector2(0.5, 0.2), "clue": "At zero, the door opens."},
				{"id": "hurry", "label": "HURRY!", "kind": "button", "action": "tap_hurry",
				 "position": Vector2(0.5, 0.5), "clue": "No wires attached."},
				{"id": "door", "label": "Door", "kind": "door",
				 "position": Vector2(0.5, 0.8), "clue": "Closed."},
			],
			"actions": {
				"tap_hurry": {"solves": false, "progress": false,
					"feedback": "Nothing happens. The timer can't be rushed."},
			},
			"completion": {"facts": {}, "min_elapsed": 3.0},
			"time_threshold": 3.0,
			"solution": [],
			"hints": [
				"The countdown feels urgent. Is anything actually at stake?",
				"Read the timer's caption: what happens when it reaches zero?",
				"Do nothing. When the timer reaches zero, the door opens by itself.",
			],
		},
		# ---- Puzzle 04 — THE BOX ----------------------------------------
		{
			"id": 4, "key": "the_box", "title": "THE BOX",
			"objective": "Put the object in the box.",
			"assumption": "The object must move into the box.",
			"interactables": [
				{"id": "object", "label": "Object", "kind": "object", "anchored": true, "action": "move_object_to_box",
				 "position": Vector2(0.28, 0.55), "clue": "Pinned to the floor."},
				{"id": "box", "label": "Box", "kind": "box", "movable": true, "action": "move_box_to_object",
				 "position": Vector2(0.72, 0.55), "clue": "On casters.",
				 "clue_on": {"in_box": "Over the object."}},
			],
			"actions": {
				"move_object_to_box": {"solves": false, "progress": false,
					"feedback": "The object is pinned down. It won't budge."},
				"move_box_to_object": {"solves": true, "progress": true,
					"effects": {"in_box": true}, "feedback": "You roll the box over the object. It's in."},
			},
			"completion": {"facts": {"in_box": true}, "min_elapsed": 0.0},
			"solution": ["move_box_to_object"],
			"hints": [
				"You assume the object goes to the box.",
				"Which one can actually move? The object is pinned; the box is on casters.",
				"Move the box onto the object: tap the box.",
			],
		},
		# ---- Puzzle 05 — THE BUTTON -------------------------------------
		# The objective is literally true: pressing the button opens the door,
		# but only once it has power. The power lever is a full-size, labelled
		# control with a state caption (overlooked, never hidden). The button's
		# caption shows its power light from the start, and pressing it without
		# power says why it failed. No pixel hunting, no invisible interaction.
		{
			"id": 5, "key": "the_button", "title": "THE BUTTON",
			"objective": "Press the button to open the door.",
			"assumption": "The labelled button works on its own.",
			"interactables": [
				{"id": "button", "label": "OPEN", "kind": "button", "action": "press_button",
				 "position": Vector2(0.5, 0.25), "clue": "Power light: off.",
				 "clue_on": {"power": "Power light: on."}},
				{"id": "lever", "label": "Power lever", "kind": "lever", "action": "pull_lever",
				 "position": Vector2(0.72, 0.53), "clue": "Down: power off.",
				 "clue_on": {"power": "Up: power on."}},
				{"id": "door", "label": "Door", "kind": "door",
				 "position": Vector2(0.5, 0.8), "clue": "Closed.",
				 "clue_on": {"door_open": "Open."}},
			],
			"initial_facts": {"power": false},
			"actions": {
				"press_button": {"solves": true, "progress": true,
					"requires": {"power": true},
					"fail_feedback": "Click. Nothing. The power light is off.",
					"effects": {"door_open": true},
					"feedback": "The button lights up. The door slides open."},
				"pull_lever": {"solves": false, "progress": true,
					"requires": {"power": false},
					"fail_feedback": "The lever is already up.",
					"effects": {"power": true},
					"feedback": "Clunk. Power on. The OPEN button's light comes on."},
			},
			"completion": {"facts": {"door_open": true}, "min_elapsed": 0.0},
			"solution": ["pull_lever", "press_button"],
			"hints": [
				"The button isn't broken. Read its power light.",
				"The power light is off. Another control on screen is labelled 'Power'.",
				"Pull the power lever, then press OPEN.",
			],
		},
	]
