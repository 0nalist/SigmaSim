extends Node
# Autoload: TerminalManager

var terminal_scene: PackedScene
var terminal: Terminal

const TOGGLE_ACTION := "toggle_terminal"

func _ready() -> void:
        _ensure_toggle_action()

        terminal_scene = load("res://components/apps/terminal/terminal.tscn")
        terminal = terminal_scene.instantiate() as Terminal
        terminal.hide()

        # Defer adding to root to avoid "Parent node is busy setting up children"
        get_tree().root.call_deferred("add_child", terminal)

func _input(event: InputEvent) -> void:
        if event.is_action_pressed(TOGGLE_ACTION):
                if is_instance_valid(terminal):
                        terminal.toggle()
                        get_viewport().set_input_as_handled()

func open() -> void:
        if is_instance_valid(terminal):
                terminal.open()

func close() -> void:
        if is_instance_valid(terminal):
                terminal.close()

func toggle() -> void:
        if is_instance_valid(terminal):
                terminal.toggle()

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
