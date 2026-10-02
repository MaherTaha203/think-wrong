extends Node
## Autoload: light haptic feedback, independently disableable. Mobile only; a
## no-op elsewhere. Never required to understand a puzzle.

func light() -> void:
	_buzz(18)

func success() -> void:
	_buzz(40)

func warning() -> void:
	_buzz(28)

func _buzz(ms: int) -> void:
	if not bool(SaveManager.settings().get("haptics", true)):
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
