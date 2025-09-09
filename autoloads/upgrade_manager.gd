extends Node
## UpgradeManager: loads upgrade definitions from JSON and tracks player upgrade levels.
##
## All upgrades live in `res://upgrades/` (vanilla) and `user://mods/upgrades/`.
## Mod files override vanilla files by id. Each upgrade is a Dictionary with keys:
## - id: String unique identifier
## - name, description: display strings
## - systems: Array of system tags (e.g. "Workforce")
## - dependencies: Array of upgrade ids required before unlocking
## - max_level: -1 for unlimited
## - repeatable: if false, upgrade can only be purchased once
## - cost_per_level: Dictionary or Array of Dictionary[String, float]
## - scale_by_formula: bool
## - cost_formula: String or Dictionary[String, String] evaluated with variables
##               `level`, `base_cost`, and `prev_cost`
## - effects: Array of effect Dictionaries {target, operation, value, scale_with_level?}
##
## UpgradeManager only handles loading, costs and purchasing. Stat application
## is handled by StatManager, which listens to our signals.

signal upgrade_purchased(id: String, new_level: int)
signal levels_changed ## Emitted when levels are loaded or reset

var upgrades: Dictionary = {}  # id -> upgrade data
var player_levels: Dictionary = {}  # id -> purchased count
var cooldowns: Dictionary = {}  # id -> {"start": int, "base": float}
var next_cost_cache: Dictionary = {}  # id -> {"level": int, "cost": Dictionary}

const EXPECTED_KEYS := [
		"id", "name", "description", "effects", "systems", "dependencies",
		"max_level", "repeatable", "cooldown", "cost_per_level", "scale_by_formula", "cost_formula"
]

func _ready() -> void:
	load_all_upgrades()

## --- Loading -------------------------------------------------------

func load_all_upgrades() -> void:
	upgrades.clear()
	next_cost_cache.clear()
	_load_dir("res://data/upgrades", false)
	_load_dir("user://mods/upgrades", true)
	Events.register_upgrade_signals(upgrades.keys())
	emit_signal("levels_changed")
	
func reload_upgrades() -> void:
	load_all_upgrades()

func _load_dir(path: String, is_mod: bool) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("UpgradeManager: missing directory %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue
		if file_name.get_extension().to_lower() != "json":
			file_name = dir.get_next()
			continue
		var file_path := path.path_join(file_name)
		var text := FileAccess.get_file_as_string(file_path)
		var data = JSON.parse_string(text)
		if typeof(data) != TYPE_DICTIONARY:
			push_error("UpgradeManager: invalid JSON in %s" % file_path)
			file_name = dir.get_next()
			continue
		if not _validate_upgrade(data, file_path):
			file_name = dir.get_next()
			continue
		var id = data["id"]
		if is_mod and upgrades.has(id):
			push_warning("UpgradeManager: mod overwriting upgrade '%s'" % id)
		upgrades[id] = data
		file_name = dir.get_next()
	dir.list_dir_end()

func _validate_upgrade(data: Dictionary, file_path: String) -> bool:
	var id = data.get("id", "")
	if id == "":
		push_warning("UpgradeManager: upgrade missing id in %s" % file_path)
		return false
	for key in data.keys():
		if key not in EXPECTED_KEYS:
			push_warning("UpgradeManager: unknown field '%s' in %s" % [key, id])
	if not data.has("cost_per_level"):
		push_warning("UpgradeManager: upgrade '%s' missing cost_per_level" % id)
		data["cost_per_level"] = {}
	var cpl = data["cost_per_level"]
	if typeof(cpl) == TYPE_ARRAY:
		for i in range(cpl.size()):
			if typeof(cpl[i]) != TYPE_DICTIONARY:
				push_error("UpgradeManager: cost_per_level entry %d must be Dictionary in %s" % [i, id])
				cpl[i] = {}
	elif typeof(cpl) != TYPE_DICTIONARY:
		push_error("UpgradeManager: cost_per_level must be Array or Dictionary in %s" % id)
		data["cost_per_level"] = {}

	if data.get("scale_by_formula", false):
		var formula = data.get("cost_formula")
		if typeof(formula) != TYPE_STRING and typeof(formula) != TYPE_DICTIONARY:
			push_error("UpgradeManager: cost_formula for %s must be String or Dictionary" % id)

		if not data.has("repeatable"):
				data["repeatable"] = true
		if not data.has("cooldown"):
				data["cooldown"] = -1

	return true

## --- Query helpers -------------------------------------------------

func get_upgrade(id: String) -> Dictionary:
	return upgrades.get(id)

func get_all_upgrades() -> Array:
	return upgrades.values()

func get_level(id: String) -> int:
	return player_levels.get(id, 0)

func is_locked(id: String) -> bool:
	var upgrade := get_upgrade(id)
	if upgrade == null:
		return true
	for dep in upgrade.get("dependencies", []):
		if get_level(dep) <= 0:
			return true
	return false

func get_upgrades_for_system(system: String, include_locked := false) -> Array:
	var target := system.to_lower()
	var result: Array = []
	for upgrade in upgrades.values():
		for sys in upgrade.get("systems", []):
			if typeof(sys) == TYPE_STRING and sys.to_lower() == target:
				if include_locked or not is_locked(upgrade.get("id")):
					result.append(upgrade)
				break
	return result

func get_upgrade_layers(list: Array) -> Array:
	var remaining = list.duplicate()
	var layers: Array = []
	var placed_ids := {}
	var max_iterations := 1000
	while not remaining.is_empty() and max_iterations > 0:
		var current_layer: Array = []
		for upgrade in remaining:
			var deps = upgrade.get("dependencies", [])
			var all_met = true
			for dep in deps:
				if not placed_ids.has(dep):
					all_met = false
					break
			if all_met:
				current_layer.append(upgrade)
		if current_layer.is_empty():
			push_error("UpgradeManager: Cyclical or invalid dependency in upgrade tree! Remaining: %s"
				% (remaining.map(func(u): return u.get("id"))))
			break
		layers.append(current_layer)
		for upgrade in current_layer:
			placed_ids[upgrade.get("id")] = true
			remaining.erase(upgrade)
		max_iterations -= 1
	if max_iterations <= 0:
		push_error("UpgradeManager: Hit max iterations in get_upgrade_layers (possible infinite loop)")
	return layers

## --- Costing -------------------------------------------------------

func max_level(id: String) -> int:
	var upgrade := get_upgrade(id)
	if upgrade == null:
		return -1
	if not is_repeatable(id):
		return 1

	var m = upgrade.get("max_level")

	# Handle missing / null values
	if m == null:
		return -1

	# Handle string case (e.g. "" or maybe "∞")
	if typeof(m) == TYPE_STRING:
		if m.strip_edges() == "":
			return -1
		# Try parsing string to int if possible
		var parsed = m.to_int()
		return parsed if parsed != 0 else -1

	# Handle int/float directly
	if typeof(m) in [TYPE_INT, TYPE_FLOAT]:
		return int(m)

	# Fallback: treat as unlimited
	return -1

func is_repeatable(id: String) -> bool:
		var upgrade := get_upgrade(id)
		if upgrade == null:
				return false
		return upgrade.get("repeatable", true)

func get_cost_for_next_level(id: String) -> Dictionary:
	var next_level := get_level(id) + 1
	var cached = next_cost_cache.get(id)
	if cached != null and cached.get("level", 0) == next_level:
		return cached.get("cost", {})
	var upgrade := get_upgrade(id)
	if upgrade == null:
		return {}
	var cost := _get_cost_for_level(upgrade, next_level)
	next_cost_cache[id] = {"level": next_level, "cost": cost}
	return cost
	
func _get_cost_for_level(upgrade: Dictionary, level: int) -> Dictionary:
	var base_cost := _get_base_cost(upgrade, level)

	if upgrade.get("scale_by_formula", false):
		var prev_cost: Dictionary = {}
		if level > 1:
			prev_cost = _get_cost_for_level(upgrade, level - 1)

		var formula = upgrade.get("cost_formula")
		var result: Dictionary = {}

		if typeof(formula) == TYPE_DICTIONARY:
			for currency in base_cost.keys():
				var expr_str: String = str(formula.get(currency, ""))
				if expr_str == "":
					result[currency] = base_cost.get(currency, 0.0)
					continue
				var expr := Expression.new()
				if expr.parse(expr_str, ["level", "base_cost", "prev_cost"]) != OK:
					push_error("UpgradeManager: bad cost formula for %s (%s)" % [upgrade.get("id"), currency])
					result[currency] = base_cost.get(currency, 0.0)
					continue
				var val = expr.execute([level, base_cost, prev_cost])
				if typeof(val) in [TYPE_FLOAT, TYPE_INT]:
					result[currency] = float(val)
				else:
					push_error("UpgradeManager: cost formula for %s (%s) didn't return number"
						% [upgrade.get("id"), currency])
					result[currency] = base_cost.get(currency, 0.0)
			return result

		if typeof(formula) == TYPE_STRING:
			var expr := Expression.new()
			if expr.parse(formula, ["level", "base_cost", "prev_cost"]) != OK:
				push_error("UpgradeManager: bad cost formula for %s" % upgrade.get("id"))
				return base_cost
			var val = expr.execute([level, base_cost, prev_cost])
			if typeof(val) == TYPE_DICTIONARY:
				return val
			push_error("UpgradeManager: cost formula for %s must return Dictionary" % upgrade.get("id"))
			return base_cost

		push_error("UpgradeManager: cost_formula missing for %s" % upgrade.get("id"))
		return base_cost

	return base_cost

func _get_base_cost(upgrade: Dictionary, level: int) -> Dictionary:
	var cpl = upgrade.get("cost_per_level", {})
	if typeof(cpl) == TYPE_ARRAY:
		if cpl.size() == 0:
			return {}
		if level - 1 < cpl.size():
			return cpl[level - 1]
		return cpl[-1]
	if typeof(cpl) == TYPE_DICTIONARY:
		return cpl
	return {}

## --- Purchasing ----------------------------------------------------

func _get_currency_amount(currency: String) -> float:
	if currency == "cash":
		return PortfolioManager.cash
	if currency == "ex":
		return StatManager.get_stat("ex").to_float()
	return PortfolioManager.get_crypto_amount(currency)

func _deduct_currency(currency: String, amount: float, credit_only: bool = false) -> bool:
	if currency == "cash":
			return PortfolioManager.attempt_spend(amount, PortfolioManager.CREDIT_REQUIREMENTS["upgrades"], false, credit_only)
	if currency == "ex":
		var ex_stat: FlexNumber = StatManager.get_stat("ex")
		if ex_stat.to_float() < amount:
			return false
		ex_stat.subtract(amount)
		StatManager.set_base_stat("ex", ex_stat)
		StatpopManager.spawn(
			"-%s EX" % NumberFormatter.smart_format(amount),
			get_viewport().get_mouse_position(),
			"click",
			Color.YELLOW,
		)
		return true
	if PortfolioManager.get_crypto_amount(currency) < amount:
		return false
	PortfolioManager.add_crypto(currency, -amount)
	StatpopManager.spawn(
		"-%s %s" % [NumberFormatter.smart_format(amount), currency],
		get_viewport().get_mouse_position(),
		"click",
		Color.YELLOW
	)
	return true

func can_purchase(id: String) -> bool:
	if is_locked(id):
		return false
	if get_cooldown_remaining(id) > 0:
		return false
	var max := max_level(id)
	if max != -1 and get_level(id) >= max:
		return false
	var cost := get_cost_for_next_level(id)
	for currency in cost.keys():
		var amount: float = cost[currency]
		if currency == "cash":
			if PortfolioManager.can_pay_with_cash(amount):
				continue
			var remainder = amount - PortfolioManager.cash
			if remainder <= 0:
				continue
			# Respect credit score requirements for upgrades. If the
			# player lacks the minimum score, purchasing should be
			# disallowed even when credit limit remains.
			var required_score = PortfolioManager.CREDIT_REQUIREMENTS.get("upgrades", 0)
			if PortfolioManager.credit_score < required_score:
				return false
			if not PortfolioManager.can_pay_with_credit(remainder):
				return false
		elif currency == "ex":
			if StatManager.get_stat("ex").to_float() < amount:
				return false
		else:
			if PortfolioManager.get_crypto_amount(currency) < amount:
				return false
	return true

func purchase(id: String, credit_only: bool = false) -> bool:
	if not can_purchase(id):
		return false
	var upgrade := get_upgrade(id)
	if upgrade == null:
		return false
	var cost: Dictionary = get_cost_for_next_level(id)
	for currency in cost.keys():
			if not _deduct_currency(currency, cost[currency], credit_only):
					return false
	var level: int = get_level(id) + 1
	player_levels[id] = level
	var cd = float(upgrade.get("cooldown", -1))
	if cd > 0:
			cooldowns[id] = {"start": TimeManager.total_minutes_elapsed, "base": cd}
	elif cooldowns.has(id):
			cooldowns.erase(id)
	print("UpgradeManager.purchase: emitting upgrade_purchased for", id, "level", level)
	upgrade_purchased.emit(id, level)
	Events.emit_upgrade_purchased(id, level)
	return true

func get_cooldown_remaining(id: String) -> float:
		if not cooldowns.has(id):
				return 0.0
		var data = cooldowns[id]
		var base := float(data.get("base", -1))
		if base <= 0:
				cooldowns.erase(id)
				return 0.0
		var start := int(data.get("start", TimeManager.total_minutes_elapsed))
		var elapsed = TimeManager.total_minutes_elapsed - start
		var mult = StatManager.get_stat("upgrade_cooldown_multiplier", 1.0)
		var remaining = base * mult - elapsed
		if remaining <= 0:
				cooldowns.erase(id)
				return 0.0
		return remaining

## --- Save / Load ---------------------------------------------------

func get_save_data() -> Dictionary:
		return {
				"levels": player_levels.duplicate(true),
				"cooldowns": cooldowns.duplicate(true)
		}

func load_from_data(data: Dictionary) -> void:
		if data.has("levels"):
				player_levels = data.get("levels", {}).duplicate(true)
				cooldowns = data.get("cooldowns", {}).duplicate(true)
		else:
				player_levels = data.duplicate(true)
				cooldowns.clear()
		emit_signal("levels_changed")

func reset() -> void:
		player_levels.clear()
		cooldowns.clear()
		emit_signal("levels_changed")
