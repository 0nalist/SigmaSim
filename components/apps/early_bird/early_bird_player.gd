# early_bird_player.gd
extends Area2D
class_name EarlyBirdPlayer

signal died
signal scored_point

#@export var gravity: float = 900.0
@export var jump_strength: float = 450.0
@export var terminal_velocity: float = 1200.0

@onready var early_bird_player_sprite: Sprite2D = %EarlyBirdPlayerSprite


var velocity: Vector2 = Vector2.ZERO
var is_alive: bool = true
var score: int = 0

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	velocity.y += gravity * 2.4 * delta
	velocity.y = min(velocity.y, terminal_velocity)

	position += velocity * delta
	var target_rotation = clamp(velocity.y / 600.0, -0.5, 0.5)
	early_bird_player_sprite.rotation = lerp(early_bird_player_sprite.rotation, target_rotation, 10.0 * delta)
	if position.y < 0 or position.y > get_viewport_rect().size.y + 10:
		_on_death()

func flap() -> void:
	if is_alive:
		velocity.y = -jump_strength

func _on_area_entered(area: Area2D) -> void:
	if not is_alive:
		return
	
	if area.is_in_group("obstacle"):
		_on_death()


@export var trauma_target: Node

func _on_death() -> void:
	print("bird died")
	if is_alive:
		is_alive = false
		TraumaManager.hit_pane(trauma_target, 1.8)
		emit_signal("died")



func add_point() -> void:
	score += 1
	emit_signal("scored_point")

func reset() -> void:
	position = Vector2(100, 0) #
	velocity = Vector2.ZERO
	score = 0
	is_alive = true

func freeze() -> void:
	velocity = Vector2.ZERO
