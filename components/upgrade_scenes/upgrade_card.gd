extends VBoxContainer



@onready var click_panel: PanelContainer = %ClickPanel
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescriptionLabel
@onready var price_label: Label = %PriceLabel
@onready var status_label: Label = %StatusLabel


signal purchase_requested(upgrade: UpgradeResource)

var upgrade: UpgradeResource
var upgrade_queued: bool = false

func set_upgrade(upg: UpgradeResource):
	upgrade = upg
	upgrade_queued = true
	if is_inside_tree():
		_refresh_upgrade()

func _ready():
	if upgrade_queued:
		_refresh_upgrade()
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	PortfolioManager.cash_updated.connect(_on_cash_updated)

func _refresh_upgrade():
	if not is_instance_valid(upgrade):
		return
	name_label.text = upgrade.upgrade_name
	desc_label.text = upgrade.description
	refresh_state()


func refresh_state():
	var id = upgrade.upgrade_id
	var count = UpgradeManager.get_purchase_count(id)
	var limit = upgrade.purchase_limit
	var cost = upgrade.get_current_cost()

	name_label.text = upgrade.upgrade_name
	desc_label.text = upgrade.description
	price_label.text = "💰 $%.0f" % cost

	if limit == -1:
		status_label.text = "Purchased: %d (∞ max)" % count
	elif count >= limit:
		status_label.text = "✅ Maxed (%d/%d)" % [count, limit]
	else:
		status_label.text = "Purchased: %d / %d" % [count, limit]

	# Handle interactivity & visual feedback
	if not UpgradeManager.is_unlocked(id):
		modulate = Color(0.7, 0.7, 0.7)  # dim when locked
		click_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	elif limit != -1 and count >= limit:
		modulate = Color(1, 1, 1)
		click_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	elif PortfolioManager.cash < cost:
		modulate = Color(0.85, 0.85, 0.85)  # slightly dim when unaffordable
		click_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		modulate = Color(1, 1, 1)
		click_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_upgrade_purchased(purchased_id: String) -> void:
	if upgrade.upgrade_id == purchased_id:
		refresh_state()

func _on_cash_updated(_new_cash: float) -> void:
	# Refresh to show if the upgrade is now affordable or not
	refresh_state()


func _on_click_panel_gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		purchase_requested.emit(upgrade)


func _on_click_panel_mouse_entered() -> void:
	modulate = Color(1.1, 1.1, 1.1) #swap out to panels later


func _on_click_panel_mouse_exited() -> void:
	modulate = Color(1, 1, 1) #swap out to panels later
