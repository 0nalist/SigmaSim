# components/apps/early_bird/early_bird.gd
# early_bird.gd
extends Pane
class_name EarlyBird

@onready var round_manager = %RoundManager
@onready var pipe_manager = %PipeManager
@onready var player: EarlyBirdPlayer = %EarlyBirdPlayer
@onready var hud = %HUD

@export var base_speed: float = 200.0
@export var speed_growth_rate: float = 10.0  # Speed increase per second
@export var max_speed: float = 2400.0  # 1600 tested as safe
@onready var autopilot: Node = %EarlyBirdAutopilot
@onready var autopilot_button: Button = %AutopilotButton
@onready var disable_flaps_checkbox: CheckBox = %DisableManualFlaps

@export var base_width: float = 440.0
@export var fixed_height: float = 600.0

@onready var high_clouds: Parallax2D = $Parallax/HighClouds
@onready var hills: Parallax2D = $Parallax/Hills
@onready var hills_2: Parallax2D = %Hills2
@onready var foreground: Parallax2D = %Foreground
@onready var forest: Parallax2D = %Forest
@onready var forest_2: Parallax2D = %Forest2
@onready var forest_3: Parallax2D = %Forest3

@onready var statpops_silenced: bool = false


var current_speed: float = 0.0
var speed_timer := 0.0

#var window_frame: WindowFrame = null

var game_active: bool = false

## Data to Save/Load ##
var cash_per_score: float = 0.01
var winnings: float = 0.00
var autopilot_cost: float = 1.0
var manual_flaps_disabled: bool = false

func _ready() -> void:
	window_frame = find_parent_window_frame()
	reset_speed()

	round_manager.round_started.connect(_on_round_started)
	round_manager.round_ended.connect(_on_round_ended)
	player.died.connect(_on_player_died)
	player.scored_point.connect(_on_player_scored)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.quit_pressed.connect(_on_quit_pressed)

	disable_flaps_checkbox.toggled.connect(_on_disable_flaps_toggled)

	StatManager.connect_to_stat("cash_per_score", self, "_on_cash_per_score_changed")
	autopilot_cost = StatManager.get_stat("autopilot_cost", 1.0)
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	autopilot_button.gui_input.connect(_on_autopilot_button_gui_input)
	_update_autopilot_button_text()
	_update_disable_flaps_visibility()
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
		# Adjust window stretch

		# Adjust window stretch
	speed_timer += delta
	current_speed = min(base_speed + speed_growth_rate * speed_timer, max_speed)
	pipe_manager.set_move_speed(current_speed)
	high_clouds.autoscroll = Vector2(-(current_speed / 20), 0)
	foreground.autoscroll = Vector2(-current_speed, 0)
	hills.autoscroll = Vector2(-(current_speed / 15), 0)
	forest.autoscroll = Vector2(-(current_speed / 2.2), 0)
	forest_2.autoscroll = Vector2(-(current_speed / 2), 0)
	forest_3.autoscroll = Vector2(-(current_speed / 1.8), 0)

	hills_2.autoscroll = Vector2(-(current_speed / 17), 0)

	# Adjust window stretch
	_adjust_window_size()

func _adjust_window_size() -> void:
	if window_frame == null:
		return
	var speed_ratio: float = (current_speed - base_speed) / (max_speed - base_speed)
	var viewport_width: int = get_viewport().size.x
	var target_width: float = lerp(base_width, float(viewport_width), speed_ratio)
	
	var new_size: Vector2 = window_frame.size
	new_size.x = lerp(float(window_frame.size.x), target_width, 0.1)
	new_size.y = fixed_height
	window_frame.size = new_size


func start_game() -> void:
	_update_cash_per_score()
	game_active = true
	player.reset()
	pipe_manager.reset()
	round_manager.start_round_cycle()
	winnings = 0.0
	hud.reset(cash_per_score)
	window_frame.size = Vector2(base_width, fixed_height)
	reset_speed()
	%Worm.show()
	_update_autopilot_button_text()
	#disable_flaps_checkbox.button_pressed = false
	#manual_flaps_disabled = false
	_update_disable_flaps_visibility()

func reset_speed():
	speed_timer = 0.0
	current_speed = base_speed
	pipe_manager.set_move_speed(current_speed)

func _input(event: InputEvent) -> void:
		if not game_active:
				return
		if (
				(event is InputEventMouseButton and event.pressed)
				or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE)
		) and not manual_flaps_disabled:
				player.flap()

func _on_round_started(round_type: String) -> void:
	if round_type == "pipe":
		pipe_manager.start_spawning()

func _on_round_ended(_round_type: String) -> void:
	pass  # You could add bonus logic here later.

func _on_player_died() -> void:
	game_active = false
	round_manager.stop_round_cycle()
	hud.show_game_over(winnings)
	%Worm.hide()
	
	
	autopilot.enabled = false
	autopilot_button.button_pressed = false
	_update_autopilot_button_text()

func _on_player_scored() -> void:
	winnings += cash_per_score
	if UpgradeManager.get_level("earlybird_earlier_bird") > 0:
		PortfolioManager.add_cash(cash_per_score)
		StatpopManager.spawn("+$"+NumberFormatter.format_commas(cash_per_score), player.global_position, "passive", Color.GREEN)
	hud.update_score(player.score)
	hud.update_winnings(winnings)

func _on_restart_pressed() -> void:
	start_game()

func _on_quit_pressed() -> void:
	if window_frame and WindowManager and WindowManager.has_method("close_window"):
		WindowManager.close_window(window_frame)
	else:
		window_frame.queue_free()

func _on_autopilot_button_pressed() -> void:
	if autopilot == null:
		return
	var cost := _get_autopilot_cost()
	if not autopilot.enabled:
		if cost > 0.0 and not PortfolioManager.attempt_spend(cost, PortfolioManager.CREDIT_REQUIREMENTS["EarlyBird"]):
			autopilot_button.button_pressed = false
			return
		autopilot.enabled = true
		if cost > 0.0:
			autopilot_cost = snapped(autopilot_cost + 0.01, 0.01)
		StatManager.set_base_stat("autopilot_cost", autopilot_cost)
		
		_update_autopilot_button_text()
		autopilot_button.disabled = true
		await get_tree().create_timer(2.0).timeout
		autopilot_button.disabled = false
		return
	autopilot.enabled = false
	_update_autopilot_button_text()

func _on_autopilot_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if autopilot == null:
			return
		var cost := _get_autopilot_cost()
		if not autopilot.enabled:
			if cost > 0.0 and not PortfolioManager.attempt_spend(cost, PortfolioManager.CREDIT_REQUIREMENTS["EarlyBird"], false, true):
				autopilot_button.button_pressed = false
				return
			autopilot.enabled = true
			if cost > 0.0:
				autopilot_cost = snapped(autopilot_cost + 0.01, 0.01)
			StatManager.set_base_stat("autopilot_cost", autopilot_cost)
			_update_autopilot_button_text()
			autopilot_button.disabled = true
			await get_tree().create_timer(2.0).timeout
			autopilot_button.disabled = false
			autopilot_button.accept_event()
			return
		autopilot.enabled = false
		_update_autopilot_button_text()
		autopilot_button.accept_event()

func _get_autopilot_cost() -> float:
		if UpgradeManager.get_level("earlybird_autopilot_free") > 0:
				return 0.0
		return autopilot_cost

func _update_autopilot_button_text() -> void:
		autopilot_button.button_pressed = autopilot.enabled
		var cost := _get_autopilot_cost()
		if not autopilot.enabled and cost > 0.0:
				autopilot_button.text = "Autopilot: $" + NumberFormatter.smart_format(cost)
		else:
				autopilot_button.text = "Autopilot"

func _on_upgrade_purchased(id: String, _level: int) -> void:
	if id == "earlybird_autopilot_free":
		_update_autopilot_button_text()
	elif id == "earlybird_disable_manual_flaps":
		_update_disable_flaps_visibility()

func _update_cash_per_score() -> void:
	cash_per_score = StatManager.get_stat("cash_per_score", 0.01)

func _on_cash_per_score_changed(value: float) -> void:
		cash_per_score = value
		hud.update_cash_per_score(cash_per_score)

func _on_disable_flaps_toggled(pressed: bool) -> void:
		manual_flaps_disabled = pressed

func _update_disable_flaps_visibility() -> void:
	var visible := UpgradeManager.get_level("earlybird_disable_manual_flaps") > 0
	disable_flaps_checkbox.visible = visible
	if not visible:
		disable_flaps_checkbox.button_pressed = false
		manual_flaps_disabled = false
