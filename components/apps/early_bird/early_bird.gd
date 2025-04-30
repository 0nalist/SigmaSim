# early_bird.gd
extends Pane
class_name EarlyBird

@onready var round_manager = %RoundManager
@onready var pipe_manager = %PipeManager
@onready var player: EarlyBirdPlayer = %EarlyBirdPlayer
@onready var hud = %HUD

@export var base_speed: float = 200.0
@export var speed_growth_rate: float = 10.0 # Speed increase per second
@export var max_speed: float = 1600.0
@onready var autopilot: Node = %EarlyBirdAutopilot


var current_speed: float = 0.0
var speed_timer := 0.0

var window_frame: WindowFrame = null

@export var base_width: float = 440.0
@export var max_width: float = 1920.0
@export var fixed_height: float = 600.0


@onready var sky: Parallax2D = $Parallax/Sky
@onready var high_clouds: Parallax2D = $Parallax/HighClouds
#@onready var low_clouds: Parallax2D = $Parallax/LowClouds
@onready var hills: Parallax2D = $Parallax/Hills
@onready var hills_2: Parallax2D = %Hills2
@onready var foreground: Parallax2D = %Foreground
@onready var forest: Parallax2D = %Forest






var game_active: bool = false

func _ready() -> void:
	
	window_frame = find_parent_window_frame()
	reset_speed()
	
	round_manager.round_started.connect(_on_round_started)
	round_manager.round_ended.connect(_on_round_ended)
	player.died.connect(_on_player_died)
	player.banked.connect(_on_player_banked)
	player.scored_point.connect(_on_player_scored)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.quit_pressed.connect(_on_quit_pressed)
	
	start_game()

func find_parent_window_frame() -> WindowFrame:
	var parent = get_parent()
	while parent:
		if parent is WindowFrame:
			return parent
		parent = parent.get_parent()
	return null

func _physics_process(delta: float) -> void:
	if not game_active:
		return

	# Escalate speed over time
	speed_timer += delta
	current_speed = min(base_speed + speed_growth_rate * speed_timer, max_speed)
	pipe_manager.set_move_speed(current_speed)
	high_clouds.autoscroll = Vector2(-(current_speed/20), 0)
	foreground.autoscroll = Vector2((-current_speed), 0)
	hills.autoscroll = Vector2(-(current_speed/15), 0)
	forest.autoscroll = Vector2(-(current_speed/2), 0)
	hills_2.autoscroll = Vector2(-(current_speed/17), 0)
	
	# Adjust window stretch
	_adjust_window_size()

func _adjust_window_size() -> void:
	if window_frame == null:
		return

	var speed_ratio = (current_speed - base_speed) / (max_speed - base_speed)
	var target_width = lerp(base_width, max_width, speed_ratio)

	var new_size = window_frame.size
	new_size.x = lerp(window_frame.size.x, target_width, 0.1)
	new_size.y = fixed_height
	window_frame.size = new_size




func start_game() -> void:
	game_active = true
	player.reset()
	pipe_manager.reset()
	round_manager.start_round_cycle()
	hud.reset()
	window_frame.size = Vector2(base_width, fixed_height)
	reset_speed()

func reset_speed():
	speed_timer = 0.0
	current_speed = base_speed
	pipe_manager.set_move_speed(current_speed)


func _input(event: InputEvent) -> void:
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
	if window_frame and WindowManager and WindowManager.has_method("close_window"):
		WindowManager.close_window(window_frame)
	else:
		window_frame.queue_free()


func _on_autopilot_button_pressed() -> void:
	if autopilot:
		autopilot.enabled = !autopilot.enabled
