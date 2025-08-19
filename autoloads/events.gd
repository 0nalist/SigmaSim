extends Node

signal desktop_background_toggled(name: String, visible: bool)

var desktop_backgrounds := {
	"BlueWarp": true,
	"ComicDots1": true,
	"ComicDots2": true,
}

func set_desktop_background_visible(name: String, visible: bool) -> void:
	desktop_backgrounds[name] = visible
	emit_signal("desktop_background_toggled", name, visible)

func is_desktop_background_visible(name: String) -> bool:
	return desktop_backgrounds.get(name, true)
