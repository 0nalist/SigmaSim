extends Node

var login_scene := preload("res://components/ui/log_in_ui.tscn")
var desktop_scene := preload("res://components/desktop_env.tscn")
var current_screen: Node

func _ready() -> void:
	show_login_ui()

func show_login_ui() -> void:
	_switch_screen(login_scene.instantiate())
	GameManager.in_game = false

func show_desktop_env(slot_id: int = SaveManager.current_slot_id) -> void:
	SaveManager.current_slot_id = slot_id
	_switch_screen(desktop_scene.instantiate())
	GameManager.in_game = true

func _switch_screen(screen: Node) -> void:
	if current_screen and is_instance_valid(current_screen):
		current_screen.queue_free()
	current_screen = screen
	add_child(current_screen)
