extends Control

@export var background_name: String

func _ready() -> void:
	visible = Events.is_desktop_background_visible(background_name)
	Events.connect("desktop_background_toggled", Callable(self, "_on_desktop_background_toggled"))
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var actions: Array = []
			var action: ContextAction = ContextAction.new()
			action.id = 0
			action.label = "New Folder"
			action.method = "_ctx_new_folder"
			action.args = [mb.global_position]
			actions.append(action)
			ContextMenuManager.open_for(self, mb.global_position, actions)

func _ctx_new_folder(pos: Vector2) -> void:
	DesktopLayoutManager.create_folder("unnamed folder", "res://assets/logos/folder.png", pos)

func _on_desktop_background_toggled(name: String, visible_state: bool) -> void:
	if name == background_name:
		visible = visible_state
