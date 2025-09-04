extends Node

var cursor_layer: CanvasLayer
var cursor: TextureRect

const DEFAULT_CURSOR := preload("res://assets/cursors/cursor_default.png")
const PICKAXE_CLICK_CURSOR = preload("res://assets/cursors/pickaxe2.png")
const PICKAXE_CURSOR = preload("res://assets/cursors/pickaxe.png")
const SMALL_CURSOR := preload("res://assets/cursors/cursor_smaller.png")

var cursor_offset := Vector2.ZERO
var enabled := false # Track toggle state
var current_cursor: Texture = DEFAULT_CURSOR

func _ready():
	call_deferred("_initialize_cursor_scene")

func _initialize_cursor_scene():
	cursor_layer = preload("res://components/ui/fake_cursor.tscn").instantiate()
	cursor_layer.name = "FakeCursorLayer"
	get_tree().get_root().add_child(cursor_layer)
	cursor = cursor_layer.get_node("FakeCursor")
	set_process(true)
	#set_enabled(true) # Start enabled

func set_enabled(value: bool):
	enabled = value
	if enabled:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		if is_instance_valid(cursor_layer):
			cursor_layer.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if is_instance_valid(cursor_layer):
			cursor_layer.visible = false

func toggle():
	set_enabled(!enabled)

func _process(_delta):
        if enabled and is_instance_valid(cursor):
                cursor.position = get_viewport().get_mouse_position() + cursor_offset

func _input(event):
        if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
                if current_cursor == DEFAULT_CURSOR and event.pressed:
                        set_cursor(SMALL_CURSOR)
                elif current_cursor == SMALL_CURSOR and not event.pressed:
                        set_cursor(DEFAULT_CURSOR)

func warp_cursor(pos: Vector2):
	if is_instance_valid(cursor):
		cursor.position = pos
		Input.warp_mouse(pos)

## Cursor setters

func set_cursor(tex: Texture, offset := Vector2.ZERO):
        if is_instance_valid(cursor):
                cursor.texture = tex
                cursor_offset = offset
        current_cursor = tex

func set_default_cursor():
	set_cursor(DEFAULT_CURSOR, Vector2.ZERO)

func set_pickaxe_cursor():
	set_cursor(PICKAXE_CURSOR, Vector2(-8, -2))

func set_pickaxe_click_cursor():
	set_cursor(PICKAXE_CLICK_CURSOR, Vector2(-6, -3))
