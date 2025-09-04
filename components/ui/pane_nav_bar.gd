extends PanelContainer
class_name PaneNavBar

signal tab_selected(tab_id: String)

var buttons: Dictionary = {}
var margin: MarginContainer
var box: BoxContainer

var _use_vertical: bool = false
var _root_control: Control
const SHRINK_THRESHOLD := 300.0
@export var use_vertical: bool = false:
	set(value):
			_use_vertical = value
			if is_inside_tree():
					_rebuild_box_container()
	get:
			return _use_vertical

func _ready() -> void:
                margin = MarginContainer.new()
                margin.add_theme_constant_override("margin_left", 10)
                margin.add_theme_constant_override("margin_top", 10)
                margin.add_theme_constant_override("margin_right", 10)
                margin.add_theme_constant_override("margin_bottom", 10)
                add_child(margin)
                _rebuild_box_container()

                _root_control = self
                while _root_control.get_parent() is Control:
                                _root_control = _root_control.get_parent()
                if _root_control:
                                _root_control.resized.connect(_on_root_resized)
                                _on_root_resized()

func _rebuild_box_container() -> void:
		if margin == null:
				return
		var old_buttons: Array[Button] = []
		if box:
				for child in box.get_children():
						box.remove_child(child)
						old_buttons.append(child)
				box.queue_free()
		if _use_vertical:
				box = VBoxContainer.new()
		else:
				box = HBoxContainer.new()
		margin.add_child(box)
		for btn in old_buttons:
				box.add_child(btn)

func add_nav_button(tab_id: String, text: String) -> void:
		if box == null:
				return
		var btn := Button.new()
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = text
		btn.pressed.connect(func(): _on_button_pressed(tab_id))
		box.add_child(btn)
		buttons[tab_id] = btn

func _on_button_pressed(tab_id: String) -> void:
		for id in buttons.keys():
				var btn: Button = buttons[id]
				btn.button_pressed = id == tab_id
		tab_selected.emit(tab_id)

func set_active(tab_id: String) -> void:
                if buttons.has(tab_id):
                                _on_button_pressed(tab_id)

func _on_root_resized() -> void:
                if _root_control == null:
                                return
                var size: Vector2 = _root_control.size
                if size.x < SHRINK_THRESHOLD or size.y < SHRINK_THRESHOLD:
                                var factor := clamp(min(size.x, size.y) / SHRINK_THRESHOLD, 0.1, 1.0)
                                scale = Vector2(factor, factor)
                else:
                                scale = Vector2.ONE
