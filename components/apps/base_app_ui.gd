# base_app_ui.gd
extends Control
class_name BaseAppUI

@export var app_title: String = "Untitled App"
@export var app_icon: Texture
signal title_updated(title: String)
@export var default_window_size: Vector2 = Vector2(640, 480)
