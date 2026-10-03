extends Control
## Root boot node (composition root): background, safe-area container, screen +
## overlay hosts. Pushes settings into Style, keeps the background in sync with
## the high-contrast setting, routes to the first screen and persists on
## lifecycle interruptions.

var _safe: MarginContainer
var _bg: ColorRect

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Style.apply_settings(SaveManager.settings())
	Localization.set_language(str(SaveManager.settings().get("language", "en")))
	if Localization.is_rtl():
		layout_direction = Control.LAYOUT_DIRECTION_RTL

	_bg = ColorRect.new()
	_bg.color = Style.bg()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	_apply_safe_area()

	var screen_host := Control.new()
	screen_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe.add_child(screen_host)

	# Overlays sit above screens and outside the safe-area margins (full screen).
	var overlay_host := Control.new()
	overlay_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay_host)

	SaveManager.settings_changed.connect(_on_settings_changed)
	ScreenManager.set_hosts(screen_host, overlay_host)
	ScreenManager.goto("menu")

	get_viewport().size_changed.connect(_apply_safe_area)

func _on_settings_changed(_key: String) -> void:
	Style.apply_settings(SaveManager.settings())
	_bg.color = Style.bg()

func _apply_safe_area() -> void:
	if _safe == null:
		return
	var m := Style.safe_margins(DisplayServer.get_display_safe_area(), DisplayServer.window_get_size(),
		get_viewport().get_visible_rect().size, Style.GAP_S)
	for side in ["left", "top", "right", "bottom"]:
		_safe.add_theme_constant_override("margin_" + side, int(m[side]))

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			SaveManager.save_game()
