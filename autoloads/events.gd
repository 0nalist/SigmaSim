extends Node

signal desktop_background_toggled(name: String, visible: bool)
signal upgrade_purchased(id: String, level: int)

var desktop_backgrounds: Dictionary = {
		"BlueWarp": true,
		"ComicDots1": false,
		"ComicDots2": false,
		"Waves": false,
		"Electric": false,
		"Background": false,
		"FlatColor": false,
}

func set_desktop_background_visible(name: String, visible: bool) -> void:
	desktop_backgrounds[name] = visible
	emit_signal("desktop_background_toggled", name, visible)

func is_desktop_background_visible(name: String) -> bool:
	return desktop_backgrounds.get(name, true)

func register_upgrade_signals(ids: Array) -> void:
	for id: String in ids:
		var signal_name: String = "%s_purchased" % id
		if not has_signal(signal_name):
			add_user_signal(signal_name, [{"name": "level", "type": TYPE_INT}])

func emit_upgrade_purchased(id: String, level: int) -> void:
	upgrade_purchased.emit(id, level)
	var signal_name: String = "%s_purchased" % id
	if has_signal(signal_name):
		emit_signal(signal_name, level)
