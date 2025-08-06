extends Pane
class_name UpgradeTreeUI

var selected_upgrade: Dictionary = {}
var hovered_upgrade: Dictionary = {}

@export var tree_title: String = "Upgrade Tree"
@export var upgrade_filter: String = ""  # e.g., "Workforce"
@export var upgrades: Array = []
@export var upgrade_card_scene: PackedScene

@onready var card_canvas = %CardCanvas
@onready var connector_overlay = %ConnectorOverlay
@onready var tooltip = %UpgradeTooltip
@onready var title_label = %TitleLabel  # (if you have one)

var card_dict: Dictionary = {}  # upgrade_id -> card
var last_hovered_card: Node = null
var last_selected_card: Node = null

func _ready():
	window_title = tree_title
	window_title_changed.emit(window_title)
	if has_node("TitleLabel"):
		title_label.text = tree_title
	layout_tree()

func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	var card_under_mouse = _get_upgrade_card_under_mouse(mouse_pos)

	# Hover logic
	if card_under_mouse != last_hovered_card:
		if last_hovered_card:
			last_hovered_card.set_hovered(false)
		last_hovered_card = card_under_mouse
		if card_under_mouse:
			card_under_mouse.set_hovered(true)

	_update_tooltip_display(card_under_mouse)

func _get_upgrade_card_under_mouse(mouse_pos: Vector2) -> Node:
	for card in card_dict.values():
		if card.get_global_rect().has_point(mouse_pos):
			return card
	return null

func _get_upgrade_list() -> Array:
	if upgrades.size() > 0:
		return upgrades
	elif upgrade_filter != "":
		return UpgradeManager.get_upgrades_for_system(upgrade_filter)
	else:
		push_warning("UpgradeTreeUI: No upgrades provided or filter set.")
		return []

func layout_tree():
	for child in card_canvas.get_children():
		child.queue_free()
	card_dict.clear()
	
	var upgrade_list = _get_upgrade_list()
	var layers = UpgradeManager.get_upgrade_layers(upgrade_list)

	const X_SPACING = 180
	const Y_SPACING = 120

	for layer_idx in layers.size():
		var layer = layers[layer_idx]
		var y = layer_idx * Y_SPACING
		var layer_width = (layer.size() - 1) * X_SPACING
		for i in layer.size():
			var upgrade = layer[i]
			var card = upgrade_card_scene.instantiate()
			card.set_upgrade(upgrade)
			var x = i * X_SPACING - layer_width / 2
			card.position = Vector2(x, y)
			card_canvas.add_child(card)
			card_dict[upgrade.get("id")] = card
			card.set_hovered(false)
			card.set_selected(false)
			card.hovered.connect(_on_card_hovered)
			card.unhovered.connect(_on_card_unhovered)
			card.clicked.connect(_on_card_clicked)

	# Now that all cards are placed, tell the overlay
	connector_overlay.set_cards(card_dict)
	connector_overlay.queue_redraw()


# Signal handlers (optional, for future, but not required with manual tracking)
func _on_card_hovered(upgrade, _global_pos):
	pass

func _on_card_unhovered():
	pass

func _on_card_clicked(upgrade, _global_pos):
	# Unselect last card if needed
	if last_selected_card:
		last_selected_card.set_selected(false)
	# Select new card
		var card = card_dict.get(upgrade.get("id"))
		if card:
			card.set_selected(true)
			last_selected_card = card
	selected_upgrade = upgrade
	tooltip.show_tooltip(upgrade)

func clear_upgrade_selection():
	if last_selected_card:
		last_selected_card.set_selected(false)
		last_selected_card = null
	selected_upgrade = {}
	hovered_upgrade = {}
	tooltip.hide_tooltip()

func _update_tooltip_display(card_under_mouse: Node) -> void:
	if card_under_mouse and card_under_mouse.upgrade:
		hovered_upgrade = card_under_mouse.upgrade
		tooltip.show_tooltip(hovered_upgrade)
	elif selected_upgrade:
		tooltip.show_tooltip(selected_upgrade)
	else:
		tooltip.hide_tooltip()
