extends Resource
class_name UpgradeResource

@export var upgrade_id: String = ""  # Unique key like "click_bonus_1"
@export var unlock_conditions: Array[String] = [] # Optional: triggers, stats, etc.
@export var cost_cash: float = 0.0
@export var cost_crypto: Dictionary = {}  # symbol -> amount
@export var upgrade_name: String = ""      # Display name: "Giga Clicker I"
@export var description: String = ""        # Optional: "Doubles production output"
@export var source: String = ""              # Where it came from: "Patch Bay", "Quest Reward", etc.

@export var effects: Array[EffectResource] = [] # All effects it applies

@export var base_cost_cash: float = 100.0
@export var cost_multiplier: float = 1.5  # exponential scaling
@export var purchase_limit: int = -1  # -1 means unlimited


var is_unlocked: bool = false
var is_purchased: bool = false

var current_purchase_count: int = 0

func get_current_cost() -> float:
	var count = UpgradeManager.get_purchase_count(upgrade_id)
	return base_cost_cash * pow(cost_multiplier, count)

func apply_all() -> void:
	for effect in effects:
		EffectManager.apply_effect(effect.target_variable, effect)

func remove_all() -> void:
	for effect in effects:
		EffectManager.remove_effect(effect.target_variable, effect)
