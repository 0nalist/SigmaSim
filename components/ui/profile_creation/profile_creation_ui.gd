extends Control

signal profile_created(slot_id: int)
signal new_profile_abandoned

@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton



var step_scenes = [
	preload("res://components/ui/profile_creation/name_entry_screen.tscn"),
	preload("res://components/ui/profile_creation/pronoun_entry_screen.tscn"),
	
	
]

var user_data: Dictionary = {}


var current_step := 0
@onready var main_container: Control = %MainContainer

func _ready():
	user_data = PlayerManager.user_data
	_show_step(current_step)

func _show_step(index: int) -> void:
	for child in main_container.get_children():
		if not child.is_class("Button"):
			child.queue_free()
	var step_instance = step_scenes[index].instantiate()
	main_container.add_child(step_instance)
	if step_instance.has_signal("step_valid"):
		step_instance.step_valid.connect(_on_step_valid)

	# Disable Next by default
	next_button.disabled = true

func _on_step_valid(valid: bool) -> void:
	print("valid!!")
	next_button.disabled = not valid

func _finish_profile_creation():
	var name = user_data.get("name", "Unnamed")
	var username = user_data.get("username", "user")
	var pic_path = user_data.get("profile_pic", "res://assets/profiles/default.png")
	var background_path = user_data.get("background", "res://assets/Bliss_(Windows_XP) (2).png")

	var slot_id = SaveManager.get_next_available_slot()

	# Save basic profile metadata
	SaveManager.create_new_profile(slot_id, name, username, pic_path, background_path)

	# Store full identity/stats in PlayerManager
	PlayerManager.user_data = user_data.duplicate(true)
	PlayerManager.set_slot_id(slot_id)
	#PlayerManager.save() ## NO method exists

	emit_signal("profile_created", slot_id)
	queue_free()




func _on_back_button_pressed() -> void:
	if current_step > 0:
		current_step -= 1
		_show_step(current_step)
	else:
		new_profile_abandoned.emit()
		queue_free()


func _on_next_button_pressed() -> void:
	# Ask current step to save data if it supports it
	var current_screen = main_container.get_child(0)
	if current_screen and current_screen.has_method("save_data"):
		current_screen.save_data()

	if current_step < step_scenes.size() - 1:
		current_step += 1
		_show_step(current_step)
	else:
		_finish_profile_creation()
