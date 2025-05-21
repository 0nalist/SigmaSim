extends PanelContainer

@onready var name_label = %NameLabel
@onready var cost_label = %CostLabel
@onready var desc_label = %DescriptionLabel
@onready var effect_list = %EffectList
@onready var buy_button = %BuyButton
@onready var status_label = %StatusLabel
@onready var close_button: Button = %CloseButton

var current_upgrade: UpgradeResource = null

func _ready() -> void:
	hide_tooltip()

func show_tooltip(upgrade: UpgradeResource):
	current_upgrade = upgrade
	_update_display()
	self.modulate = Color(1, 1, 1, 1)

func hide_tooltip():
	self.modulate = Color(1, 1, 1, 0)
	buy_button.disabled = true
	close_button.disabled = true

func _update_display():
	if not current_upgrade:
		return
	name_label.text = current_upgrade.upgrade_name
	cost_label.text = format_cost(current_upgrade)
	desc_label.text = current_upgrade.description

	# Clear and rebuild effects
	for child in effect_list.get_children():
		child.queue_free()
	for effect in current_upgrade.effects:
		var effect_label = Label.new()
		effect_label.text = describe_effect(effect)
		effect_list.add_child(effect_label)

	var can_purchase = UpgradeManager.can_purchase(current_upgrade.upgrade_id)
	var is_maxed = UpgradeManager.is_purchased(current_upgrade.upgrade_id)

	buy_button.disabled = not can_purchase or is_maxed
	buy_button.text = "Maxed Out" if is_maxed else "Buy"

	# Show status if maxed or locked, hide otherwise
	var status = get_status_text(current_upgrade)
	status_label.text = status
	status_label.visible = status != ""

	# Make sure close button is always enabled when tooltip is shown
	close_button.disabled = false

func _on_buy_button_pressed():
	if current_upgrade and not UpgradeManager.is_purchased(current_upgrade.upgrade_id):
		UpgradeManager.purchase_upgrade(current_upgrade.upgrade_id)
		_update_display() # Refresh everything (cost, button, status, effects)

func format_cost(upgrade: UpgradeResource) -> String:
	var txt = ""
	if upgrade.cost_cash > 0:
		txt += "💰 $" + NumberFormatter.format_number(upgrade.get_current_cost())
	for symbol in upgrade.cost_crypto:
		txt += "\n" + str(upgrade.cost_crypto[symbol]) + " " + symbol
	return txt.strip_edges()

func describe_effect(effect: EffectResource) -> String:
	return effect.description

func get_status_text(upgrade: UpgradeResource) -> String:
	if UpgradeManager.is_purchased(upgrade.upgrade_id):
		return "Maxed Out"
	if not UpgradeManager.is_unlocked(upgrade.upgrade_id):
		return "Locked"
	if PortfolioManager.cash < upgrade.get_current_cost():
		return "Not enough funds"
	return ""

func _on_close_button_pressed() -> void:
	hide_tooltip()
	var parent_ui = get_parent().get_parent().get_parent() # Or however you access UpgradeTreeUI
	if parent_ui.has_method("clear_upgrade_selection"):
		parent_ui.clear_upgrade_selection()
