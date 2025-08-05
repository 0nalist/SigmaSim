extends PanelContainer
class_name UpgradeUI

#signal buy_requested(upgrade_id: String)
signal purchase_requested(upgrade_id: String)


var upgrade_data: Dictionary
var is_locked: bool = false

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var level_label: Label = %LevelLabel
@onready var cost_label: Label = %CostLabel
@onready var buy_button: Button = %BuyButton

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)

func set_upgrade(upgrade: Dictionary) -> void:
	upgrade_data = upgrade
	name_label.text = upgrade.get("name", upgrade.get("id", "???"))
	desc_label.text = upgrade.get("description", "")
	set_level(UpgradeManager.get_level(upgrade["id"]))
	_refresh_cost()
	set_locked(UpgradeManager.is_locked(upgrade["id"]))

func set_locked(locked: bool) -> void:
	is_locked = locked
	buy_button.disabled = locked
	if locked:
			self.modulate = Color(0.6, 0.6, 0.6, 1.0) # Greyed out
	else:
			self.modulate = Color(1, 1, 1, 1)

func set_level(level: int) -> void:
	level_label.text = "Level: %d" % level

func _refresh_cost() -> void:
	var cost = UpgradeManager.get_cost_for_next_level(upgrade_data["id"])
	var cost_strs = []
	for currency in cost.keys():
			cost_strs.append("%s: %d" % [currency.capitalize(), int(round(cost[currency]))])
	cost_label.text = "Cost: " + " / ".join(cost_strs)

func _on_buy_button_pressed() -> void:
	emit_signal("purchase_requested", upgrade_data["id"])

func _on_PurchaseButton_pressed() -> void:
	emit_signal("buy_requested", upgrade_data["id"])
