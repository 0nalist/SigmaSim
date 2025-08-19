extends Control

@export var background_name: String

func _ready() -> void:
	visible = Events.is_desktop_background_visible(background_name)
	Events.connect("desktop_background_toggled", Callable(self, "_on_desktop_background_toggled"))

func _on_desktop_background_toggled(name: String, visible_state: bool) -> void:
	if name == background_name:
		visible = visible_state
