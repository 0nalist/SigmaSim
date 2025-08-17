# early_bird_hud.gd
extends Pane
class_name EarlyBirdHUD

signal restart_pressed
signal quit_pressed

var _winnings_tween: Tween
var _winnings_base_modulate: Color = Color(1, 1, 1, 1)
var _winnings_base_scale: Vector2 = Vector2.ONE
var _last_score: int = 0
var _should_pulse_on_next_winnings: bool = false

const PULSE_COLOR: Color = Color(0.2, 1.0, 0.2, 1.0) # soft green
const PULSE_SCALE: Vector2 = Vector2(1.1, 1.1)
const PULSE_UP_DUR: float = 0.08
const PULSE_DOWN_DUR: float = 0.13

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

	_winnings_base_modulate = winnings_label.modulate
	_winnings_base_scale = winnings_label.scale

	# Center the pulse origin on the label itself
	_center_pivot_on(winnings_label)
	winnings_label.resized.connect(func():
		_center_pivot_on(winnings_label)
	)

	reset()

func _center_pivot_on(ctrl: Control) -> void:
	# Make scaling originate from the control center
	ctrl.pivot_offset = ctrl.size * 0.5

func update_score(new_score: int) -> void:
	if new_score > _last_score:
		_should_pulse_on_next_winnings = true
	_last_score = new_score
	score_label.text = str(new_score)

func update_winnings(new_winnings: float) -> void:
	winnings_label.text = "$%.2f" % new_winnings
	# Keep pivot centered if text width changes and triggers a resize later
	if _should_pulse_on_next_winnings:
		_should_pulse_on_next_winnings = false
		_pulse_winnings_green()

func _pulse_winnings_green() -> void:
	if is_instance_valid(_winnings_tween):
		_winnings_tween.kill()

	winnings_label.modulate = _winnings_base_modulate
	winnings_label.scale = _winnings_base_scale

	# Up phase
	var up := create_tween()
	up.set_parallel(true)
	up.tween_property(winnings_label, "modulate", PULSE_COLOR, PULSE_UP_DUR)
	up.tween_property(winnings_label, "scale", PULSE_SCALE, PULSE_UP_DUR)

	# Down phase
	up.finished.connect(func():
		if is_instance_valid(_winnings_tween):
			_winnings_tween.kill()
		_winnings_tween = create_tween()
		_winnings_tween.set_parallel(true)
		_winnings_tween.tween_property(winnings_label, "modulate", _winnings_base_modulate, PULSE_DOWN_DUR)
		_winnings_tween.tween_property(winnings_label, "scale", _winnings_base_scale, PULSE_DOWN_DUR)
	)

func update_cash_per_score(cps: float) -> void:
	cash_per_score_label.text = "$%.2f" % cps

func show_game_over(final_winnings: float) -> void:
	game_label.text = "Game Over!\nWinnings: $" + str(NumberFormatter.format_commas(final_winnings))
	PortfolioManager.add_cash(final_winnings)
	if final_winnings > 0:
		StatpopManager.spawn("+$" + str(NumberFormatter.format_commas(final_winnings)), winnings_label.global_position + Vector2(55, 55))
	game_menu_container.show()

func reset(cps: float = 0.0) -> void:
	_last_score = 0
	_should_pulse_on_next_winnings = false
	update_score(0)
	update_cash_per_score(cps)
	update_winnings(0)
	if is_instance_valid(_winnings_tween):
		_winnings_tween.kill()
	winnings_label.modulate = _winnings_base_modulate
	winnings_label.scale = _winnings_base_scale
	_center_pivot_on(winnings_label)
	game_menu_container.hide()

func _on_go_button_pressed() -> void:
	emit_signal("restart_pressed")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_pressed")
