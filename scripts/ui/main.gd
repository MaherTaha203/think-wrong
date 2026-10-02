extends Control
## Root boot node: background, safe-area container, screen + overlay hosts.
## Routes to the first screen and persists on lifecycle interruptions.

var _safe: MarginContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Style.bg()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_safe)
	_apply_safe_area()

	var screen_host := Control.new()
	screen_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_safe.add_child(screen_host)

	# Overlays sit above screens and outside the safe-area margins (full screen).
	var overlay_host := Control.new()
	overlay_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay_host)

	Localization.set_language(str(SaveManager.settings().get("language", "en")))
	ScreenManager.set_hosts(screen_host, overlay_host)
	ScreenManager.goto("menu")

	get_viewport().size_changed.connect(_apply_safe_area)

func _apply_safe_area() -> void:
	if _safe == null:
		return
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	_safe.add_theme_constant_override("margin_left", maxi(safe.position.x, Style.GAP_S))
	_safe.add_theme_constant_override("margin_top", maxi(safe.position.y, Style.GAP_S))
	_safe.add_theme_constant_override("margin_right", maxi(win.x - (safe.position.x + safe.size.x), Style.GAP_S))
	_safe.add_theme_constant_override("margin_bottom", maxi(win.y - (safe.position.y + safe.size.y), Style.GAP_S))

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			SaveManager.save_game()
