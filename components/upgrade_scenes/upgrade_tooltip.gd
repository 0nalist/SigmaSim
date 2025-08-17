extends PanelContainer

@onready var name_label = %NameLabel
@onready var cost_label = %CostLabel
@onready var desc_label = %DescriptionLabel
@onready var effect_list = %EffectList
@onready var buy_button = %BuyButton
@onready var status_label = %StatusLabel
@onready var close_button: Button = %CloseButton

var current_upgrade: Dictionary = {}

func _ready() -> void:
	hide_tooltip()

func show_tooltip(upgrade: Dictionary):
		current_upgrade = upgrade
		_update_display()
		self.modulate = Color(1, 1, 1, 1)

func hide_tooltip():
	self.modulate = Color(1, 1, 1, 0)
	buy_button.disabled = true
	close_button.disabled = true

func _update_display() -> void:
	if current_upgrade.is_empty():
		return
	
	var id = current_upgrade.get("id", "")
	name_label.text = current_upgrade.get("name", id)
	cost_label.text = format_cost(current_upgrade)
	desc_label.text = current_upgrade.get("description", "")

	# Clear existing effect labels
	for child in effect_list.get_children():
		child.queue_free()
	
	# Add new effect labels
	for effect in current_upgrade.get("effects", []):
		var effect_label = Label.new()
		effect_label.text = describe_effect(effect)
		effect_list.add_child(effect_label)
	
		# Evaluate upgrade state
                var can_purchase = UpgradeManager.can_purchase(id)
                var level = StatManager.get_upgrade_level(id)
                var purchased_once = not UpgradeManager.is_repeatable(id) and level >= 1
                var maxed = not purchased_once and UpgradeManager.max_level(id) != -1 and level >= UpgradeManager.max_level(id)

		buy_button.disabled = not can_purchase or purchased_once or maxed
		if purchased_once:
				buy_button.text = "Purchased"
		else:
				buy_button.text = "Maxed Out" if maxed else "Buy"

	var status = get_status_text(current_upgrade)
	status_label.text = status
	status_label.visible = status != ""

	close_button.disabled = false


func _on_buy_button_pressed():
		var id = current_upgrade.get("id", "")
		if id != "" and UpgradeManager.can_purchase(id):
				UpgradeManager.purchase(id)
				_update_display()

func format_cost(upgrade: Dictionary) -> String:
		var cost = UpgradeManager.get_cost_for_next_level(upgrade.get("id"))
		var parts: Array[String] = []
		for currency in cost.keys():
				var amount = NumberFormatter.format_number(cost[currency])
				if currency == "cash":
						parts.append("💰 $%s" % amount)
				else:
						parts.append("%s %s" % [amount, currency])
		return "\n".join(parts)

func describe_effect(effect: Dictionary) -> String:
		var op = effect.get("operation", "add")
		var value = effect.get("value", 0)
		var target = effect.get("target", "")
		match op:
				"add":
						return "+%s %s" % [str(value), target]
				"mul":
						return "x%s %s" % [str(value), target]
				"set":
						return "Set %s to %s" % [target, str(value)]
				_:
						return "%s %s %s" % [op, str(value), target]

func get_status_text(upgrade: Dictionary) -> String:
	var id = upgrade.get("id", "")
	if id == "":
		return ""
	
                var level = StatManager.get_upgrade_level(id)
                if not UpgradeManager.is_repeatable(id) and level >= 1:
                                return "Purchased"
                if UpgradeManager.max_level(id) != -1 and level >= UpgradeManager.max_level(id):
                                return "Maxed Out"
	
	if UpgradeManager.is_locked(id):
		return "Locked"
	
	var cost = UpgradeManager.get_cost_for_next_level(id)
	for currency in cost.keys():
		if currency == "cash" and PortfolioManager.cash < cost[currency]:
			return "Not enough funds"
		if currency != "cash" and PortfolioManager.get_crypto_amount(currency) < cost[currency]:
			return "Not enough funds"
	
	return ""


func _on_close_button_pressed() -> void:
	hide_tooltip()
	var parent_ui = get_parent().get_parent().get_parent() # Or however you access UpgradeTreeUI
	if parent_ui.has_method("clear_upgrade_selection"):
		parent_ui.clear_upgrade_selection()
