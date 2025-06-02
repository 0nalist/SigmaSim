@tool

extends Panel
class_name UpgradeNodeEditor


@export var upgrade_resource: UpgradeResource  # UpgradeResource
@export var display_name: String = ""
@export var is_major: bool = false

func _ready():
	self.size = Vector2(80, 40)
	%Label.text = display_name if display_name != "" else (upgrade_resource.resource_name if upgrade_resource else "Unset")
	modulate = Color(1.2, 1.2, 1.6) if is_major else Color(1, 1, 1)
