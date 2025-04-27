extends Resource
class_name UpgradeResource

@export var upgrade_name: String = ""      # Display name: "Giga Clicker I"
@export var description: String = ""        # Optional: "Doubles production output"
@export var source: String = ""              # Where it came from: "Patch Bay", "Quest Reward", etc.

@export var effects: Array[EffectResource] = [] # All effects it applies

func apply_all() -> void:
	for effect in effects:
		EffectManager.apply_effect(effect.target_variable, effect)

func remove_all() -> void:
	for effect in effects:
		EffectManager.remove_effect(effect.target_variable, effect)
