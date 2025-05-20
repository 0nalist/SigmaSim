extends Control

@onready var name_label = %NameLabel
#@onready var icon = %Icon
@onready var cost_label = %CostLabel
@onready var desc_label = %DescriptionLabel
@onready var effect_list = %EffectList
@onready var buy_button = %BuyButton
@onready var status_label = %StatusLabel

var current_upgrade: UpgradeResource = null

func show_upgrade(upgrade: UpgradeResource, screen_pos: Vector2, show_purchase: bool = false):
	current_upgrade = upgrade
	name_label.text = upgrade.upgrade_name
	#icon.texture = upgrade.icon if upgrade.icon else null
	cost_label.text = format_cost(upgrade)
	desc_label.text = upgrade.description

	# Clear and rebuild effects
	for child in effect_list.get_children():
		child.queue_free()
	for effect in upgrade.effects:
		var effect_label = Label.new()
		effect_label.text = describe_effect(effect)
		effect_list.add_child(effect_label)

	# Show/hide button
	var can_purchase = UpgradeManager.can_purchase(upgrade.upgrade_id)
	buy_button.visible = show_purchase and can_purchase
	buy_button.disabled = not can_purchase
	status_label.visible = not can_purchase
	if not can_purchase:
		status_label.text = get_status_text(upgrade)
	else:
		status_label.text = ""

	# Position and popup
	global_position = screen_pos + Vector2(16, 0)
	show()

func _on_buy_button_pressed():
	if current_upgrade:
		UpgradeManager.purchase_upgrade(current_upgrade.upgrade_id)
		hide()

func format_cost(upgrade: UpgradeResource) -> String:
	var txt = ""
	if upgrade.cost_cash > 0:
		txt += "💰 $" + NumberFormatter.format_number(upgrade.get_current_cost())
	for symbol in upgrade.cost_crypto:
		txt += "\n" + str(upgrade.cost_crypto[symbol]) + " " + symbol
	return txt.strip_edges()

func describe_effect(effect: EffectResource) -> String:
	# Build a human-readable description from effect fields
	return effect.description  # Or custom formatting

func get_status_text(upgrade: UpgradeResource) -> String:
	if UpgradeManager.is_purchased(upgrade.upgrade_id):
		return "Maxed Out"
	if not UpgradeManager.is_unlocked(upgrade.upgrade_id):
		return "Locked"
	if PortfolioManager.cash < upgrade.get_current_cost():
		return "Not enough funds"
	return ""
