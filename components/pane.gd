extends Control
class_name Pane

@export var window_title: String = "Untitled"
@export var window_icon: Texture
@export var default_window_size: Vector2 = Vector2(640, 480)
@export_enum("left", "center", "right") var default_position: String = "center"

@export var show_in_taskbar: bool = true
@export var only_one_instance_allowed: bool = false

@export var allow_multiple: bool = false
@export var unique_popup_key: String = ""
@export var is_popup: bool = false

@export var window_can_close: bool = true
@export var window_can_minimize: bool = true
@export var window_can_maximize: bool = true

signal title_updated(title: String)

func _ready() -> void:
	get_parent().get_parent().get_parent().window_can_close = window_can_close


func get_window_title() -> String:
	return window_title
