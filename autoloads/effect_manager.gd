extends Node
#Autoload name EffectManager

var effect_stacks := {} # variable_name -> Array[EffectResource]

func apply_effect(variable_name: String, effect: EffectResource) -> void:
	if not effect_stacks.has(variable_name):
		effect_stacks[variable_name] = []
	effect_stacks[variable_name].append(effect)

func get_final_value(variable_name: String, base_value: float) -> float:
	var value = base_value
	if effect_stacks.has(variable_name):
		for effect in effect_stacks[variable_name]:
			value = effect.apply(value)
	return value

func clear_effects(variable_name: String) -> void:
	effect_stacks.erase(variable_name)

func remove_effect(variable_name: String, effect: EffectResource) -> void:
	if not effect_stacks.has(variable_name):
		return
	effect_stacks[variable_name].erase(effect)

func reset() -> void:
	effect_stacks.clear()
