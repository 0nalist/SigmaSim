## Autoload PlayerManager
extends Node

var slot_id = -1

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
	


	# Other Traits
	"zodiac_sign": "",
	"mbti": "",

	# Flags and progression
	"unlocked_perks": [],
	"seen_dialogue_ids": []
}

var user_data: Dictionary = default_user_data.duplicate(true)


func get_var(key: String, default_value = null):
	return user_data.get(key, default_value)

func set_var(key: String, value) -> void:
	user_data[key] = value


## -- Global stat access -- ##

func get_stat(key: String) -> Variant:
	match key:
		"cash": return PortfolioManager.cash
		"credit_used": return PortfolioManager.credit_used
		"student_loans": return PortfolioManager.student_loans
		"alpha", "beta", "delta", "gamma", "omega", "sigma":
			return user_data.get(key, 0.0)
		_: return user_data.get(key)

func set_stat(key: String, value: Variant) -> void:
	match key:
		"cash": PortfolioManager.cash = value
		"student_loans": PortfolioManager.student_loans = value
		"credit_used": PortfolioManager.credit_used = value
		"alpha", "beta", "delta", "gamma", "omega", "sigma":
			user_data[key] = value
		_: user_data[key] = value


func reset():
	user_data = default_user_data.duplicate(true)
	slot_id = -1


func ensure_default_stats() -> void:
	for key in default_user_data.keys():
		if not user_data.has(key):
			user_data[key] = default_user_data[key]




func adjust_stat(stat: String, delta: float) -> void:
	if user_data.has(stat):
		user_data[stat] += delta


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
	


# Called once during login from SaveManager, like other systems
func set_slot_id(slot: int) -> void:
	slot_id = slot

func get_slot_id() -> int:
	return slot_id


## -- BACKGROUNDS ## probably make this its own resource late

var background_effects := {
	"The Dropout": _apply_dropout,
	"The Burnout": _apply_burnout,
	"The Gamer": _apply_gamer,
	"The Manager": _apply_manager,
	"The Postgrad": _apply_postgrad,
	"The Stoic": _apply_stoic,
}


# First, define real functions
func _apply_dropout() -> void:
	PortfolioManager.cash = 300.0
	PortfolioManager.set_student_loans(0.0)

func _apply_burnout() -> void:
	PortfolioManager.credit_used = 10000.0
	PortfolioManager.credit_limit = 25000.0
	PortfolioManager.set_student_loans(0.0)

func _apply_gamer() -> void:
	PortfolioManager.set_student_loans(40000.0)
	#AppManager.unlock_app("Minerr")
	#ResourceManager.add_gpu("BasicGPU", 3)

func _apply_manager() -> void:
	PortfolioManager.set_student_loans(120000.0)
	#Grinderr.set_permanent_discount(0.5)
	#Grinderr.set_first_employee_free(true)

func _apply_postgrad() -> void:
	PortfolioManager.set_student_loans(360000.0)

	var upgrade = UpgradeResource.new()
	upgrade.upgrade_name = "Postgrad"
	upgrade.source = "Background"

	var effect1 = EffectResource.new()
	effect1.target_variable = "productivity_per_click"
	effect1.operation = "mult"
	effect1.value = 2.0
	upgrade.effects.append(effect1)

	var effect2 = EffectResource.new()
	effect2.target_variable = "gpu_power"
	effect2.operation = "mult"
	effect2.value = 2.0
	upgrade.effects.append(effect2)

	upgrade.apply_all()

	# Unlock features
	#AppManager.unlock_feature("ScroogebergTerminal")
	#PlayerManager.set_var("can_see_stock_sentiment", true)

func _apply_stoic() -> void:
	PortfolioManager.credit_used = 100000.0
	PortfolioManager.credit_limit = 99000.0
	PortfolioManager.add_student_loans(500000)



func apply_background_effects(background_name: String) -> void:
	if background_effects.has(background_name):
		background_effects[background_name].call()
	else:
		printerr("No background effects found for: " + background_name)
