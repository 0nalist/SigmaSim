extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var worm_texture: TextureRect = $WormTexture
@onready var timer: Timer = $Timer
var rotation_animation_interval: float = 2.4
var pulse_animation_interval: float = 1.9

var pulsing: bool = false
var pulse_tween: Tween




func _ready() -> void:
	pass



func _on_mouse_entered() -> void:
	pulsing = true
	_start_pulsing()

func _on_mouse_exited() -> void:
	pulsing = false
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	sprite.scale = Vector2.ONE

func _start_pulsing() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()

	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), pulse_animation_interval / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), pulse_animation_interval / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("worm clicked")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		PortfolioManager.cash += 1.0
		if StatpopManager:
			print("worm statpop")
			StatpopManager.spawn("+$1", global_position, "click")


func _on_worm_texture_mouse_entered() -> void:
	pulsing = true
	_start_pulsing()


func _on_worm_texture_mouse_exited() -> void:
	pulsing = false
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	sprite.scale = Vector2.ONE


func _on_worm_texture_gui_input(event: InputEvent) -> void:
	print("worm clicked")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		PortfolioManager.add_cash(1)
		if StatpopManager:
			print("worm statpop")
			StatpopManager.spawn("+$1", global_position, "click")


func _on_timer_timeout() -> void:
	var angle_deg = randf_range(30.0, 70.0)
	worm_texture.rotation += deg_to_rad(angle_deg)
#	print("rotating worm")
