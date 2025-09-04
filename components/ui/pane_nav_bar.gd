extends PanelContainer
class_name PaneNavBar

@export var full_width: float = 140.0
@export var width_ratio: float = 0.25

@onready var margin_container: MarginContainer = %MarginContainer
@onready var tab_bar: VBoxContainer = %TabBar

var tabs: Dictionary = {}
var _button_group := ButtonGroup.new()
var _root_control: Control

func _ready() -> void:
	custom_minimum_size.x = full_width
	_root_control = self
	while _root_control.get_parent() is Control:
		_root_control = _root_control.get_parent()
	if _root_control:
		_root_control.resized.connect(_on_root_resized)
		_on_root_resized()

func _on_root_resized() -> void:
	var root_width: float = _root_control.size.x
	custom_minimum_size.x = min(full_width, root_width * width_ratio)

func add_tab(button: Button, id: StringName) -> void:
        tabs[id] = button
        button.toggle_mode = true
        button.button_group = _button_group
