# early_bird_round_manager.gd
extends Node
class_name EarlyBirdRoundManager

signal round_started(round_type: String)
signal round_ended(round_type: String)

@export var pipe_round_duration: float = 15.0
@export var break_round_duration: float = 5.0

var current_round: String = ""
var timer: Timer

func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	

func start_round_cycle() -> void:
	_start_pipe_round()

func stop_round_cycle() -> void:
	timer.stop()

func _start_pipe_round() -> void:
	current_round = "pipe"
	emit_signal("round_started", current_round)
	timer.wait_time = pipe_round_duration
	timer.start()

func _start_break_round() -> void:
	current_round = "break"
	emit_signal("round_started", current_round)
	timer.wait_time = break_round_duration
	timer.start()

func _on_timer_timeout() -> void:
	emit_signal("round_ended", current_round)
	
	# Switch to the other round type
	if current_round == "pipe":
		_start_break_round()
	else:
		_start_pipe_round()
