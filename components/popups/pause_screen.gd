extends Control
class_name PauseScreen

signal resume_pressed
signal save_pressed
signal sleep_pressed
signal logout_pressed
signal shutdown_pressed

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var sleep_button: Button = %SleepButton
@onready var logout_button: Button = %LogoutButton
@onready var shutdown_button: Button = %ShutdownButton

func _ready() -> void:
	resume_button.pressed.connect(func(): emit_signal("resume_pressed"))
	save_button.pressed.connect(func(): emit_signal("save_pressed"))
	sleep_button.pressed.connect(func(): emit_signal("sleep_pressed"))
	logout_button.pressed.connect(func(): emit_signal("logout_pressed"))
	shutdown_button.pressed.connect(func(): emit_signal("shutdown_pressed"))



##TODO create a new type of popup that is automatically centered, cannot be moved or closed
## wrap buttons in this popup
