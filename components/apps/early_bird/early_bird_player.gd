# early_bird_player.gd
extends Area2D
class_name EarlyBirdPlayer

signal died
signal scored_point

#@export var gravity: float = 900.0
@export var jump_strength: float = 450.0
@export var terminal_velocity: float = 1200.0

@onready var early_bird_player_sprite: Sprite2D = %EarlyBirdPlayerSprite
@onready var early_bird_player_flap_sprite: Sprite2D = %EarlyBirdPlayerFlapSprite


var velocity: Vector2 = Vector2.ZERO
var is_alive: bool = true
var score: int = 0

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))
	early_bird_player_flap_sprite.hide()
	early_bird_player_sprite.show()

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
	animate_flap()


func animate_flap():
	early_bird_player_flap_sprite.show()
	early_bird_player_sprite.hide()
	await get_tree().create_timer(.2).timeout
	early_bird_player_flap_sprite.hide()
	early_bird_player_sprite.show()

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
		emit_signal("died")
		var pane := trauma_target as Control
		if pane:
			pane.pivot_offset = pane.size / 2
		TraumaManager.hit_pane(trauma_target, 1.8)
		#TraumaManager.hit_window_frame(trauma_target, 1.8)
		await get_tree().create_timer(.1).timeout
		if pane:
			pane.pivot_offset = pane.size / 2
		TraumaManager.hit_pane(trauma_target, 1.8)




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
