extends RefCounted
class_name PuzzleController
## Generic, deterministic puzzle engine. Holds a PuzzleDefinition, the mutable
## PuzzleState, a HintController and counters. No UI, no randomness, no real time
## (time is advanced explicitly), so every puzzle is headless-testable.
##
## The controller is the single owner of completion: `completed` fires exactly
## once per run (from a solving action or from the clock), and once a run is
## complete further input is ignored until reset().

enum Result { OK, OK_COMPLETED, NO_PROGRESS, INVALID }

const DEFAULT_FAIL := "Nothing happens."

var definition: PuzzleDefinition
var state: PuzzleState
var hints: HintController
var wrong_attempts: int = 0
var _done := false

signal completed()
signal feedback(message: String, kind: String)  # kind: "info"/"success"/"invalid"

func _init(def: PuzzleDefinition) -> void:
	definition = def
	reset()

func reset() -> void:
	state = PuzzleState.new(definition.initial_facts)
	hints = HintController.new(definition.hints)
	wrong_attempts = 0
	_done = false

## Advance the injected clock; completes a time-gated puzzle when it is due.
func advance_time(dt: float) -> void:
	if _done:
		return
	state.advance_time(dt)
	if float(definition.completion.get("min_elapsed", 0.0)) > 0.0 and is_complete():
		_finish()

func is_finished() -> bool:
	return _done

func is_complete() -> bool:
	var comp: Dictionary = definition.completion
	if state.elapsed < float(comp.get("min_elapsed", 0.0)):
		return false
	var req: Dictionary = comp.get("facts", {})
	for k in req.keys():
		if state.get_fact(k) != req[k]:
			return false
	# A puzzle with no required facts and no min_elapsed would be trivially
	# complete; guard against that (every puzzle needs a real objective).
	if req.is_empty() and float(comp.get("min_elapsed", 0.0)) <= 0.0:
		return false
	return true

## Attempt an action. Returns a Result. Invalid/no-progress attempts never change
## solving state and increment wrong_attempts (so "invalid interaction" is
## observable and tested); they never crash. Input after completion is ignored.
func attempt(action_id: String) -> int:
	if _done:
		return Result.NO_PROGRESS
	if not definition.actions.has(action_id):
		wrong_attempts += 1
		feedback.emit(DEFAULT_FAIL, "invalid")
		return Result.INVALID

	var a: Dictionary = definition.actions[action_id]

	# Preconditions.
	var requires: Dictionary = a.get("requires", {})
	for k in requires.keys():
		if state.get_fact(k) != requires[k]:
			wrong_attempts += 1
			feedback.emit(str(a.get("fail_feedback", DEFAULT_FAIL)), "invalid")
			return Result.INVALID

	# Apply effects.
	var effects: Dictionary = a.get("effects", {})
	for k in effects.keys():
		state.set_fact(k, effects[k])

	var msg := str(a.get("feedback", ""))
	if bool(a.get("solves", false)) and is_complete():
		if msg != "":
			feedback.emit(msg, "success")
		_finish()
		return Result.OK_COMPLETED

	if bool(a.get("progress", false)):
		if msg != "":
			feedback.emit(msg, "info")
		return Result.OK

	# Non-solving, non-progressing action (a fair red herring).
	wrong_attempts += 1
	if msg != "":
		feedback.emit(msg, "invalid")
	return Result.NO_PROGRESS

func _finish() -> void:
	_done = true
	completed.emit()

# --- hint passthrough -----------------------------------------------------
func reveal_hint() -> String:
	return hints.reveal_next()

func hints_used() -> int:
	return hints.used_count()
