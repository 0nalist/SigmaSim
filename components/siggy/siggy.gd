extends Control

var slide_duration := 1
var bounce_height := 9
var bounce_speed := 0.08  # Time per bounce

@onready var siggy_sprite := %SiggySprite
#@onready var speech_bubble.speech_label: Label = %SpeechLabel
@onready var speech_bubble: SpeechBubble = %SpeechBubble

func _ready():
	hide()
	z_index = 1020
	await get_tree().create_timer(1).timeout
	call_deferred("slide_in_from_right")

func slide_out_from_behind(window: WindowFrame):
	show()
	z_index = window.z_index - 1

	# Start hidden behind the window's center
	var siggy_size = size
	if siggy_size == Vector2.ZERO:
		siggy_size = get_minimum_size()
		if siggy_size == Vector2.ZERO:
			siggy_size = Vector2(200, 200)
	var win_pos = window.position
	var win_size = window.size
	position = win_pos + win_size / 2 - siggy_size / 2

	# Determine which direction has the most free space on screen
	var screen_size = get_viewport_rect().size
	var margin := 20
	var left_space = win_pos.x
	var right_space = screen_size.x - (win_pos.x + win_size.x)
	var top_space = win_pos.y
	var bottom_space = screen_size.y - (win_pos.y + win_size.y)

	var target_pos = position
	if left_space >= right_space and left_space >= top_space and left_space >= bottom_space:
		target_pos = Vector2(win_pos.x - siggy_size.x - margin, win_pos.y + win_size.y / 2 - siggy_size.y / 2)
	elif right_space >= top_space and right_space >= bottom_space:
		target_pos = Vector2(win_pos.x + win_size.x + margin, win_pos.y + win_size.y / 2 - siggy_size.y / 2)
	elif top_space >= bottom_space:
		target_pos = Vector2(win_pos.x + win_size.x / 2 - siggy_size.x / 2, win_pos.y - siggy_size.y - margin)
	else:
		target_pos = Vector2(win_pos.x + win_size.x / 2 - siggy_size.x / 2, win_pos.y + win_size.y + margin)

	create_tween().tween_property(self, "position", target_pos, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func slide_in_from_bottom_right():
	var screen_size = get_viewport_rect().size
	var siggy_size = size

	if siggy_size == Vector2.ZERO:
		siggy_size = get_minimum_size()
		if siggy_size == Vector2.ZERO:
			siggy_size = Vector2(200, 200)	# Failsafe default

	var target_pos = screen_size - siggy_size + Vector2(-600, -80)	# Optional offset for margin
	var start_pos = Vector2(target_pos.x, screen_size.y + siggy_size.y)

	position = start_pos
	show()
	create_tween().tween_property(self, "position", target_pos, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func slide_in_from_right():
	show()
	var screen_size = get_viewport_rect().size
	var siggy_size = size

	if siggy_size == Vector2.ZERO:
		siggy_size = get_minimum_size()
		if siggy_size == Vector2.ZERO:
			siggy_size = Vector2(200, 200)	# Fallback default

	# Target position: halfway down screen, 75% across (right quarter)
	var target_pos = Vector2(
		screen_size.x * 0.92,
		screen_size.y * 0.5 - siggy_size.y / 2
	)

	# Start position: offscreen to the right
	var start_pos = Vector2(screen_size.x + siggy_size.x, target_pos.y)

	position = start_pos
	show()

	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func talk(text: String, time_per_char := 0.05) -> void:
	speech_bubble.set_text(text)
	
	# Prepare the bubble for a typewriter effect.
	var target_size = speech_bubble.size
	speech_bubble.speech_label.visible_ratio = 0.0
	speech_bubble.visible = true
	speech_bubble.modulate.a = 0.0
	speech_bubble.scale = Vector2.ZERO
	speech_bubble.pivot_offset = target_size
	speech_bubble.position = Vector2(-target_size.x - 20, -40)

	# Pop in speech bubble with a juicy tween
	var tween = create_tween()
	tween.tween_property(speech_bubble, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(speech_bubble, "modulate:a", 1.0, 0.2)
	await tween.finished

	var total_chars := text.length()
	var delay_per_step := time_per_char
	var bounce_every_n_chars := 2

	var original_pos = siggy_sprite.position
	var original_rotation = siggy_sprite.rotation_degrees
	var rng = RNGManager.siggy.get_rng()

	for i in range(total_chars):
		speech_bubble.speech_label.visible_ratio = float(i + 1) / total_chars

		if i % bounce_every_n_chars == 0:
			var bounce_tween = create_tween()
			var up = original_pos - Vector2(0, bounce_height + rng.randi_range(-2, 2))
			var angle = 2.0 if i % 4 == 0 else -2.0

			bounce_tween.tween_property(siggy_sprite, "position", up, bounce_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bounce_tween.parallel().tween_property(siggy_sprite, "rotation_degrees", angle, bounce_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bounce_tween.tween_property(siggy_sprite, "position", original_pos, bounce_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bounce_tween.parallel().tween_property(siggy_sprite, "rotation_degrees", original_rotation, bounce_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		await get_tree().create_timer(delay_per_step).timeout

	# Ensure Siggy resets cleanly
	siggy_sprite.rotation_degrees = 0.0
	siggy_sprite.position = original_pos

func slide_down_away():
	var screen_size = get_viewport_rect().size
	var target_pos = Vector2(position.x, screen_size.y + size.y)

	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, slide_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): hide())

func activate(reason: String, data: Dictionary = {}):
	match reason:
		"bill_unpayable":
			var msg = "Uh oh, looks like you're going to need some fast cash!"
			msg += "\n💡 Tip: " + get_money_tip()
			slide_in_from_bottom_right()
			talk(msg)
		"default":
			var msg = "Hi there! Need something?"
			slide_in_from_right()
			talk(msg)

func get_money_tip() -> String:
	var tips = []
	tips.append("Check your stocks in BrokeRage.")
	tips.append("You could pick up a gig on Grinderr.")
	tips.append("Try mining crypto in Minerr.")

	if tips.is_empty():
		return "Try cutting back on spending for now."

	var rng = RNGManager.siggy.get_rng()
	return tips[rng.randi() % tips.size()]

func out_of_pocket_wildcard() -> String:
	var wildcards = []
	wildcards.append("I'm real and I love you in real life!")
	wildcards.append("...all I'm saying is, buildings don't just fall down like that!")
	wildcards.append("And that's the day I learned why they're called sperm whales")

	var rng = RNGManager.siggy.get_rng()
	return str(wildcards[rng.randi_range(0, wildcards.size() - 1)])

func _on_talk_button_pressed() -> void:
	talk(out_of_pocket_wildcard())

func _on_check_button_pressed() -> void:
	slide_down_away()

func _on_button_pressed() -> void:
	pass  # Replace with function body.
