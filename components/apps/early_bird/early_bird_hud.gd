# early_bird_hud.gd
extends Pane
class_name EarlyBirdHUD


signal restart_pressed
signal quit_pressed

@onready var hud: Control = %HUD
@onready var score_label: Label = %ScoreLabel
#@onready var bank_label: Label = %BankLabel

@onready var game_menu_container: VBoxContainer = %GameMenuContainer
@onready var game_label: Label = %GameLabel
@onready var go_button: Button = %GoButton
@onready var quit_button: Button = %QuitButton



func _ready() -> void:
	game_label.text = "Early Bird"
	go_button.pressed.connect(_on_go_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	reset()

func update_score(new_score: int) -> void:
	score_label.text = str(new_score)



func show_game_over(final_score: int) -> void:
	#game_label.text = "Game Over!\nScore: " + str(final_score)
	game_menu_container.show()



func reset() -> void:
	update_score(0)
	
	game_menu_container.hide()
	#game_label.hide()

func _on_go_button_pressed() -> void:
	emit_signal("restart_pressed")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_pressed")
