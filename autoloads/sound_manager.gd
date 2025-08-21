extends Node
## Autoload name SoundManager

# Enumerations for sound effects and music tracks
enum SFX {
	BUTTON_CLICK,
	ERROR,
}

enum Music {
	MAIN_THEME,
}

# Paths to audio resources. Replace with actual files as they are added.
const _SFX_PATHS := {
	SFX.BUTTON_CLICK: "res://assets/audio/sfx/button_click.ogg",
	SFX.ERROR: "res://assets/audio/sfx/error.ogg",
}

const _MUSIC_PATHS := {
	Music.MAIN_THEME: "res://assets/audio/music/main_theme.ogg",
}

var _music_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)

func play_sfx(sfx_name: SFX) -> void:
	var path: String = _SFX_PATHS.get(sfx_name, "")
	if path == "":
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.finished.connect(player.queue_free)
	player.play()

func play_music(track: Music) -> void:
	var path: String = _MUSIC_PATHS.get(track, "")
	if path == "":
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	if _music_player.playing:
		_music_player.stop()
