extends PanelContainer

signal hovered(upgrade: UpgradeResource, global_pos: Vector2)
signal unhovered()
signal clicked(upgrade: UpgradeResource, global_pos: Vector2)

@onready var name_label = %NameLabel
@onready var icon = %Icon  # Remove if you don't have an icon

var upgrade: UpgradeResource = null
var upgrade_queued: bool = false

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

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("clicked", upgrade, get_global_position())
	if event is InputEventMouseMotion:
		emit_signal("hovered", upgrade, get_global_position())

func _on_mouse_entered():
	emit_signal("hovered", upgrade, get_global_position())

func _on_mouse_exited():
	emit_signal("unhovered")


func _on_clicked(upgrade: UpgradeResource, global_pos: Vector2) -> void:
	pass # Replace with function body.
