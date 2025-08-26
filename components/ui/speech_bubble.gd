extends NinePatchRect
class_name SpeechBubble

@onready var speech_label: Label = %SpeechLabel

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000

func set_text(text: String) -> void:
	speech_label.text = text
	speech_label.visible_ratio = 1.0
	speech_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var label_size = speech_label.get_combined_minimum_size()
	var max_width = 260
	var target_width = clamp(label_size.x, 80, max_width)
	speech_label.custom_minimum_size.x = target_width
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_size = speech_label.get_combined_minimum_size()
	var padding = Vector2(20, 20)
	var target_size = label_size + padding
	custom_minimum_size = target_size
	size = target_size
	pivot_offset = target_size

func pop_and_fade(lifetime: float = 3.0) -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)
	var fade = create_tween()
	fade.tween_interval(lifetime)
	fade.tween_property(self, "modulate:a", 0.0, 0.2)
	fade.tween_callback(queue_free)

func get_label() -> Label:
	return speech_label
