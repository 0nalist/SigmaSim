# early_bird_pipe_pair.gd
extends Node2D
class_name EarlyBirdPipePair

@export var move_speed: float = 200.0
@export var gap_size: float = 200.0
@export var min_y: float = 50.0
@export var max_y: float = 550.0


var scored: bool = false
var player: Node = null # Reference to player for scoring check


func _physics_process(delta: float) -> void:

	position.x -= move_speed * delta

	# Check for scoring
	if not scored and player:
		if player.global_position.x > global_position.x:
			if player.is_alive:
				player.add_point()
			scored = true

	if position.x < -300:
			queue_free()

func randomize_gap_position(viewport_height: float) -> void:
	var safe_margin = 50.0

	# Randomize center Y position for the GAP within bounds
	var rng = RNGManager.early_bird.get_rng()
	var lower_bound = max(safe_margin + gap_size / 2, min_y + gap_size / 2)
	var upper_bound = min(viewport_height - safe_margin - gap_size / 2, max_y - gap_size / 2)
	position.y = rng.randf_range(lower_bound, upper_bound)





func get_gap_center_y() -> float:
	return position.y
