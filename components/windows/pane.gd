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


@export var request_windowless_mode: bool = false

@export var show_in_taskbar: bool = true
#@export var only_one_instance_allowed: bool = false

@export var allow_multiple: bool = false
@export var unique_popup_key: String = ""
@export var is_popup: bool = false
@export var persist_on_save: bool = true

@export var window_can_close: bool = true
@export var window_can_minimize: bool = true
@export var window_can_maximize: bool = true

@export var user_movable: bool = true
@export var user_resizable: bool = true
@export var stay_on_top: bool = false

@export var color1: Color = Color.WHITE
@export var color2: Color = Color.WHITE
@export var color3: Color = Color.WHITE
@export var color4: Color = Color.WHITE
@export var color5: Color = Color.WHITE
@export var color6: Color = Color.WHITE

@export var upgrade_pane: PackedScene # upgrade_pane_scene if I am using scenes. But are packed scenes best here?


#signal title_updated(title: String) #unused, for now

func _ready() -> void:
	#get_parent().get_parent().get_parent().window_can_close = window_can_close
	#window_icon_changed.emit(window_icon)
	var window = get_parent().get_parent().get_parent()
	window.call_deferred("set", "windowless_mode", request_windowless_mode)


func get_drag_handle() -> Control:
	var tab_bar = %TabBar.get_tab_bar() 
	tab_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	return tab_bar


func get_window_title() -> String:
	return window_title

func get_window_icon() -> Texture:
	return window_icon
