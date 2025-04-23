## Autoload PlayerManager
extends Node

var slot_id = -1

var user_data: Dictionary = {
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

	# Other Traits
	"zodiac_sign": "",
	"mbti": "",

	# Flags and progression
	"unlocked_perks": [],
	"seen_dialogue_ids": []
}

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

# Called once during login from SaveManager, like other systems
func set_slot_id(slot: int) -> void:
	slot_id = slot

func get_slot_id() -> int:
	return slot_id


## -- BACKGROUNDS ## probably make this its own resource late

var background_effects := {
	"The Dropout": func():
		PortfolioManager.cash = 300.0
		PortfolioManager.set_student_loans(0.0),

	"The Burnout": func():
		PortfolioManager.credit_used = 10000.0
		PortfolioManager.credit_limit = 25000.0
		PortfolioManager.set_student_loans(0.0),

	"The Gamer": func():
		PortfolioManager.set_student_loans(40000.0)
		#AppManager.unlock_app("Minerr")
		#ResourceManager.add_gpu("BasicGPU", 3),

	#"The Manager": func():
		#PlayerManager.set_var("student_loans", 120000.0)
		#pass
		#Grinderr.set_permanent_discount(0.5)
		#Grinderr.set_first_employee_free(true)

	#"The Postgrad": func():
		#pass
		#PlayerManager.set_var("student_loans", 360000.0)
		#EffectManager.add_modifier("PRODUCTIVITY_PER_CLICK_MULT", 2.0, "Postgrad")
		#EffectManager.add_modifier("GPU_POWER_MULT", 2.0, "Postgrad")
		#AppManager.unlock_feature("ScroogebergTerminal")
		#PlayerManager.set_var("can_see_stock_sentiment", true)
}

func apply_background_effects(background_name: String) -> void:
	if background_effects.has(background_name):
		background_effects[background_name].call()
	else:
		printerr("No background effects found for: " + background_name)
