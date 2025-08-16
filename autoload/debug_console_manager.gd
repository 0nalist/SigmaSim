extends Node
# Autoload: DebugConsoleManager

var console_scene: PackedScene
var console: DebugConsole

const TOGGLE_ACTION := "toggle_debug_console"

func _ready() -> void:
	_ensure_toggle_action()

	console_scene = load("res://components/debug/debug_console.tscn")
	console = console_scene.instantiate() as DebugConsole
	console.hide()

	# Defer adding to root to avoid "Parent node is busy setting up children"
	get_tree().root.call_deferred("add_child", console)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		if is_instance_valid(console):
			console.toggle()
			get_viewport().set_input_as_handled()

func open() -> void:
	if is_instance_valid(console):
		console.open()

func close() -> void:
	if is_instance_valid(console):
		console.close()

func toggle() -> void:
	if is_instance_valid(console):
		console.toggle()

func _ensure_toggle_action() -> void:
	if not InputMap.has_action(TOGGLE_ACTION):
		InputMap.add_action(TOGGLE_ACTION)

	var events := InputMap.action_get_events(TOGGLE_ACTION)
	if events.size() == 0:
		var ev := InputEventKey.new()
		var k: int = KEY_QUOTELEFT  # backtick (`) in Godot 4
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = false
		InputMap.action_add_event(TOGGLE_ACTION, ev)

		# Optional: add F1 as a secondary toggle
		var ev2 := InputEventKey.new()
		ev2.keycode = KEY_F1
		ev2.physical_keycode = KEY_F1
		InputMap.action_add_event(TOGGLE_ACTION, ev2)
