# early_bird.gd
extends Control
class_name EarlyBird

@onready var round_manager = %RoundManager
@onready var pipe_manager = %PipeManager
@onready var player: EarlyBirdPlayer = %EarlyBirdPlayer
@onready var hud = %HUD

var game_active: bool = false

func _ready() -> void:
	round_manager.round_started.connect(_on_round_started)
	round_manager.round_ended.connect(_on_round_ended)
	player.died.connect(_on_player_died)
	player.banked.connect(_on_player_banked)
	player.scored_point.connect(_on_player_scored)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.quit_pressed.connect(_on_quit_pressed)
	hud.force_spawn_pipe.connect(_on_force_spawn_pipe)
	start_game()

func _on_force_spawn_pipe() -> void:
	print("Force spawning pipe manually.")
	pipe_manager._on_spawn_pipe_pair()

func start_game() -> void:
	game_active = true
	player.reset()
	pipe_manager.reset()
	round_manager.start_round_cycle()
	hud.reset()

func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return

	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		player.flap()

func _on_round_started(round_type: String) -> void:
	if round_type == "pipe":
		pipe_manager.start_spawning()
		hud.show_bank_prompt(false)
	elif round_type == "break":
		pipe_manager.stop_spawning()
		hud.show_bank_prompt(true)

func _on_round_ended(round_type: String) -> void:
	pass # You could add bonus logic here later.

func _on_player_died() -> void:
	game_active = false
	round_manager.stop_round_cycle()
	hud.show_game_over(player.score)

func _on_player_banked() -> void:
	game_active = false
	round_manager.stop_round_cycle()
	hud.show_bank_success(player.score)

func _on_player_scored() -> void:
	hud.update_score(player.score)

func _on_restart_pressed() -> void:
	start_game()

func _on_quit_pressed() -> void:
	queue_free() # (Or hide this window if integrating in SigmaSim)
