# base_app_ui.gd
extends Control
class_name BaseAppUI

@export var app_title: String = "Untitled App"
@export var app_icon: Texture

signal title_updated(title: String)

@export var default_window_size: Vector2 = Vector2(640, 480)
@export_enum("left", "center", "right") var default_position: String = "center"

@export var show_in_taskbar: bool = true
@export var only_one_instance_allowed: bool = false

var window_can_close = true
var window_can_minimize = true
var window_can_maximize = true
