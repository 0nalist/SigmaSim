extends Node
# Autoload: UpgradeManager

var upgrade_states: Dictionary = {} # upgrade_id → { unlocked: bool, purchased: bool }
var available_upgrades: Dictionary = {} # upgrade_id → UpgradeResource

signal upgrade_unlocked(id: String)
signal upgrade_purchased(id: String)


@export var upgrade_files: Array[UpgradeResource] = []


func _ready() -> void:
	load_all_upgrades()

# --- Registry and loader --- #

func load_all_upgrades() -> void:
	for upgrade in upgrade_files:
			if upgrade.upgrade_id != "":
				available_upgrades[upgrade.upgrade_id] = upgrade
			else:
				push_warning("UpgradeManager: Skipped invalid upgrade with no ID.")



# --- State management --- #

func unlock_upgrade(id: String) -> void:
	if not upgrade_states.has(id):
		upgrade_states[id] = {}
	upgrade_states[id].unlocked = true
	emit_signal("upgrade_unlocked", id)

func purchase_upgrade(id: String) -> void:
	var upgrade = get_upgrade_by_id(id)
	if not upgrade:
		push_error("UpgradeManager: Tried to purchase unknown upgrade: %s" % id)
		return

	if not is_unlocked(id):
		return

	var state = upgrade_states.get(id, {})
	var count = state.get("purchase_count", 0)

	if upgrade.purchase_limit != -1 and count >= upgrade.purchase_limit:
		return  # Reached limit

	var cost = upgrade.base_cost_cash * pow(upgrade.cost_multiplier, count)
	if PortfolioManager.cash < cost:
		return  # Not enough money

	PortfolioManager.attempt_spend(cost)
	upgrade.apply_all()

	state.purchase_count = count + 1
	upgrade_states[id] = state
	emit_signal("upgrade_purchased", id)


func is_unlocked(id: String) -> bool:
	var state = upgrade_states.get(id, {})
	if state.has("unlocked"):
		return state.unlocked

	var upgrade := get_upgrade_by_id(id)
	if not upgrade:
		return false

	# If no unlock_conditions defined, default to unlocked
	if upgrade.unlock_conditions.is_empty():
		return true

	return false


func is_purchased(id: String) -> bool:
	var upgrade = get_upgrade_by_id(id)
	var count = upgrade_states.get(id, {}).get("purchase_count", 0)
	if upgrade.purchase_limit == -1:
		return false  # never "fully" purchased if unlimited
	return count >= upgrade.purchase_limit



# --- Queries --- #
func get_purchase_count(id: String) -> int:
	return upgrade_states.get(id, {}).get("purchase_count", 0)

func get_upgrade_by_id(id: String) -> UpgradeResource:
	return available_upgrades.get(id)

func get_all_upgrades() -> Array:
	return available_upgrades.values()

func get_upgrades_by_source(source_name: String) -> Array:
	var target = source_name.to_lower()
	return available_upgrades.values().filter(func(u): return u.source.to_lower() == target)

# --- Save/load --- #

func get_save_data() -> Dictionary:
	return upgrade_states

func load_from_data(data: Dictionary) -> void:
	print("🔄 UpgradeManager: Resetting and loading...")
	EffectManager.reset()
	upgrade_states.clear()
	upgrade_states = data

	for id in upgrade_states:
		var upgrade = get_upgrade_by_id(id)
		if not upgrade:
			continue
		var count = upgrade_states[id].get("purchase_count", 0)
		print("⬆️  Applying", id, "x", count)
		for _i in count:
			upgrade.apply_all()
