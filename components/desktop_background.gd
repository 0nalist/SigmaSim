extends Control

@export var background_name: String

func _ready() -> void:
	visible = Events.is_desktop_background_visible(background_name)
	Events.connect("desktop_background_toggled", Callable(self, "_on_desktop_background_toggled"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("clicked but not validated")
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			print("clicked desktop background")
			var actions: Array = []
			var action_new: ContextAction = ContextAction.new()
			action_new.id = 0
			action_new.label = "New Folder"
			action_new.method = "_ctx_new_folder"
			action_new.args = [mb.global_position]
			actions.append(action_new)
			var action_bg: ContextAction = ContextAction.new()
			action_bg.id = 1
			action_bg.label = "Change Desktop Background"
			action_bg.method = "_ctx_change_background"
			actions.append(action_bg)
			ContextMenuManager.open_for(self, mb.global_position, actions)
			accept_event()

func _ctx_new_folder(pos: Vector2) -> void:
		var base_name := "Unnamed Folder"
		var name := base_name
		var counter := 1
		while true:
				var exists := false
				for item in DesktopLayoutManager.items.values():
						if item.get("title", "") == name:
								exists = true
								break
				if not exists:
						break
				counter += 1
				name = "%s %d" % [base_name, counter]
		DesktopLayoutManager.create_folder(name, "res://assets/logos/folder.png", pos)

func _ctx_change_background() -> void:
		var scene: PackedScene = WindowManager.app_registry.get("Settings")
		if scene:
				var pane: Pane = scene.instantiate()
				WindowManager.launch_pane_instance(pane, "Backgrounds")

func _on_desktop_background_toggled(name: String, visible_state: bool) -> void:
	if name == background_name:
		visible = visible_state
