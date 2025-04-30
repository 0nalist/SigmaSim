extends Control
class_name Pane

signal window_title_changed(new_title: String)
signal window_icon_changed(new_icon)

@export var window_title: String = "Window" :
	set(value):
		window_title = value
		window_title_changed.emit(value)
@export var window_icon: Texture :
	set(value):
		window_icon = value
		window_icon_changed.emit(value)
@export var default_window_size: Vector2 = Vector2(400, 480)
@export_enum("left", "center", "right") var default_position: String = "center"

@export var show_in_taskbar: bool = true
#@export var only_one_instance_allowed: bool = false

@export var allow_multiple: bool = false
@export var unique_popup_key: String = ""
@export var is_popup: bool = false

@export var window_can_close: bool = true
@export var window_can_minimize: bool = true
@export var window_can_maximize: bool = true

@export var user_movable: bool = true
@export var user_resizable: bool = true
@export var stay_on_top: bool = false

@export var upgrade_pane: PackedScene # upgrade_pane_scene if I am using scenes. But are packed scenes best here?


signal title_updated(title: String)

func _ready() -> void:
	#get_parent().get_parent().get_parent().window_can_close = window_can_close
	#window_icon_changed.emit(window_icon)
	pass


func get_window_title() -> String:
	return window_title

func get_window_icon() -> Texture:
	return window_icon
