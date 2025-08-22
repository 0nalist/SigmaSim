extends Control

signal profile_created()
signal new_profile_abandoned

@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton
@onready var step_label: Label = %StepLabel
@onready var step_progress: ProgressBar = %StepProgress





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
        step_progress.max_value = step_scenes.size()
        _show_step(current_step)

func _show_step(index: int) -> void:
	for child in main_container.get_children():
		if not child.is_class("Button"):
			child.queue_free()
        var step_instance = step_scenes[index].instantiate()
        step_instance.modulate.a = 0.0
        main_container.add_child(step_instance)
        if step_instance.has_signal("step_valid"):
                step_instance.step_valid.connect(_on_step_valid)

        # Disable Next by default
        next_button.disabled = true

        step_label.text = "Step %d/%d" % [index + 1, step_scenes.size()]
        var fade_tween = create_tween()
        fade_tween.tween_property(step_instance, "modulate:a", 1.0, 0.3)
        create_tween().tween_property(step_progress, "value", index + 1, 0.2)
        var label_tween = create_tween()
        label_tween.tween_property(step_label, "scale", Vector2(1.1, 1.1), 0.1)
        label_tween.tween_property(step_label, "scale", Vector2.ONE, 0.1)

func _on_step_valid(valid: bool) -> void:
        print("valid!!")
        next_button.disabled = not valid
        if valid:
                var t = create_tween()
                t.tween_property(next_button, "scale", Vector2(1.1, 1.1), 0.1)
                t.tween_property(next_button, "scale", Vector2.ONE, 0.1)

func _finish_profile_creation():
	var password = user_data.get("password", "")
	var seed_val: int
	if password != "":
		seed_val = PlayerManager.djb2(password)
		print("Profile creation password:", password, " -> seed:", seed_val)
	else:
		seed_val = int(Time.get_unix_time_from_system())
		print("Profile creation no password; using unix time seed:", seed_val)
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
