extends PanelContainer
class_name PaneNavBar

@export var base_min_width: float = 140.0
@export var width_ratio: float = 0.25

@onready var _margin: MarginContainer = $MarginContainer
@onready var _vbox: VBoxContainer = $MarginContainer/VBox

func _ready() -> void:
    var win := get_window()
    if win:
        win.size_changed.connect(_update_size)
        _update_size()

func _update_size() -> void:
    var win := get_window()
    if win:
        var window_width: float = win.size.x
        var target: float = min(base_min_width, window_width * width_ratio)
        custom_minimum_size.x = target
