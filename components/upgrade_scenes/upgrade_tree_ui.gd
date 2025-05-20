extends Pane
class_name UpgradeTreeUI

@export var tree_title: String = "Upgrade Tree"
@export var upgrade_filter: String = ""  # e.g., "Workforce"
@export var upgrades: Array[UpgradeResource]
@export var upgrade_card_scene: PackedScene

@onready var card_canvas = %CardCanvas
@onready var connector_overlay = %ConnectorOverlay
@onready var tooltip = %UpgradeTooltip
@onready var title_label = %TitleLabel  # (if you have one)

var card_dict: Dictionary = {}  # upgrade_id -> card

func _ready():
	window_title = tree_title
	window_title_changed.emit(window_title)
	if has_node("TitleLabel"):
		title_label.text = tree_title
	layout_tree()

func _get_upgrade_list() -> Array:
	if upgrades.size() > 0:
		return upgrades
	elif upgrade_filter != "":
		return UpgradeManager.get_upgrades_by_source(upgrade_filter)
	else:
		push_warning("UpgradeTreeUI: No upgrades provided or filter set.")
		return []

func layout_tree():
	for child in card_canvas.get_children():
		child.queue_free()
	card_dict.clear()
	var upgrade_list = _get_upgrade_list()
	var layers = UpgradeManager.get_upgrade_layers(upgrade_list)

	const X_SPACING = 300
	const Y_SPACING = 200

	for layer_idx in layers.size():
		var layer = layers[layer_idx]
		var y = layer_idx * Y_SPACING
		var layer_width = (layer.size() - 1) * X_SPACING
		for i in layer.size():
			var upgrade = layer[i]
			var card = upgrade_card_scene.instantiate()
			card.set_upgrade(upgrade)
			# Center each layer horizontally
			var x = i * X_SPACING - layer_width / 2
			card.position = Vector2(x, y)
			card_canvas.add_child(card)
			card_dict[upgrade.upgrade_id] = card
			card.hovered.connect(_on_card_hovered)
			card.unhovered.connect(_on_card_unhovered)
			card.clicked.connect(_on_card_clicked)

	# Draw connector lines
	connector_overlay.set_cards(card_dict)
	connector_overlay.queue_redraw()

func _on_card_hovered(upgrade, global_pos):
	tooltip.show_upgrade(upgrade, global_pos)

func _on_card_unhovered():
	tooltip.hide()

func _on_card_clicked(upgrade, global_pos):
	tooltip.show_upgrade(upgrade, global_pos, true)
