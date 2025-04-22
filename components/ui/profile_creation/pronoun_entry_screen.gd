extends Control

signal step_valid(valid: bool)

@onready var boy_check_box: CheckBox = %BoyCheckBox
@onready var girl_check_box: CheckBox = %GirlCheckBox
@onready var custom_gender_check_box: CheckBox = %CustomGender

@onready var custom_pronoun_container: HBoxContainer = %CustomPronounContainer
@onready var custom_pronoun_line_edit_1: LineEdit = %CustomPronounLineEdit1
@onready var custom_pronoun_line_edit_2: LineEdit = %CustomPronounLineEdit2
@onready var custom_pronoun_line_edit_3: LineEdit = %CustomPronounLineEdit3

@onready var man_button: Button = %ManButton
@onready var woman_button: Button = %WomanButton

func _ready():
	man_button.pressed.connect(func(): _simulate_choice_and_continue("Boy"))
	woman_button.pressed.connect(func(): _simulate_choice_and_continue("Girl"))

	boy_check_box.toggled.connect(_check_validity)
	girl_check_box.toggled.connect(_check_validity)
	custom_gender_check_box.toggled.connect(func(toggled): 
		custom_pronoun_container.visible = toggled
		_check_validity("")
	)
	custom_pronoun_container.hide()
	_check_validity("")

func _simulate_choice_and_continue(word: String) -> void:
	var target_checkbox: CheckBox = null

	match word:
		"Boy":
			target_checkbox = boy_check_box
		"Girl":
			target_checkbox = girl_check_box

	if not target_checkbox:
		return

	var fake_cursor := CursorManager.cursor
	var start_pos := fake_cursor.position
	var checkbox_pos := target_checkbox.get_global_rect().get_center()

	# Move to checkbox
	var tween := create_tween()
	tween.tween_property(fake_cursor, "position", checkbox_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	# Check the box
	target_checkbox.set_pressed_no_signal(true)
	_check_validity("")

	await get_tree().create_timer(0.3).timeout

	# Move to the Next button (find it safely)
	var next_button = _find_next_button()
	if next_button:
		var button_pos = next_button.get_global_rect().get_center()
		var tween2 := create_tween()
		tween2.tween_property(fake_cursor, "position", button_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween2.finished

		await get_tree().create_timer(0.2).timeout
		next_button.emit_signal("pressed")  # simulate the click

func _check_validity(_text) -> void:
	var is_valid := (
		boy_check_box.button_pressed or
		girl_check_box.button_pressed or
		custom_gender_check_box.button_pressed
	)
	emit_signal("step_valid", is_valid)

func _find_next_button() -> Button:
	var root = get_tree().get_root()
	for node in root.get_children():
		if node.has_node("NextButton"):
			return node.get_node("NextButton")
	return null

func save_data() -> void:
	var user_data = PlayerManager.user_data

	var selected_pronouns: Array[String] = []
	if %BoyCheckBox.button_pressed:
		selected_pronouns.append("he/him")
	if %GirlCheckBox.button_pressed:
		selected_pronouns.append("she/her")
	if %CustomGender.button_pressed:
		for line_edit in [%CustomPronounLineEdit1, %CustomPronounLineEdit2, %CustomPronounLineEdit3]:
			var p = line_edit.text.strip_edges()
			if p != "":
				selected_pronouns.append(p)

	user_data["pronouns"] = selected_pronouns
