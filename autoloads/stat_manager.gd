extends Node
## StatManager keeps track of all gameplay stats derived from base values and
## upgrade effects.  All systems should query stats from here instead of reading
## upgrade data directly.
##
## Base stats are loaded from `res://data/stats/base_stats.json` and can be
## overridden by `user://mods/stats/base_stats.json`.  Mods may also introduce
## new stats simply by defining them in these files or by providing upgrades
## that reference new stat keys.
##
## Each upgrade effect dictionary is expected to have:
##   {"target": "stat_key", "operation": "add|mul|set", "value": number,
##    "scale_with_level": bool (default true)}
##
## The final value for each stat is computed deterministically whenever the
## upgrade levels change.  Effects are applied in no particular order since
## recompute always starts from the base stat value.

signal stat_changed(stat: String, value: float)

var base_stats: Dictionary = {}
var stats: Dictionary = {}

func _ready() -> void:
        _load_base_stats()
        _recalculate_all()
        if Engine.has_singleton("UpgradeManager"):
                UpgradeManager.upgrade_purchased.connect(_on_upgrades_changed)
                if UpgradeManager.has_signal("levels_changed"):
                        UpgradeManager.levels_changed.connect(_on_upgrades_changed)

func _load_base_stats() -> void:
        base_stats.clear()
        _load_stats_file("res://data/stats/base_stats.json")
        _load_stats_file("user://mods/stats/base_stats.json")

func _load_stats_file(path: String) -> void:
        if not FileAccess.file_exists(path):
                return
        var text := FileAccess.get_file_as_string(path)
        var data = JSON.parse_string(text)
        if typeof(data) == TYPE_DICTIONARY:
                for k in data.keys():
                        base_stats[k] = data[k]

## Public API --------------------------------------------------------

func get_stat(stat_name: String, default := 0.0) -> float:
        return stats.get(stat_name, base_stats.get(stat_name, default))

func get_all_stats() -> Dictionary:
        return stats.duplicate(true)

func get_base_stat(stat_name: String, default := 0.0) -> float:
        return base_stats.get(stat_name, default)

func set_base_stat(stat_name: String, value: float) -> void:
        base_stats[stat_name] = value
        _recalculate_all()

func reset() -> void:
        _load_base_stats()
        _recalculate_all()

## Recalculation -----------------------------------------------------

func _on_upgrades_changed(_id = "", _level = 0) -> void:
        _recalculate_all()

func _recalculate_all() -> void:
        var old_stats = stats.duplicate(true)
        stats = base_stats.duplicate(true)
        if Engine.has_singleton("UpgradeManager"):
                for id in UpgradeManager.player_levels.keys():
                        var level: int = UpgradeManager.get_level(id)
                        if level <= 0:
                                continue
                        var upg = UpgradeManager.get_upgrade(id)
                        if upg == null:
                                continue
                        for effect in upg.get("effects", []):
                                _apply_effect(effect, level)
        for key in stats.keys():
                if old_stats.get(key) != stats[key]:
                        emit_signal("stat_changed", key, stats[key])

func _apply_effect(effect: Dictionary, level: int) -> void:
        var target = effect.get("target", "")
        if target == "":
                push_warning("StatManager: effect missing target")
                return
        var value = float(effect.get("value", 0.0))
        var scale := effect.get("scale_with_level", true)
        if scale:
                value *= level
        var op = effect.get("operation", "add")
        var current = stats.get(target, base_stats.get(target, 0.0))
        match op:
                "add":
                        stats[target] = current + value
                "mul":
                        if not stats.has(target):
                                current = base_stats.get(target, 1.0)
                        stats[target] = current * value
                "set":
                        stats[target] = value
                _:
                        push_warning("StatManager: unknown operation '%s' for stat '%s'" % [op, target])
