diff --git a/autoloads/upgrade_manager.gd b/autoloads/upgrade_manager.gd
index 25b2c4e018fb06c2f98bc3925d7d11ee47095119..1b2b3104c8c13df51f9da53c73e78e7ca4949fef 100644
--- a/autoloads/upgrade_manager.gd
+++ b/autoloads/upgrade_manager.gd
@@ -1,173 +1,276 @@
 extends Node
-# Autoload: UpgradeManager
-
-var upgrade_states: Dictionary = {} # upgrade_id → { unlocked: bool, purchased: bool }
-var available_upgrades: Dictionary = {} # upgrade_id → UpgradeResource
-
-signal upgrade_unlocked(id: String)
-signal upgrade_purchased(id: String)
-
-
-@export var upgrade_files: Array[UpgradeResource] = []
-
+## UpgradeManager: loads upgrade definitions from JSON and tracks player upgrade levels.
+##
+## All upgrades live in `res://upgrades/` (vanilla) and `user://mods/upgrades/`.
+## Mod files override vanilla files by id.  Each upgrade is a Dictionary with keys:
+## - id: String unique identifier
+## - name, description: display strings
+## - systems: Array of system tags (e.g. "Workforce")
+## - dependencies: Array of upgrade ids required before unlocking
+## - max_level: -1 for unlimited
+## - cost_per_level: Dictionary or Array of Dictionary[String,float]
+## - scale_by_formula: bool
+## - cost_formula: String or Dictionary[String,String] evaluated with variables
+##               `level`, `base_cost`, and `prev_cost`
+## - effects: Array of effect Dictionaries {target, operation, value, scale_with_level?}
+##
+## UpgradeManager only handles loading, costs and purchasing.  Stat application
+## is handled by StatManager, which listens to our signals.
+
+signal upgrade_purchased(id: String, new_level: int)
+signal levels_changed() ## Emitted when levels are loaded or reset
+
+var upgrades: Dictionary = {}      # id -> upgrade data
+var player_levels: Dictionary = {} # id -> purchased count
+
+const EXPECTED_KEYS := [
+        "id", "name", "description", "effects", "systems",
+        "dependencies", "max_level", "cost_per_level",
+        "scale_by_formula", "cost_formula"
+]
 
 func _ready() -> void:
-	load_all_upgrades()
+        load_all_upgrades()
 
-# --- Registry and loader --- #
+## --- Loading -------------------------------------------------------
 
 func load_all_upgrades() -> void:
-	for upgrade in upgrade_files:
-			if upgrade.upgrade_id != "":
-				available_upgrades[upgrade.upgrade_id] = upgrade
-			else:
-				push_warning("UpgradeManager: Skipped invalid upgrade with no ID.")
-
-
-
-# --- State management --- #
-
-func unlock_upgrade(id: String) -> void:
-	if not upgrade_states.has(id):
-		upgrade_states[id] = {}
-	upgrade_states[id].unlocked = true
-	emit_signal("upgrade_unlocked", id)
-
-func purchase_upgrade(id: String) -> void:
-	var upgrade = get_upgrade_by_id(id)
-	if not upgrade:
-		push_error("UpgradeManager: Tried to purchase unknown upgrade: %s" % id)
-		return
-
-	if not is_unlocked(id):
-		return
-
-	var state = upgrade_states.get(id, {})
-	var count = state.get("purchase_count", 0)
-
-	if upgrade.purchase_limit != -1 and count >= upgrade.purchase_limit:
-		return  # Reached limit
-
-	var cost = upgrade.base_cost_cash * pow(upgrade.cost_multiplier, count)
-	if PortfolioManager.cash < cost:
-		return  # Not enough money
-
-	PortfolioManager.attempt_spend(cost)
-	upgrade.apply_all()
-
-	state.purchase_count = count + 1
-	upgrade_states[id] = state
-	emit_signal("upgrade_purchased", id)
-
-
-func is_unlocked(id: String) -> bool:
-	var state = upgrade_states.get(id, {})
-	if state.has("unlocked"):
-		return state.unlocked
-
-	var upgrade := get_upgrade_by_id(id)
-	if not upgrade:
-		return false
-
-	# If no unlock_conditions defined, default to unlocked
-	if upgrade.unlock_conditions.is_empty():
-		return true
-
-	return false
-
-
-func is_purchased(id: String) -> bool:
-	var upgrade = get_upgrade_by_id(id)
-	var count = upgrade_states.get(id, {}).get("purchase_count", 0)
-	if upgrade.purchase_limit == -1:
-		return false  # never "fully" purchased if unlimited
-	return count >= upgrade.purchase_limit
-
-
-
-# --- Queries --- #
-func can_purchase(id: String) -> bool:
-	var upgrade = get_upgrade_by_id(id)
-	if not upgrade:
-		return false
-	if not is_unlocked(id):
-		return false
-	var count = get_purchase_count(id)
-	if upgrade.purchase_limit != -1 and count >= upgrade.purchase_limit:
-		return false
-	var cost = upgrade.base_cost_cash * pow(upgrade.cost_multiplier, count)
-	if PortfolioManager.cash < cost:
-		return false
-	return true
-
-
-func get_purchase_count(id: String) -> int:
-	return upgrade_states.get(id, {}).get("purchase_count", 0)
-
-func get_upgrade_by_id(id: String) -> UpgradeResource:
-	return available_upgrades.get(id)
+        upgrades.clear()
+        _load_dir("res://upgrades", false)
+        _load_dir("user://mods/upgrades", true)
+        emit_signal("levels_changed") # upgrades may define new stats
+
+func reload_upgrades() -> void:
+        load_all_upgrades()
+
+func _load_dir(path: String, is_mod: bool) -> void:
+        var dir := DirAccess.open(path)
+        if dir == null:
+                push_warning("UpgradeManager: missing directory %s" % path)
+                return
+        dir.list_dir_begin()
+        var file_name := dir.get_next()
+        while file_name != "":
+                if dir.current_is_dir():
+                        file_name = dir.get_next()
+                        continue
+                if file_name.get_extension().to_lower() != "json":
+                        file_name = dir.get_next()
+                        continue
+                var file_path := path.path_join(file_name)
+                var text := FileAccess.get_file_as_string(file_path)
+                var data = JSON.parse_string(text)
+                if typeof(data) != TYPE_DICTIONARY:
+                        push_error("UpgradeManager: invalid JSON in %s" % file_path)
+                        file_name = dir.get_next()
+                        continue
+                if not _validate_upgrade(data, file_path):
+                        file_name = dir.get_next()
+                        continue
+                var id = data["id"]
+                if is_mod and upgrades.has(id):
+                        push_warning("UpgradeManager: mod overwriting upgrade '%s'" % id)
+                upgrades[id] = data
+                file_name = dir.get_next()
+        dir.list_dir_end()
+
+func _validate_upgrade(data: Dictionary, file_path: String) -> bool:
+        var id = data.get("id", "")
+        if id == "":
+                push_warning("UpgradeManager: upgrade missing id in %s" % file_path)
+                return false
+        for key in data.keys():
+                if key not in EXPECTED_KEYS:
+                        push_warning("UpgradeManager: unknown field '%s' in %s" % [key, id])
+        if not data.has("cost_per_level"):
+                push_warning("UpgradeManager: upgrade '%s' missing cost_per_level" % id)
+                data["cost_per_level"] = {}
+        var cpl = data["cost_per_level"]
+        if typeof(cpl) == TYPE_ARRAY:
+                for i in range(cpl.size()):
+                        if typeof(cpl[i]) != TYPE_DICTIONARY:
+                                push_error("UpgradeManager: cost_per_level entry %d must be Dictionary in %s" % [i, id])
+                                cpl[i] = {}
+        elif typeof(cpl) != TYPE_DICTIONARY:
+                push_error("UpgradeManager: cost_per_level must be Array or Dictionary in %s" % id)
+                data["cost_per_level"] = {}
+        if data.get("scale_by_formula", false):
+                var formula = data.get("cost_formula")
+                if typeof(formula) != TYPE_STRING and typeof(formula) != TYPE_DICTIONARY:
+                        push_error("UpgradeManager: cost_formula for %s must be String or Dictionary" % id)
+        return true
+
+## --- Query helpers -------------------------------------------------
+
+func get_upgrade(id: String) -> Dictionary:
+        return upgrades.get(id)
 
 func get_all_upgrades() -> Array:
-	return available_upgrades.values()
-
-func get_upgrades_by_source(source_name: String) -> Array:
-	var target = source_name.to_lower()
-	return available_upgrades.values().filter(func(u): return u.source.to_lower() == target)
-
-func get_upgrade_layers(upgrades: Array) -> Array:
-	var remaining = upgrades.duplicate()
-	var layers: Array = []
-	var placed_ids := {}  # upgrade_id -> true
-	var max_iterations := 1000  # prevent infinite loops
-
-	while not remaining.is_empty() and max_iterations > 0:
-		var current_layer: Array = []
-		for upgrade in remaining:
-			var prereqs = upgrade.prerequisites if upgrade.has_method("prerequisites") else []
-			var all_met = true
-			for prereq_id in prereqs:
-				if not placed_ids.has(prereq_id):
-					all_met = false
-					break
-			if all_met:
-				current_layer.append(upgrade)
+        return upgrades.values()
+
+func get_level(id: String) -> int:
+        return player_levels.get(id, 0)
+
+func is_locked(id: String) -> bool:
+        var upgrade := get_upgrade(id)
+        if upgrade == null:
+                return true
+        for dep in upgrade.get("dependencies", []):
+                if get_level(dep) <= 0:
+                        return true
+        return false
+
+func get_upgrades_for_system(system: String, include_locked := false) -> Array:
+        var result: Array = []
+        for upgrade in upgrades.values():
+                if system in upgrade.get("systems", []):
+                        if include_locked or not is_locked(upgrade.get("id")):
+                                result.append(upgrade)
+        return result
+
+func get_upgrade_layers(list: Array) -> Array:
+        var remaining = list.duplicate()
+        var layers: Array = []
+        var placed_ids := {}
+        var max_iterations := 1000
+        while not remaining.is_empty() and max_iterations > 0:
+                var current_layer: Array = []
+                for upgrade in remaining:
+                        var deps = upgrade.get("dependencies", [])
+                        var all_met = true
+                        for dep in deps:
+                                if not placed_ids.has(dep):
+                                        all_met = false
+                                        break
+                        if all_met:
+                                current_layer.append(upgrade)
+                if current_layer.is_empty():
+                        push_error("UpgradeManager: Cyclical or invalid dependency in upgrade tree! Remaining: %s" % (
+                                remaining.map(func(u): return u.get("id"))))
+                        break
+                layers.append(current_layer)
+                for upgrade in current_layer:
+                        placed_ids[upgrade.get("id")] = true
+                        remaining.erase(upgrade)
+                max_iterations -= 1
+        if max_iterations <= 0:
+                push_error("UpgradeManager: Hit max iterations in get_upgrade_layers (possible infinite loop)")
+        return layers
+
+## --- Costing -------------------------------------------------------
+
+func max_level(id: String) -> int:
+        var upgrade := get_upgrade(id)
+        var m = upgrade.get("max_level")
+        if m == null or m == "":
+                return -1
+        return int(m)
+
+func get_cost_for_next_level(id: String) -> Dictionary:
+        var upgrade := get_upgrade(id)
+        if upgrade == null:
+                return {}
+        var next_level := get_level(id) + 1
+        return _get_cost_for_level(upgrade, next_level)
+
+func _get_cost_for_level(upgrade: Dictionary, level: int) -> Dictionary:
+        var base_cost := _get_base_cost(upgrade, level)
+        if upgrade.get("scale_by_formula", false):
+                var prev_cost: Dictionary = {}
+                if level > 1:
+                        prev_cost = _get_cost_for_level(upgrade, level - 1)
+                var formula = upgrade.get("cost_formula")
+                var result: Dictionary = {}
+                if typeof(formula) == TYPE_DICTIONARY:
+                        for currency in base_cost.keys():
+                                var expr_str: String = str(formula.get(currency, ""))
+                                if expr_str == "":
+                                        result[currency] = base_cost.get(currency, 0.0)
+                                        continue
+                                var expr := Expression.new()
+                                if expr.parse(expr_str, ["level", "base_cost", "prev_cost"]) != OK:
+                                        push_error("UpgradeManager: bad cost formula for %s (%s)" % [upgrade.get("id"), currency])
+                                        result[currency] = base_cost.get(currency, 0.0)
+                                        continue
+                                var val = expr.execute([level, base_cost, prev_cost])
+                                if typeof(val) in [TYPE_FLOAT, TYPE_INT]:
+                                        result[currency] = float(val)
+                                else:
+                                        push_error("UpgradeManager: cost formula for %s (%s) didn't return number" % [upgrade.get("id"), currency])
+                                        result[currency] = base_cost.get(currency, 0.0)
+                        return result
+                elif typeof(formula) == TYPE_STRING:
+                        var expr := Expression.new()
+                        if expr.parse(formula, ["level", "base_cost", "prev_cost"]) != OK:
+                                push_error("UpgradeManager: bad cost formula for %s" % upgrade.get("id"))
+                                return base_cost
+                        var val = expr.execute([level, base_cost, prev_cost])
+                        if typeof(val) == TYPE_DICTIONARY:
+                                return val
+                        push_error("UpgradeManager: cost formula for %s must return Dictionary" % upgrade.get("id"))
+                        return base_cost
+                else:
+                        push_error("UpgradeManager: cost_formula missing for %s" % upgrade.get("id"))
+                        return base_cost
+        return base_cost
+
+func _get_base_cost(upgrade: Dictionary, level: int) -> Dictionary:
+        var cpl = upgrade.get("cost_per_level", {})
+        if typeof(cpl) == TYPE_ARRAY:
+                if cpl.size() == 0:
+                        return {}
+                if level - 1 < cpl.size():
+                        return cpl[level - 1]
+                return cpl[-1]
+        elif typeof(cpl) == TYPE_DICTIONARY:
+                return cpl
+        return {}
+
+## --- Purchasing ----------------------------------------------------
+
+func _get_currency_amount(currency: String) -> float:
+        if currency == "cash":
+                return PortfolioManager.cash
+        return PortfolioManager.get_crypto_amount(currency)
+
+func _deduct_currency(currency: String, amount: float) -> void:
+        if currency == "cash":
+                PortfolioManager.spend_cash(amount)
+        else:
+                PortfolioManager.add_crypto(currency, -amount)
 
-		if current_layer.is_empty():
-			push_error("UpgradeManager: Cyclical or invalid dependency in upgrade tree! Remaining: %s" % (
-				remaining.map(func(u): return u.upgrade_id)))
-			break
-
-		layers.append(current_layer)
-		for upgrade in current_layer:
-			placed_ids[upgrade.upgrade_id] = true
-			remaining.erase(upgrade)
-
-		max_iterations -= 1
-
-	if max_iterations <= 0:
-		push_error("UpgradeManager: Hit max iterations in get_upgrade_layers (possible infinite loop)")
-
-	return layers
-
-
-
-
-# --- Save/load --- #
+func can_purchase(id: String) -> bool:
+        if is_locked(id):
+                return false
+        var max := max_level(id)
+        if max != -1 and get_level(id) >= max:
+                return false
+        var cost := get_cost_for_next_level(id)
+        for currency in cost.keys():
+                if _get_currency_amount(currency) < cost[currency]:
+                        return false
+        return true
+
+func purchase(id: String) -> bool:
+        if not can_purchase(id):
+                return false
+        var cost := get_cost_for_next_level(id)
+        for currency in cost.keys():
+                _deduct_currency(currency, cost[currency])
+        var level := get_level(id) + 1
+        player_levels[id] = level
+        emit_signal("upgrade_purchased", id, level)
+        return true
+
+## --- Save / Load ---------------------------------------------------
 
 func get_save_data() -> Dictionary:
-	return upgrade_states
+        return player_levels.duplicate(true)
 
 func load_from_data(data: Dictionary) -> void:
-	print("🔄 UpgradeManager: Resetting and loading...")
-	EffectManager.reset()
-	upgrade_states.clear()
-	upgrade_states = data
-
-	for id in upgrade_states:
-		var upgrade = get_upgrade_by_id(id)
-		if not upgrade:
-			continue
-		var count = upgrade_states[id].get("purchase_count", 0)
-		print("⬆️  Applying", id, "x", count)
-		for _i in count:
-			upgrade.apply_all()
+        player_levels = data.duplicate(true)
+        emit_signal("levels_changed")
+
+func reset() -> void:
+        player_levels.clear()
+        emit_signal("levels_changed")
