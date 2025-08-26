extends NinePatchRect
class_name SpeechBubble

@onready var speech_label: Label = %SpeechLabel
var follow_control: Control

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000

func set_text(text: String) -> void:
	# Config
	var max_width: float = 260.0
	var min_width: float = 80.0
	var padding: Vector2 = Vector2(20.0, 20.0)

	# Configure the label first.
	speech_label.visible_ratio = 1.0  # Label supports this. 
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_label.text = text

	# Choose a target width and apply it to the Label so wrapping will occur.
	var label_req: Vector2 = speech_label.get_combined_minimum_size()
	var target_width: float = clamp(label_req.x, min_width, max_width)
	speech_label.custom_minimum_size = Vector2(target_width, 0.0)
	speech_label.size = Vector2(target_width, 0.0)

	# Measure wrapped text using the Label's current theme font & size.
	var text_size: Vector2 = _measure_wrapped(text, target_width)

	# Size the bubble to fit the text + padding.
	var target_size: Vector2 = Vector2(target_width, text_size.y) + padding
	custom_minimum_size = target_size
	size = target_size
	pivot_offset = target_size

func pop_and_fade(lifetime: float = 3.0) -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0
	visible = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)
	var fade: Tween = create_tween()
	fade.tween_interval(lifetime)
	fade.tween_property(self, "modulate:a", 0.0, 0.2)
	fade.tween_callback(queue_free)

func get_label() -> Label:
		return speech_label

func follow(control: Control) -> void:
		follow_control = control
		_update_follow_position()

func _process(_delta: float) -> void:
		if follow_control and is_instance_valid(follow_control):
				_update_follow_position()

func _update_follow_position() -> void:
		if follow_control and is_instance_valid(follow_control):
				var rect = follow_control.get_global_rect()
				global_position = Vector2(
						rect.position.x - size.x - 10,
						rect.position.y + (rect.size.y - size.y) * 0.5,
				)

# --- Helpers ---

func _measure_wrapped(text: String, width: float) -> Vector2:
	# This uses the actual font on the Label (including theme overrides).
	var font: Font = speech_label.get_theme_font("font")
	var font_size: int = speech_label.get_theme_font_size("font_size")
	# Height accounts for wrapping at the given width.
	var size: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size)
	return size
