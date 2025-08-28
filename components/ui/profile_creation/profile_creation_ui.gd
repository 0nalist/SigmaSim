extends Control

signal profile_created()
signal new_profile_abandoned

@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton





var step_scenes = [
	preload("res://components/ui/profile_creation/name_entry_screen.tscn"),
	preload("res://components/ui/profile_creation/gender_selection_screen.tscn"),
	preload("res://components/ui/profile_creation/sexuality_entry_screen.tscn"),
	preload("res://components/ui/profile_creation/education_selection_screen.tscn"),
	preload("res://components/ui/profile_creation/background_selection_screen.tscn"),
	preload("res://components/ui/profile_creation/portrait_creation_screen.tscn"),
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not next_button.disabled:
			next_button.emit_signal("pressed")
			get_viewport().set_input_as_handled()

func _finish_profile_creation():
		var password = user_data.get("password", "")
		var seed_val: int
		if password != "":
			seed_val = PlayerManager.djb2(password)
			user_data["using_random_seed"] = false
			print("Profile creation password:", password, " -> seed:", seed_val)
		else:
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			seed_val = rng.randi()
			user_data["using_random_seed"] = true
			print("Profile creation no password; generated random seed:", seed_val)
		user_data["global_rng_seed"] = seed_val
		RNGManager.init_seed(seed_val)
		var slot_id = SaveManager.get_next_available_slot()
		print("Finalizing profile in slot", slot_id, "with seed", seed_val)
		SaveManager.initialize_new_profile(slot_id, user_data)
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
