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
           preload("res://components/ui/profile_creation/prof_pic_selection_screen.tscn"),
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
	var slot_id = SaveManager.get_next_available_slot()
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
