extends Control

signal step_valid(valid: bool)

@onready var he_check_box: CheckBox = %HeCheckBox
@onready var politics_check_box: CheckBox = %PoliticsCheckBox
@onready var politics_options: VBoxContainer = %PoliticsOptions
@onready var she_check_box: CheckBox = %SheCheckBox
@onready var they_check_box: CheckBox = %TheyCheckBox
@onready var custom_pronoun_container: HBoxContainer = %CustomPronounContainer
@onready var custom_pronoun_line_edit_1: LineEdit = %CustomPronounLineEdit1
@onready var custom_pronoun_line_edit_2: LineEdit = %CustomPronounLineEdit2
@onready var custom_pronoun_line_edit_3: LineEdit = %CustomPronounLineEdit3

func _ready():
		he_check_box.toggled.connect(_check_validity)
		politics_check_box.toggled.connect(func(toggled):
				politics_options.visible = toggled
				_check_validity()
		)
		she_check_box.toggled.connect(_check_validity)
		they_check_box.toggled.connect(_check_validity)
		for line_edit in [custom_pronoun_line_edit_1, custom_pronoun_line_edit_2, custom_pronoun_line_edit_3]:
				line_edit.text_changed.connect(_check_validity)
		politics_options.hide()
		_check_validity()

func _check_validity(_toggled = null) -> void:
		var is_valid := he_check_box.button_pressed
		if politics_check_box.button_pressed:
				var custom_filled := (
						custom_pronoun_line_edit_1.text.strip_edges() != "" and
						custom_pronoun_line_edit_2.text.strip_edges() != "" and
						custom_pronoun_line_edit_3.text.strip_edges() != ""
				)
				is_valid = is_valid or she_check_box.button_pressed or they_check_box.button_pressed or custom_filled
		emit_signal("step_valid", is_valid)

func save_data() -> void:
		var user_data = PlayerManager.user_data
		var pronouns := ""
		if politics_check_box.button_pressed:
				if custom_pronoun_line_edit_1.text.strip_edges() != "" and custom_pronoun_line_edit_2.text.strip_edges() != "" and custom_pronoun_line_edit_3.text.strip_edges() != "":
						pronouns = "%s/%s/%s" % [
								custom_pronoun_line_edit_1.text.strip_edges(),
								custom_pronoun_line_edit_2.text.strip_edges(),
								custom_pronoun_line_edit_3.text.strip_edges()
						]
				elif they_check_box.button_pressed:
						pronouns = "they/them/theirs"
				elif she_check_box.button_pressed:
						pronouns = "she/her/hers"
				elif he_check_box.button_pressed:
						pronouns = "he/him/his"
		else:
				if he_check_box.button_pressed:
						pronouns = "he/him/his"
		user_data["pronouns"] = pronouns
