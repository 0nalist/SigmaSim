## Autoload PlayerManager
extends Node

var slot_id = -1

var user_data: Dictionary = {
	# Identity
	"name": "",
	"username": "",
	"pronouns": "",
	"sexuality": "",
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
