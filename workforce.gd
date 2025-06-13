extends Pane

@onready var tab_bar = %TabBar

func get_drag_handle() -> Control:
	return tab_bar
