# early_bird_hud.gd
extends Pane
class_name EarlyBirdHUD


signal restart_pressed
signal quit_pressed

@onready var hud: Control = %HUD
@onready var score_label: Label = %ScoreLabel
@onready var cash_per_score_label: Label = %CashPerScoreLabel

@onready var game_menu_container: VBoxContainer = %GameMenuContainer
@onready var game_label: Label = %GameLabel
@onready var go_button: Button = %GoButton
@onready var quit_button: Button = %QuitButton
@onready var winnings_label: Label = %WinningsLabel



func _ready() -> void:
	game_label.text = "Early Bird"
	go_button.pressed.connect(_on_go_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	reset()

func update_score(new_score: int) -> void:

	score_label.text = str(new_score)
	#winnings_label.text = str(winnings)

func update_winnings(new_winnings: float) -> void:
	winnings_label.text = "$%.2f" % new_winnings



func update_cash_per_score(cps: float) -> void:
	cash_per_score_label.text = "$%.2f" % cps


func show_game_over(final_winnings: float) -> void:
	game_label.text = "Game Over!\nWinnings: $" + str(final_winnings)
	PortfolioManager.add_cash(final_winnings)
	game_menu_container.show()



func reset(cps: float = 0.0) -> void:
	update_score(0)
	update_cash_per_score(cps)
	update_winnings(0)

	game_menu_container.hide()

func _on_go_button_pressed() -> void:
	emit_signal("restart_pressed")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_pressed")
