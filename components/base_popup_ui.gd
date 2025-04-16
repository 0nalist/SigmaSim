extends Control
class_name BasePopupUI

@export var default_window_size: Vector2 = Vector2(360, 280)
@export var unique_popup_key: String = ""
@export var allow_multiple: bool = false

@export var window_can_close: bool = true
@export var window_can_minimize: bool = true
@export var window_can_maximize: bool = true
