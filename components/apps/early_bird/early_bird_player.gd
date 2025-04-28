# early_bird_player.gd
extends Area2D
class_name EarlyBirdPlayer

signal died
signal scored_point
signal banked

#@export var gravity: float = 900.0
@export var jump_strength: float = 650.0
@export var terminal_velocity: float = 1400.0

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

	if position.y < 0 or position.y > get_viewport_rect().size.y:
		_on_death()

func flap() -> void:
	if is_alive:
		velocity.y = -jump_strength

func _on_area_entered(area: Area2D) -> void:
	if not is_alive:
		return
	
	if area.is_in_group("obstacle"):
		_on_death()
	elif area.is_in_group("bank"):
		_on_banked()

func _on_death() -> void:
	print("bird died")
	if is_alive:
		is_alive = false
		emit_signal("died")

func _on_banked() -> void:
	print("banked")
	if is_alive:
		is_alive = false
		emit_signal("banked")

func add_point() -> void:
	score += 1
	emit_signal("scored_point")

func reset() -> void:
	position = Vector2(100, get_viewport_rect().size.y / 2)
	velocity = Vector2.ZERO
	score = 0
	is_alive = true

func freeze() -> void:
	velocity = Vector2.ZERO
