# early_bird_pipe_manager.gd
extends Node2D
class_name EarlyBirdPipeManager

@export var pipe_pair_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_x_offset: float = 1000.0

var spawn_timer: Timer

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_pipe_pair)
	add_child(spawn_timer)
	

func start_spawning() -> void:
	spawn_timer.start()

func stop_spawning() -> void:
	spawn_timer.stop()

func reset() -> void:
	stop_spawning()
	for child in get_children():
		if child is EarlyBirdPipePair:
			child.queue_free()

func _on_spawn_pipe_pair() -> void:
	print("spawning pipe pair")
	var pipe_pair = pipe_pair_scene.instantiate()
	add_child(pipe_pair)

	pipe_pair.global_position = Vector2(
		get_viewport_rect().size.x + spawn_x_offset,
		0
	)

	pipe_pair.player = %EarlyBirdPlayer

	pipe_pair.randomize_gap_position()
