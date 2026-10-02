extends Node
## Autoload: version constants for THINK WRONG.
##
## Four independent versions are tracked so the app, save format and content can
## evolve separately. Mirrored by tests/gdscript/run_tests.gd.

const APP_VERSION := "0.1.0"          # prototype
const CONTENT_VERSION := "1"          # puzzle content revision
const SAVE_DATA_VERSION := 1          # drives save migration

func build_info() -> Dictionary:
	return {
		"app_version": APP_VERSION,
		"content_version": CONTENT_VERSION,
		"save_data_version": SAVE_DATA_VERSION,
		"godot_version": Engine.get_version_info().get("string", "unknown"),
	}
