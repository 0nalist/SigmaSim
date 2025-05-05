extends Label
class_name Statpop

@export var lifetime := 1.0
@export var float_distance := 50.0

var timer := 0.0
var start_position := Vector2.ZERO

func _ready() -> void:
	start_position = global_position
	modulate.a = 1.0


func init(text: String, color: Color = Color.WHITE) -> void:
	self.text = text
	self.add_theme_color_override("font_color", color)
	
	anchor_left = 0
	anchor_top = 0
	anchor_right = 0
	anchor_bottom = 0
	pivot_offset = size / 2

func _process(delta: float) -> void:
	timer += delta
	var progress = timer / lifetime

	global_position = start_position - Vector2(0, float_distance * progress)
	modulate.a = 1.0 - progress

	if progress >= 1.0:
		queue_free()
