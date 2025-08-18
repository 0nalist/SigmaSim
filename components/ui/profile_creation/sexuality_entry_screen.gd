extends Control


@onready var femmes_check_box: CheckBox = %FemmesCheckBox
@onready var mascs_check_box: CheckBox = %MascsCheckBox
@onready var enby_check_box: CheckBox = %EnbyCheckBox
@onready var question_button: Button = %QuestionButton

signal step_valid(valid: bool)


func _ready():
	_check_validity()

	question_button.pressed.connect(_simulate_selections)

func _check_validity() -> void:
	var is_valid := (
		femmes_check_box.button_pressed or
		mascs_check_box.button_pressed or
		enby_check_box.button_pressed
	)
	emit_signal("step_valid", is_valid)

func _simulate_selections() -> void:
	var fake_cursor := CursorManager.cursor
	#var original_pos := fake_cursor.position

	# Define checkboxes to simulate clicking
	var checkboxes := [femmes_check_box, mascs_check_box, enby_check_box]

	for checkbox in checkboxes:
		var checkbox_pos = checkbox.get_global_rect().get_center()
		var tween := create_tween()
		tween.tween_property(fake_cursor, "position", checkbox_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished

		checkbox.set_pressed_no_signal(true)
		await get_tree().create_timer(0.1).timeout

	_check_validity()

	await get_tree().create_timer(0.2).timeout

	# Move to the Next button and press it
	var next_button := _find_next_button()
	if next_button:
		var button_pos = next_button.get_global_rect().get_center()
		var tween := create_tween()
		tween.tween_property(fake_cursor, "position", button_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		await get_tree().create_timer(0.2).timeout
		next_button.emit_signal("pressed")

func _find_next_button() -> Button:
	var root := get_tree().get_root()
	for node in root.get_children():
		if node.has_node("NextButton"):
			return node.get_node("NextButton")
	return null


func _on_femmes_check_box_toggled(_toggled_on: bool) -> void:
	_check_validity()


func _on_mascs_check_box_toggled(_toggled_on: bool) -> void:
	_check_validity()


func _on_enby_check_box_toggled(_toggled_on: bool) -> void:
	_check_validity()

func save_data() -> void:
		var user_data = PlayerManager.user_data

		var attractions: Array[String] = []
		var x := 0.0
		var y := 0.0
		var z := 0.0
		if %FemmesCheckBox.button_pressed:
				attractions.append("femmes")
				x = 100.0
		if %MascsCheckBox.button_pressed:
				attractions.append("mascs")
				y = 100.0
		if %EnbyCheckBox.button_pressed:
				attractions.append("enbies")
				z = 100.0

		user_data["attracted_to"] = attractions
		user_data["fumble_pref_x"] = x
		user_data["fumble_pref_y"] = y
		user_data["fumble_pref_z"] = z
