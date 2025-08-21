class_name RelationshipBar
extends StatProgressBar

var mark_fractions: Array[float] = []

func set_mark_fractions(new_marks: Array[float]) -> void:
	mark_fractions.clear()
	for m: float in new_marks:
		mark_fractions.append(m)
	queue_redraw()

func _draw() -> void:
	var bar_rect: Rect2 = Rect2(Vector2.ZERO, size)
	for f: float in mark_fractions:
		var x: float = bar_rect.position.x + bar_rect.size.x * f
		draw_line(
			Vector2(x, bar_rect.position.y),
			Vector2(x, bar_rect.position.y + bar_rect.size.y),
			Color.WHITE,
			1.0
		)


func _get_tooltip(at_position: Vector2 = Vector2.ZERO) -> String:
	for f: float in mark_fractions:
		var x: float = size.x * f
		if absf(at_position.x - x) <= 2.0:
			return "A date is required to continue progressing"
	return tooltip_text
