extends Node

var cursor_layer: CanvasLayer
var cursor: TextureRect

const DEFAULT_CURSOR := preload("res://assets/cursors/cursor_default.png")
const PICKAXE_CLICK_CURSOR = preload("res://assets/cursors/pickaxe2.png")
const PICKAXE_CURSOR = preload("res://assets/cursors/pickaxe.png")


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Defer the whole init step until the scene is safe to modify
	call_deferred("_initialize_cursor_scene")

func _initialize_cursor_scene():
	cursor_layer = preload("res://components/ui/fake_cursor.tscn").instantiate()
	cursor_layer.name = "FakeCursorLayer"
	get_tree().get_root().add_child(cursor_layer)

	cursor = cursor_layer.get_node("FakeCursor")
	set_process(true)

func _process(_delta):
	if is_instance_valid(cursor):
		cursor.position = get_viewport().get_mouse_position()

func warp_cursor(pos: Vector2):
	if is_instance_valid(cursor):
		cursor.position = pos
		Input.warp_mouse(pos)

## Cursor setters

func set_cursor(tex: Texture):
	if is_instance_valid(cursor):
		cursor.texture = tex
		
		

func set_default_cursor():
	set_cursor(DEFAULT_CURSOR)

func set_pickaxe_cursor():
	set_cursor(PICKAXE_CURSOR)

func set_pickaxe_click_cursor():
	set_cursor(PICKAXE_CLICK_CURSOR)
