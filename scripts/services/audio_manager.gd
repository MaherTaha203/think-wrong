extends Node
## Autoload: minimal SFX (interaction, success, invalid, navigation). Respects the
## sound setting; never crashes when an asset is missing. SFX are original,
## procedurally generated (tools/gen_audio.py). Audio is supplemental — no puzzle
## requires sound to be solved.

const SFX := {
	"tap": "res://assets/audio/tap.wav",
	"success": "res://assets/audio/success.wav",
	"invalid": "res://assets/audio/invalid.wav",
	"nav": "res://assets/audio/nav.wav",
}

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next := 0
const POOL := 5

func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for key in SFX.keys():
		if ResourceLoader.exists(SFX[key]):
			_streams[key] = load(SFX[key])

func play(name: String) -> void:
	if not bool(SaveManager.settings().get("sound", true)):
		return
	if not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.play()
