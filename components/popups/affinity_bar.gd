class_name AffinityBar
extends StatProgressBar

var equilibrium_value: float = 50.0

func set_equilibrium(val: float) -> void:
	equilibrium_value = val
	queue_redraw()

func _draw() -> void:
	var bar_rect: Rect2 = Rect2(Vector2.ZERO, size)
	var fraction: float = 0.0
	if max_value != 0:
		fraction = equilibrium_value / max_value
	var x: float = bar_rect.position.x + bar_rect.size.x * fraction
	draw_line(
		Vector2(x, bar_rect.position.y),
		Vector2(x, bar_rect.position.y + bar_rect.size.y),
		Color.WHITE,
		1.0
	)

func _get_tooltip(at_position: Vector2 = Vector2.ZERO) -> String:
	var fraction: float = 0.0
	if max_value != 0:
		fraction = equilibrium_value / max_value
	var x: float = size.x * fraction
	if absf(at_position.x - x) <= 2.0:
		return "Affinity will drift towards equilibrium over time"
	return tooltip_text
