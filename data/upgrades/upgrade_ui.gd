extends PanelContainer
class_name UpgradeUI

#signal buy_requested(upgrade_id: String)
signal purchase_requested(upgrade_id: String)


var upgrade_data: Dictionary
var is_locked: bool = false
var upgrade_queued: bool = false

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var level_label: Label = %LevelLabel
@onready var cost_label: Label = %CostLabel
@onready var buy_button: Button = %BuyButton
@onready var cooldown_label: Label = %CooldownLabel

func _ready() -> void:
        buy_button.pressed.connect(_on_buy_button_pressed)
        TimeManager.minute_passed.connect(_on_minute_passed)
        # Re-evaluate affordability whenever relevant stats change so the Buy
        # button correctly enables when the player gains resources.
        PortfolioManager.cash_updated.connect(_on_resources_changed)
        StatManager.stat_changed.connect(_on_stat_changed)
        if upgrade_queued:
                _apply_upgrade()
        else:
                set_locked(is_locked)

func set_upgrade(upgrade: Dictionary) -> void:
        upgrade_data = upgrade
        upgrade_queued = true
        if is_inside_tree():
                _apply_upgrade()

func _apply_upgrade() -> void:
        upgrade_queued = false
        name_label.text = upgrade_data.get("name", upgrade_data.get("id", "???"))
        desc_label.text = upgrade_data.get("description", "")
        set_level(StatManager.get_upgrade_level(upgrade_data["id"]))
        _refresh_cost()
        set_locked(UpgradeManager.is_locked(upgrade_data["id"]))
        _update_cooldown()

func refresh() -> void:
	if upgrade_data.is_empty():
		return
	set_level(StatManager.get_upgrade_level(upgrade_data["id"]))
	_refresh_cost()
	_update_cooldown()

func set_locked(locked: bool) -> void:
        is_locked = locked
        if not is_inside_tree():
                return
        buy_button.disabled = locked
        if locked:
                self.modulate = Color(0.6, 0.6, 0.6, 1.0) # Greyed out
        else:
                self.modulate = Color(1, 1, 1, 1)

func set_level(level: int) -> void:
		var repeatable = upgrade_data.get("repeatable", true)
		if repeatable:
				level_label.text = "Level: %d" % level
		else:
				level_label.text = "PURCHASED" if level > 0 else ""
				buy_button.disabled = is_locked or not UpgradeManager.can_purchase(upgrade_data.get("id", ""))
		_update_cooldown()

func _refresh_cost() -> void:
	var cost = UpgradeManager.get_cost_for_next_level(upgrade_data["id"])
	var cost_strs = []
	for currency in cost.keys():
		var amount = float(cost[currency])
		if currency == "cash":
			var formatted = NumberFormatter.format_commas(amount, 2)
			# Handle negative values for cash
			if amount < 0:
				cost_strs.append("-$" + formatted.substr(1)) # Remove extra '-'
			else:
				cost_strs.append("$" + formatted)
		else:
			# Default to 2 decimals and capitalized currency name
			cost_strs.append("%s: %s" % [currency.capitalize(), NumberFormatter.format_commas(amount, 2)])
	cost_label.text = "Cost: " + " / ".join(cost_strs)

func _on_buy_button_pressed() -> void:
		emit_signal("purchase_requested", upgrade_data["id"])

func _on_PurchaseButton_pressed() -> void:
		emit_signal("buy_requested", upgrade_data["id"])

func _on_minute_passed(_m: int) -> void:
	_update_cooldown()

func _on_resources_changed(_value = 0) -> void:
	_update_cooldown()

func _on_stat_changed(stat: String, _value) -> void:
	# Some upgrades use non-cash currencies stored in StatManager (e.g. ex).
	# If the changed stat is part of the cost, refresh the button state.
	if upgrade_data.is_empty():
			return
	var cost = UpgradeManager.get_cost_for_next_level(upgrade_data.get("id"))
	if stat in cost.keys():
			_update_cooldown()

func _update_cooldown() -> void:
		if upgrade_data.is_empty():
				cooldown_label.text = ""
				return
		var remaining = ceil(UpgradeManager.get_cooldown_remaining(upgrade_data.get("id", "")))
		if remaining > 0:
				cooldown_label.text = "Ready in %s" % _format_minutes(int(remaining))
		else:
				cooldown_label.text = ""
		buy_button.disabled = is_locked or not UpgradeManager.can_purchase(upgrade_data.get("id", ""))

func _format_minutes(minutes: int) -> String:
		var days = minutes / (24 * 60)
		var hours = (minutes % (24 * 60)) / 60
		var mins = minutes % 60
		var parts: Array[String] = []
		if days > 0:
				parts.append("%dd" % days)
		if hours > 0:
				parts.append("%dh" % hours)
		if mins > 0 or parts.is_empty():
				parts.append("%dm" % mins)
		return " ".join(parts)

func _exit_tree() -> void:
			if TimeManager.minute_passed.is_connected(_on_minute_passed):
							TimeManager.minute_passed.disconnect(_on_minute_passed)
			if PortfolioManager.cash_updated.is_connected(_on_resources_changed):
							PortfolioManager.cash_updated.disconnect(_on_resources_changed)
			if StatManager.stat_changed.is_connected(_on_stat_changed):
							StatManager.stat_changed.disconnect(_on_stat_changed)
