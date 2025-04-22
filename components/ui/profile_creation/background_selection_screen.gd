extends Control
signal step_valid(valid: bool)

@onready var next_button: Button = %NextButton
@onready var option_buttons: Array[Button] = [
	%BackgroundOption1,
	%BackgroundOption2,
	%BackgroundOption3
]

var selected_background: String = ""

func _ready():
#	next_button.disabled = true

	# Assign labels and connect each button
#	option_buttons[0].text = "Trust Fund Baby\nStart with extra money, but spoiled."
#	option_buttons[1].text = "Self-Made Hustler\nBegin broke, but gain productivity and hustle stats."
#	option_buttons[2].text = "Influencer Nepo Baby\nStart with fame and followers, but fragile ego."

	for button in option_buttons:
		button.pressed.connect(func():
			_on_background_selected(button)
		)

func _on_background_selected(button: Button) -> void:
	for btn in option_buttons:
		btn.set_pressed_no_signal(false)
	button.set_pressed_no_signal(true)

	selected_background = button.text.split("\n")[0]  # Grab the title
	next_button.disabled = false
	emit_signal("step_valid", true)

func save_data() -> void:
	var user_data = PlayerManager.user_data
	user_data["starting_background"] = selected_background
