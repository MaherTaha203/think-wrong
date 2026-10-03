extends Node
## Autoload: version constants for THINK WRONG.
##
## Four independent versions are tracked so the app, save format and content can
## evolve separately. Mirrored by tests/gdscript/run_tests.gd.

const APP_VERSION := "0.1.0"          # prototype
const CONTENT_VERSION := "1"          # puzzle content revision
const SAVE_DATA_VERSION := 1          # drives save migration

## Canonical reverse-DNS application identifier — the single source of truth for
## export presets (Android/iOS) when they are created during Phase 2 release
## work. It MUST be a valid Android application id (Java package name): each
## dot-separated segment starts with a letter and contains only [A-Za-z0-9_] —
## no hyphens. iOS bundle ids are a superset, so the same value is valid there.
## Enforced by tests/gdscript/run_tests.gd (_test_app_id).
const APPLICATION_ID := "com.mahertaha.thinkwrong"

func build_info() -> Dictionary:
	return {
		"app_version": APP_VERSION,
		"content_version": CONTENT_VERSION,
		"save_data_version": SAVE_DATA_VERSION,
		"application_id": APPLICATION_ID,
		"godot_version": Engine.get_version_info().get("string", "unknown"),
	}
