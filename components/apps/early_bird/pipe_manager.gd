# early_bird_pipe_manager.gd
extends Node2D
class_name EarlyBirdPipeManager

@export var pipe_pair_scene: PackedScene
@export var spawn_interval: float = 2
@export var spawn_x_offset: float = 1000.0

var spawn_timer: Timer
var cached_viewport_size: Vector2
@onready var _root_control: Control = get_parent()

func _ready() -> void:
        spawn_timer = Timer.new()
        spawn_timer.wait_time = spawn_interval
        spawn_timer.timeout.connect(_on_spawn_pipe_pair)
        add_child(spawn_timer)

        cached_viewport_size = _root_control.size
        _root_control.resized.connect(_on_viewport_size_changed)
	

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
	var pipe_pair = pipe_pair_scene.instantiate()
	add_child(pipe_pair)
	
        pipe_pair.position = Vector2(
        cached_viewport_size.x + spawn_x_offset,
        0
        )
        pipe_pair.player = %EarlyBirdPlayer

        pipe_pair.randomize_gap_position(cached_viewport_size.y)

func set_move_speed(new_speed: float) -> void:
	for child in get_children():
		if child is EarlyBirdPipePair:
			child.move_speed = new_speed

	# Adjust spawn interval: faster speed = spawn farther apart
	spawn_interval = clamp(1 + (100.0 / new_speed), 0.25, 2) 
	if spawn_timer:
                spawn_timer.wait_time = spawn_interval



func _on_viewport_size_changed() -> void:
        var new_size = _root_control.size
        if new_size.x > 1 and new_size.y > 1:
                cached_viewport_size = new_size


func get_active_pipe_pairs() -> Array[EarlyBirdPipePair]:
	var active_pairs: Array[EarlyBirdPipePair]
	for child in get_children():
		if child is EarlyBirdPipePair:
			active_pairs.append(child)
	return active_pairs
