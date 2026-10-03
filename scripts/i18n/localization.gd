extends Node
## Autoload: localization-ready string table. All user-facing strings go through
## t(); adding a language later is a table addition, no UI changes. English ships;
## Arabic is prepared (is_rtl() flips the root layout direction in main.gd) but
## not populated in the prototype, so RTL rendering is untested. Puzzle content
## (objectives, captions, feedback, hints) still lives in scripts/data/puzzles.gd
## in English; moving it behind keys is a Phase 2 localization task.

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
		"main_menu": "Main menu",
		"pause": "Pause",
		"resume": "Resume",
		"restart": "Restart",
		"hint": "Hint",
		"hint_intro": "Hints start gently. The last one shows the solution.",
		"show_hint": "Show a hint",
		"next_hint": "Next hint",
		"show_solution": "Show solution",
		"no_more_hints": "No more hints",
		"solution": "Solution",
		"locked": "Locked",
		"not_solved": "Not solved",
		"solved": "Solved",
		"puzzle_unavailable": "Puzzle unavailable",
		"objective": "Objective",
		"solved_title": "Solved",
		"aha": "You were thinking about it the wrong way.",
		"next": "Next",
		"replay": "Replay",
		"on": "On",
		"off": "Off",
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
