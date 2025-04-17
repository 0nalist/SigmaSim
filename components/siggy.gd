extends Control


var slide_duration := 0.5
var bounce_height := 9
var bounce_speed := 0.08  # Time per bounce

@onready var siggy_sprite := %SiggySprite
@onready var speech_label: Label = %SpeechLabel
@onready var speech_bubble: NinePatchRect = %SpeechBubble


func _ready():
	#hide()
	z_index = 1023


func slide_in_from_bottom_right():
	var screen_size = get_viewport_rect().size
	var siggy_size = size
	var target_pos = screen_size - siggy_size
	var start_pos = Vector2(target_pos.x, screen_size.y + siggy_size.y)

	position = start_pos
	show()
	create_tween().tween_property(self, "position", target_pos, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func slide_in_from_right():
	var screen_size = get_viewport_rect().size
	var siggy_size = size
	var target_pos = Vector2(screen_size.x - siggy_size.x, screen_size.y - siggy_size.y)
	var start_pos = Vector2(screen_size.x + siggy_size.x, target_pos.y)

	position = start_pos
	show()
	create_tween().tween_property(self, "position", target_pos, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func talk(text: String, time_per_char := 0.05) -> void:
	speech_label.text = text
	speech_label.visible_ratio = 0.0
	speech_bubble.visible = true
	speech_bubble.modulate.a = 0.0
	speech_bubble.position = Vector2(-speech_bubble.size.x - 20, -40)

	# Fade in speech bubble
	var tween = create_tween()
	tween.tween_property(speech_bubble, "modulate:a", 1.0, 0.3)

	await tween.finished

	var total_chars := text.length()
	var type_duration = clamp(total_chars * time_per_char, 0.5, 10.0)
	var delay_per_step := time_per_char
	var bounce_every_n_chars := 2

	var original_pos = siggy_sprite.position
	var original_rotation = siggy_sprite.rotation_degrees

	for i in range(total_chars):
		speech_label.visible_ratio = float(i + 1) / total_chars

		if i % bounce_every_n_chars == 0:
			var bounce_tween = create_tween()
			var up = original_pos - Vector2(0, bounce_height + randi_range(-2, 2))
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

	#if AppManager.has_app("BrokeRage"):
	tips.append("Check your stocks in BrokeRage.")
	#if AppManager.has_app("Grinderr"):
	tips.append("You could pick up a gig on Grinderr.")
	#if AppManager.has_app("Minerr"):
	tips.append("Try mining crypto in Minerr.")

	if tips.is_empty():
		return "Try cutting back on spending for now."
	return tips.pick_random()


func _on_talk_button_pressed() -> void:
	talk("This is a test phraseThis is a test phraseThis is a test phraseThis is a test phrase")


func _on_check_button_pressed() -> void:
	slide_down_away()


func _on_button_pressed() -> void:
	pass # Replace with function body.
