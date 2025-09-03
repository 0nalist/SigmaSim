extends Node
# Autoload: TerminalManager

const TOGGLE_ACTION := "toggle_terminal"

func _ready() -> void:
        _ensure_toggle_action()

func _input(event: InputEvent) -> void:
        if GameManager.in_game and event.is_action_pressed(TOGGLE_ACTION):
                toggle()
                get_viewport().set_input_as_handled()

func open() -> void:
        if not GameManager.in_game:
                return
        var existing := WindowManager.find_window_by_app("Terminal")
        if existing:
                WindowManager.focus_window(existing)
                if existing.pane is Terminal:
                        (existing.pane as Terminal).open()
                return

	WindowManager.launch_app_by_name("Terminal")
	existing = WindowManager.find_window_by_app("Terminal")
	if existing and existing.pane is Terminal:
		(existing.pane as Terminal).open()

func close() -> void:
	var existing := WindowManager.find_window_by_app("Terminal")
	if existing:
		WindowManager.close_window(existing)

func toggle() -> void:
        if not GameManager.in_game:
                return
        var existing := WindowManager.find_window_by_app("Terminal")
        if existing:
                WindowManager.close_window(existing)
        else:
                open()

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

		var ev2 := InputEventKey.new()
		ev2.keycode = KEY_F1
		ev2.physical_keycode = KEY_F1
		InputMap.action_add_event(TOGGLE_ACTION, ev2)
