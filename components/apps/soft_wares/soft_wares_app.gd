extends Pane
class_name SoftWaresApp

const SOFTWARE_ITEM_SCENE: PackedScene = preload("res://components/apps/soft_wares/soft_ware_item.tscn")

var soft_wares_registry: Dictionary = {
		"minerr": {
				"title": "Minerr",
				"description": "Mine and trade cryptocurrencies.",
				"icon": preload("res://assets/cursors/pickaxe.png"),
				"cost": 100
		},
		"brokerage": {
				"title": "BrokeRage",
				"description": "Buy and sell stocks in a chaotic market.",
				"icon": preload("res://assets/logos/brokerage.png"),
				"cost": 250
		},
		"fumble": {
				"title": "Fumble",
				"description": "Date, swipe, and battle for love.",
				"icon": preload("res://assets/logos/fumble.png"),
				"cost": 300
		},
		"earlybird": {
				"title": "EarlyBird",
				"description": "Rise early and get that worm.",
				"icon": preload("res://assets/early_bird/worm1.png"),
				"cost": 150
		}
}

@onready var items_container: VBoxContainer = %ItemsContainer

func _ready() -> void:
	_populate_items()

func _populate_items() -> void:
		for app_id in soft_wares_registry.keys():
				var data: Dictionary = soft_wares_registry[app_id]
				var item: SoftWareItem = SOFTWARE_ITEM_SCENE.instantiate() as SoftWareItem
				item.app_icon = data["icon"]
				item.app_title = data["title"]
				item.app_description = data["description"]
				item.app_cost = int(data["cost"])
				item.app_id = app_id
				item.upgrade_scene = _get_upgrade_scene(app_id)
				items_container.add_child(item)

func _get_upgrade_scene(app_id: String) -> PackedScene:

	var mapping: Dictionary = {
			"minerr": "Minerr",
			"brokerage": "BrokeRage",
			"fumble": "Fumble",
			"earlybird": "EarlyBird"
	}
	var app_name: String = mapping.get(app_id, app_id)
	var scene: PackedScene = null

	var wm := get_tree().root.get_node("WindowManager")
	if wm:
			var registry = wm.get("app_registry")
			if registry is Dictionary:
					scene = registry.get(app_name)

	if scene:
			var pane := scene.instantiate() as Pane
			if pane:
					var upgrade_scene: PackedScene = pane.upgrade_pane
					pane.queue_free()
					return upgrade_scene
	return null
