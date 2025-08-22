## Autoload PlayerManager
extends Node

const DEFAULT_BACKGROUND_SHADERS := {
"BlueWarp": {
"stretch": 0.8,
"thing1": 0.6,
"thing2": 0.6,
"thing3": 0.8,
"speed": 0.03,
"color_low": {"r": 0.02, "g": 0.05, "b": 0.10, "a": 1.0},
"color_mid": {"r": 0.10, "g": 0.30, "b": 0.55, "a": 1.0},
"color_high": {"r": 0.30, "g": 0.60, "b": 0.85, "a": 1.0},
},
"ComicDots1": {
"circle_color": {"r": 0.00000481308, "g": 0.665883, "b": 0.95733, "a": 1.0},
"circle_multiplier": 32.0,
"speed": 0.01,
},
"ComicDots2": {
"circle_color": {"r": 0.00000481308, "g": 0.665883, "b": 0.95733, "a": 1.0},
"circle_multiplier": 32.0,
"speed": 0.01,
},
"Waves": {
"bottom_color": {"r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0},
"top_color": {"r": 0.868811, "g": 0.0, "b": 0.459911, "a": 1.0},
"wave_amp": 0.082,
"wave_size": 2.253,
"wave_time_mul": 0.01,
"total_phases": 6.0,
},
"Electric": {
"background_color": {"r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0},
"line_color": {"r": 0.0, "g": 1.0, "b": 1.0, "a": 1.0},
"line_freq": 5.085,
"height": 0.6,
"speed": 2.555,
"scale_x": 3.25,
"scale_y": 15.43,
},
"FlatColor": {
"color": {"r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0},
},
}

var default_user_data: Dictionary = {
	# Identity
	"name": "",
	"username": "",
	"password": "",
	"pronouns": "",
	"attracted_to": "",
	"portrait_config": {},
	"background_path": "",
	"education_level": "",
	"starting_student_debt": 0.0,
	"starting_credit_limit": 0.0,
	"bio": "",

	# Core Stats
	"alpha": 0.0,
	"beta": 0.0,
	"delta": 0.0,
	"gamma": 0.0,
	"omega": 0.0,
	"sigma": 0.0,

	#Upgradeable Gameplay Stats
	"productivity_per_click": 1.0,
	"power_per_click": 1.0,
	"gpu_power": 1.0,
	"worker_productivity": 100,
	
	# Chat Battle Stats
	"attractiveness": 50,
	"rizz": 1,
	"confidence": 100.0,
	"confidence_regen_rate": 1.0,
	"ex": 0.00,
	
	# Other Traits

	"zodiac_sign": "",
	"mbti": "",

# Fumble preferences
	"fumble_pref_x": 0.0,
	"fumble_pref_y": 0.0,
	"fumble_pref_z": 0.0,
	"fumble_curiosity": 50.0,
	"fumble_fugly_filter_threshold": 0,

	# Flags and progression
	"unlocked_perks": [],
	"seen_dialogue_ids": [],
	"global_rng_seed": 0,
	# Background shader settings
	"background_shaders": DEFAULT_BACKGROUND_SHADERS.duplicate(true),
	}

var user_data: Dictionary = default_user_data.duplicate(true)



func get_var(key: String, default_value = null):
	return user_data.get(key, default_value)

func set_var(key: String, value) -> void:
				user_data[key] = value

func get_stat(name: String, default_value: float = 0.0) -> float:
		return float(user_data.get(name, default_value))

func color_to_dict(color: Color) -> Dictionary:
		return {
				"r": color.r,
				"g": color.g,
				"b": color.b,
				"a": color.a,
		}

func dict_to_color(data: Dictionary) -> Color:
		return Color(
				data.get("r", 0.0),
				data.get("g", 0.0),
				data.get("b", 0.0),
				data.get("a", 1.0),
		)

func set_shader_param(shader: String, param: String, value) -> void:
		if not user_data.has("background_shaders"):
				user_data["background_shaders"] = {}
		if not user_data["background_shaders"].has(shader):
				user_data["background_shaders"][shader] = {}
		if value is Color:
				user_data["background_shaders"][shader][param] = color_to_dict(value)
		elif value is Vector2:
				user_data["background_shaders"][shader][param] = [value.x, value.y]
		else:
				user_data["background_shaders"][shader][param] = value

func get_shader_param(shader: String, param: String, default_value):
		var shaders = user_data.get("background_shaders", {})
		var shader_dict = shaders.get(shader, {})
		var val = shader_dict.get(param, default_value)
		if default_value is Color:
				if val is Dictionary:
						return dict_to_color(val)
				return default_value
		elif default_value is Vector2:
				if val is Array and val.size() >= 2:
						return Vector2(val[0], val[1])
				return default_value
		return val

func reset_shader(shader: String) -> void:
		if not DEFAULT_BACKGROUND_SHADERS.has(shader):
				return
		if not user_data.has("background_shaders"):
				user_data["background_shaders"] = {}
		user_data["background_shaders"][shader] = DEFAULT_BACKGROUND_SHADERS[shader].duplicate(true)




func reset():
	user_data = default_user_data.duplicate(true)
	SaveManager.current_slot_id = -1


func ensure_default_stats() -> void:
	for key in default_user_data.keys():
		if not user_data.has(key):
			user_data[key] = default_user_data[key]
		elif key == "background_shaders":
			for shader in default_user_data["background_shaders"].keys():
				if not user_data[key].has(shader):
					user_data[key][shader] = default_user_data["background_shaders"][shader].duplicate(true)
				else:
					for param in default_user_data["background_shaders"][shader].keys():
						if not user_data[key][shader].has(param):
							user_data[key][shader][param] = default_user_data["background_shaders"][shader][param]


func djb2(s: String) -> int:
		var hash := 5381
		for i in s.length():
				hash = ((hash << 5) + hash) + s.unicode_at(i)
		return hash & 0xFFFFFFFF




func has_seen(id: String) -> bool:
		return id in user_data["seen_dialogue_ids"]

func mark_seen(id: String) -> void:
	if not has_seen(id):
		user_data["seen_dialogue_ids"].append(id)



## -- SAVE LOAD

func get_save_data() -> Dictionary:
	user_data["global_rng_seed"] = RNGManager.seed
	return user_data.duplicate(true)

func load_from_data(data: Dictionary) -> void:
	user_data = data.duplicate(true)
	ensure_default_stats()
	if user_data.has("confidence"):
		user_data["confidence"] = clamp(user_data["confidence"], 0.0, 100.0)



## -- BACKGROUNDS ## probably make this its own resource late

var background_effects := {
	"The Dropout": _apply_dropout,
	"The Burnout": _apply_burnout,
	"The Gamer": _apply_gamer,
	"The Manager": _apply_manager,
	"The Postgrad": _apply_postgrad,
	"The Stoic": _apply_stoic,
	"Grandma's Favorite": _apply_grandma,
	"Pretty Privilege": _apply_pretty_privilege,
}


func _apply_grandma() -> void:
	PortfolioManager.add_cash(20.00)
	var center = get_viewport().get_visible_rect().size / 2
	StatpopManager.spawn("+$20.00", center, "click", Color.GREEN)

func _apply_pretty_privilege() -> void:
		var new_attractiveness = StatManager.get_base_stat("attractiveness", 0.0) + 10.0
		StatManager.set_base_stat("attractiveness", new_attractiveness)

func _apply_dropout() -> void:
		PortfolioManager.cash = 300.0
		StatManager.set_base_stat("cash", PortfolioManager.cash)
		PortfolioManager.set_student_loans(0.0)

func _apply_burnout() -> void:
		PortfolioManager.credit_used = 10000.0
		PortfolioManager.credit_limit = 25000.0
		PortfolioManager.set_student_loans(0.0)

func _apply_gamer() -> void:
	PortfolioManager.set_student_loans(40000.0)
	#AppManager.unlock_app("Minerr")
	GPUManager.add_gpu("")
	#ResourceManager.add_gpu("BasicGPU", 3)

func _apply_manager() -> void:
	PortfolioManager.set_student_loans(120000.0)
	#Grinderr.set_permanent_discount(0.5)
	#Grinderr.set_first_employee_free(true)

func _apply_postgrad() -> void:
		PortfolioManager.set_student_loans(360000.0)

		# Background perks are applied directly to base stats so they
		# participate in normal upgrade recalculation.
		var current_ppc = StatManager.get_base_stat("productivity_per_click", 1.0)
		StatManager.set_base_stat("productivity_per_click", current_ppc * 2.0)

		var current_gpu = StatManager.get_base_stat("gpu_power", 1.0)
		StatManager.set_base_stat("gpu_power", current_gpu * 2.0)

func _apply_stoic() -> void:
	PortfolioManager.credit_used = 100000.0
	PortfolioManager.credit_limit = 99000.0
	PortfolioManager.add_student_loans(500000)



func apply_background_effects(background_name: String) -> void:
	if background_effects.has(background_name):
		background_effects[background_name].call()
	else:
		printerr("No background effects found for: " + background_name)
