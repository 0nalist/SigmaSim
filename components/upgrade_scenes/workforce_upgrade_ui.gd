class_name WorkForceUpgradeUI
extends Pane

@export var upgrade_card_scene: PackedScene

@onready var upgrade_list: VBoxContainer = %UpgradeList

func _ready():
	_populate()

func _populate():
	for upgrade in UpgradeManager.get_all_upgrades():
		if upgrade.source != "Workforce":
			continue
		var card := upgrade_card_scene.instantiate()
		card.call_deferred("set_upgrade", upgrade)
		upgrade_list.add_child(card)
		card.purchase_requested.connect(_on_upgrade_purchase_requested)

func _on_upgrade_purchase_requested(upgrade: UpgradeResource):
	UpgradeManager.purchase_upgrade(upgrade.upgrade_id)
	#print("UpgradeManager.purchase_upgrade " + str(upgrade.upgrade_id))
	
	#Siggy.spawn_and_say("Upgrades apply in the order you purchase them. So buy as many flat upgrades as you can before moving to multiplicative upgrades!")
