extends Control

@onready var name_label = %NameLabel
#@onready var icon = %Icon
@onready var cost_label = %CostLabel
@onready var desc_label = %DescriptionLabel
@onready var effect_list = %EffectList
@onready var buy_button = %BuyButton
@onready var status_label = %StatusLabel
@onready var close_button: Button = %CloseButton


var current_upgrade: UpgradeResource = null


func _ready() -> void:
	z_index = 1000

func show_upgrade(upgrade: UpgradeResource):
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

	# Always show button, gray out if not purchasable
	var can_purchase = UpgradeManager.can_purchase(upgrade.upgrade_id)
	buy_button.disabled = not can_purchase
	if UpgradeManager.can_purchase(upgrade.upgrade_id):
		buy_button.disabled = false
		buy_button.text = "Buy"
	else:
		buy_button.disabled = true
		buy_button.text = "Can't Buy"

	status_label.visible = false # Hide status, unless you want an error message

	# Don't reposition the tooltip
	self.visible = true


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




func _on_close_button_pressed() -> void:
	self.visible = false
	# Clear selection when closed
	var parent_ui = get_parent().get_parent().get_parent() # Or however you access UpgradeTreeUI
	if parent_ui.has_method("clear_upgrade_selection"):
		parent_ui.clear_upgrade_selection()
