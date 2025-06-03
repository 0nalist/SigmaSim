extends PanelContainer

signal hovered(upgrade: UpgradeResource, global_pos: Vector2)
signal unhovered()
signal clicked(upgrade: UpgradeResource, global_pos: Vector2)

@onready var name_label = %NameLabel
@onready var icon = %Icon  # Remove if you don't have an icon

var upgrade: UpgradeResource = null
var upgrade_queued: bool = false

var is_hovered := false
var is_selected := false

func set_upgrade(upg: UpgradeResource):
	upgrade = upg
	upgrade_queued = true
	if is_inside_tree():
		_refresh_upgrade()

func _ready():
	if upgrade_queued:
		_refresh_upgrade()

func _refresh_upgrade():
	if not is_instance_valid(upgrade):
		return
	if name_label:
		name_label.text = upgrade.upgrade_name
	if icon and upgrade.has_meta("icon") and upgrade.icon:
		icon.texture = upgrade.icon
	var can_purchase = UpgradeManager.can_purchase(upgrade.upgrade_id)
	modulate = Color(1, 1, 1) if can_purchase else Color(0.6, 0.6, 0.6)

func set_hovered(value: bool):
	is_hovered = value
	_update_modulate()

func set_selected(value: bool):
	is_selected = value
	_update_modulate()

func _update_modulate():
	# Priority: Selected > Hovered > Default
	if is_selected:
		# Example: green tint for selected
		modulate = Color(0.7, 1.1, 0.7, 1)
	elif is_hovered:
		# Example: blue tint for hovered
		modulate = Color(0.7, 0.7, 1.2, 1)
		print("hovered mod")
	else:
		# Default: white or gray for unpurchasable
		var can_purchase = UpgradeManager.can_purchase(upgrade.upgrade_id)
		modulate = Color(1, 1, 1, 1) if can_purchase else Color(0.6, 0.6, 0.6, 1)


'''
func _on_mouse_entered():
	emit_signal("hovered", upgrade, get_global_position())
	print("mouse enterd")

func _on_mouse_exited():
	emit_signal("unhovered")
	print("mouse exited")
'''
func _on_clicked(upgrade: UpgradeResource, global_pos: Vector2) -> void:
	print("empty click function")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("clicked", upgrade, get_global_position())
		print("mouse clicked")
	if event is InputEventMouseMotion:
		emit_signal("hovered", upgrade, get_global_position())
