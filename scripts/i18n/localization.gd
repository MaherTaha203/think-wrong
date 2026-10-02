extends Node
## Autoload: localization-ready string table. All user-facing strings go through
## t(); adding a language later is a table addition, no UI changes. English ships;
## Arabic prepared (RTL-aware) but not populated in the prototype.

var language := "en"

const STRINGS := {
	"en": {
		"app_title": "THINK WRONG",
		"tagline": "the obvious solution is usually wrong.",
		"play": "Play",
		"continue": "Continue",
		"levels": "Levels",
		"settings": "Settings",
		"back": "Back",
		"menu": "Menu",
		"pause": "Pause",
		"resume": "Resume",
		"restart": "Restart",
		"hint": "Hint",
		"next_hint": "Next hint",
		"show_solution": "Show solution",
		"solution": "Solution",
		"locked": "Locked",
		"objective": "Objective",
		"solved_title": "Solved",
		"aha": "You were thinking about it the wrong way.",
		"next": "Next",
		"replay": "Replay",
		"sound": "Sound",
		"haptics": "Haptics",
		"reduced_motion": "Reduced Motion",
		"high_contrast": "High Contrast",
		"reset_progress": "Reset Progress",
		"reset_confirm": "Reset all progress? This cannot be undone.",
		"cancel": "Cancel",
		"confirm": "Reset",
		"level": "Puzzle",
	},
	"ar": {},
}

func set_language(code: String) -> void:
	if STRINGS.has(code):
		language = code

func t(key: String) -> String:
	var table: Dictionary = STRINGS.get(language, {})
	if table.has(key):
		return table[key]
	return STRINGS["en"].get(key, key)

func is_rtl() -> bool:
	return language == "ar"
