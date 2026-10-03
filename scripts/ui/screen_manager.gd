extends Node
## Autoload: screen navigation + overlays.
##
## Full screens replace one another (one alive at a time). Overlays (Pause, Hint,
## confirmations) are drawn on top of the current screen without destroying it.
## Transitions respect the reduced-motion setting. The incoming screen is on top
## and stops pointer input, so the outgoing one cannot be tapped while it fades.

const SCREENS := {
	"menu": "res://scenes/MainMenu.tscn",
	"levels": "res://scenes/LevelSelect.tscn",
	"puzzle": "res://scenes/Puzzle.tscn",
	"complete": "res://scenes/PuzzleComplete.tscn",
	"settings": "res://scenes/Settings.tscn",
}

var _host: Control = null
var _overlay_host: Control = null
var _current: Control = null
var _overlay: Control = null

func set_hosts(screen_host: Control, overlay_host: Control) -> void:
	_host = screen_host
	_overlay_host = overlay_host

func current_screen() -> Control:
	return _current if _current != null and is_instance_valid(_current) else null

func current_overlay() -> Control:
	return _overlay if has_overlay() else null

func goto(screen_name: String) -> void:
	if _host == null or not SCREENS.has(screen_name):
		push_error("ScreenManager: bad screen '%s'" % screen_name)
		return
	close_overlay()
	var packed: PackedScene = load(SCREENS[screen_name])
	if packed == null:
		push_error("ScreenManager: failed to load %s" % SCREENS[screen_name])
		return
	var inst := packed.instantiate() as Control
	inst.set_anchors_preset(Control.PRESET_FULL_RECT)
	inst.mouse_filter = Control.MOUSE_FILTER_STOP
	_host.add_child(inst)
	var old := _current
	_current = inst
	if Style.reduced_motion():
		if old != null and is_instance_valid(old):
			old.queue_free()
		return
	inst.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(inst, "modulate:a", 1.0, Style.T_MED)
	if old != null and is_instance_valid(old):
		tw.parallel().tween_property(old, "modulate:a", 0.0, Style.T_FAST)
		tw.tween_callback(old.queue_free)

## Show a Control instance as a modal overlay (built by the caller).
func show_overlay(node: Control) -> void:
	close_overlay()
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_host.add_child(node)
	_overlay = node

func close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null

func has_overlay() -> bool:
	return _overlay != null and is_instance_valid(_overlay)
