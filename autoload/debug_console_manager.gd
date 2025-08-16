extends Node
class_name DebugConsoleManager

var console_scene: PackedScene
var console: DebugConsole

const TOGGLE_ACTION := "toggle_debug_console"

func _ready() -> void:
    # Ensure input action exists for toggling
    _ensure_toggle_action()

    console_scene = load("res://components/debug/debug_console.tscn")
    console = console_scene.instantiate() as DebugConsole
    get_tree().root.add_child(console)
    console.hide()

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
    # Bind the backquote key if no events are assigned
    var events := InputMap.action_get_events(TOGGLE_ACTION)
    if events.size() == 0:
        var ev := InputEventKey.new()
        # Backquote / tilde key (US layout)
        ev.physical_keycode = KEY_GRAVE
        ev.pressed = false
        InputMap.action_add_event(TOGGLE_ACTION, ev)
