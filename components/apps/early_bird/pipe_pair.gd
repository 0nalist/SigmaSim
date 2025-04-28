# early_bird_pipe_pair.gd
extends Node2D
class_name EarlyBirdPipePair

@export var move_speed: float = 200.0
@export var gap_size: float = 200.0
@export var min_y: float = 150.0
@export var max_y: float = 450.0

var scored: bool = false
var player: Node = null # Reference to player for scoring check

func _ready() -> void:
	_randomize_gap_position()

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

func _randomize_gap_position() -> void:
	var viewport_height = get_viewport_rect().size.y
	var safe_margin = 100.0 # To avoid absurd gaps touching edges

	var top_pipe = %TopPipe
	var bottom_pipe = %BottomPipe

	var top_sprite = top_pipe.get_node("TopPipeSprite")
	var bottom_sprite = bottom_pipe.get_node("BottomPipeSprite")

	# Choose a random Y for the CENTER of the gap
	var gap_center_y = randf_range(
		safe_margin + gap_size / 2,
		viewport_height - safe_margin - gap_size / 2
	)

	# Position TopPipe so its bottom touches the top of the gap
	var top_pipe_height = top_sprite.texture.get_height()
	top_pipe.position = Vector2(0, gap_center_y - (gap_size / 2) - top_pipe_height)

	# Position BottomPipe so its top touches the bottom of the gap
	bottom_pipe.position = Vector2(0, gap_center_y + (gap_size / 2))

	# Reset Sprites inside the Area2D
	top_sprite.position = Vector2(0, 0)
	bottom_sprite.position = Vector2(0, 0)
