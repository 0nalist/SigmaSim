## Autoload PlayerManager
extends Node
 	

var default_user_data: Dictionary = {
	# Identity
	"name": "",
	"username": "",
	"pronouns": "",
	"attracted_to": "",
	"profile_picture_path": "",
	"background_path": "",

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

	# Flags and progression
	"unlocked_perks": [],
	"seen_dialogue_ids": []
}

var user_data: Dictionary = default_user_data.duplicate(true)



func get_var(key: String, default_value = null):
	return user_data.get(key, default_value)

func set_var(key: String, value) -> void:
	user_data[key] = value




func reset():
	user_data = default_user_data.duplicate(true)
	SaveManager.current_slot_id = -1


func ensure_default_stats() -> void:
	for key in default_user_data.keys():
		if not user_data.has(key):
			user_data[key] = default_user_data[key]




func has_seen(id: String) -> bool:
	return id in user_data["seen_dialogue_ids"]

func mark_seen(id: String) -> void:
	if not has_seen(id):
		user_data["seen_dialogue_ids"].append(id)



## -- SAVE LOAD

func get_save_data() -> Dictionary:
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
	StatpopManager.spawn("+$20.00", center)

func _apply_pretty_privilege() -> void:
		var new_attractiveness := StatManager.get_stat("attractiveness") + 10.0
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
