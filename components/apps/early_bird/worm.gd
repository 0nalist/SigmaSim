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
	#print("worm clicked")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var value = StatManager.get_stat("worm_yield", 1.0)
		PortfolioManager.add_cash(value)
		if StatpopManager:
			print("worm statpop")
			var amount := NumberFormatter.format_commas(value, 2, true)
			StatpopManager.spawn("+$" + amount, global_position, "click", Color.GREEN)


func _on_worm_texture_mouse_entered() -> void:
	pulsing = true
	_start_pulsing()


func _on_worm_texture_mouse_exited() -> void:
	pulsing = false
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	sprite.scale = Vector2.ONE


func _on_worm_texture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var value = StatManager.get_stat("worm_yield", 1.0)
		PortfolioManager.add_cash(value)
		if StatpopManager:
			var amount := NumberFormatter.format_commas(value, 2, true)
			StatpopManager.spawn("+$" + amount, global_position, "click", Color.GREEN)


func _on_timer_timeout() -> void:
     var rng = RNGManager.early_bird.get_rng()
	var angle_deg = rng.randf_range(30.0, 70.0)
	worm_texture.rotation += deg_to_rad(angle_deg)
