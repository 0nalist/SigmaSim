extends Pane
class_name SoftWaresApp

const SOFTWARE_ITEM_SCENE: PackedScene = preload("res://components/apps/soft_wares/soft_ware_item.tscn")

var soft_wares_registry: Dictionary = {
	"minerr": {
		"title": "Minerr",
		"description": "Mine and trade cryptocurrencies.",
		"icon": preload("res://assets/cursors/pickaxe.png"),
		"cost": 100,
		"has_upgrades": true
	},
	"brokerage": {
		"title": "BrokeRage",
		"description": "Buy and sell stocks in a chaotic market.",
		"icon": preload("res://assets/logos/brokerage.png"),
		"cost": 250,
		"has_upgrades": true
	},
	"fumble": {
		"title": "Fumble",
		"description": "Date, swipe, and battle for love.",
		"icon": preload("res://assets/logos/fumble.png"),
		"cost": 300,
		"has_upgrades": false
	},
	"earlybird": {
		"title": "EarlyBird",
		"description": "Rise early and get that worm.",
		"icon": preload("res://assets/early_bird/worm1.png"),
		"cost": 150,
		"has_upgrades": false
	}
}

@onready var items_container: VBoxContainer = %ItemsContainer

func _ready() -> void:
	_populate_items()

func _populate_items() -> void:
	for app_id in soft_wares_registry.keys():
		var data: Dictionary = soft_wares_registry[app_id]
		var item: SoftWareItem = SOFTWARE_ITEM_SCENE.instantiate() as SoftWareItem
		items_container.add_child(item)
		item.app_icon = data["icon"]
		item.app_title = data["title"]
		item.app_description = data["description"]
		item.app_cost = int(data["cost"])
		item.has_upgrades = bool(data["has_upgrades"])
		item.app_id = app_id
		
