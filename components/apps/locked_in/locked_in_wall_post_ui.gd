class_name LockedInWallPostUI
extends PanelContainer

@onready var label: Label = %Label

func set_text(text: String) -> void:
	label.text = text
