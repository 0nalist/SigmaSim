class_name AffinityBar
extends StatProgressBar

var affinity_equilibrium: float = 0.0

func set_affinity_equilibrium(new_eq: float) -> void:
	affinity_equilibrium = new_eq
	queue_redraw()

func _draw() -> void:
	var bar_rect: Rect2 = Rect2(Vector2.ZERO, size)
	if max_value != min_value:
			var fraction: float = clamp((affinity_equilibrium - min_value) / (max_value - min_value), 0.0, 1.0)
			var x: float = bar_rect.position.x + bar_rect.size.x * fraction
			draw_line(
					Vector2(x, bar_rect.position.y),
					Vector2(x, bar_rect.position.y + bar_rect.size.y),
					Color.WHITE,
					1.0
			)

func _get_tooltip(at_position: Vector2 = Vector2.ZERO) -> String:
	var bar_rect: Rect2 = Rect2(Vector2.ZERO, size)
	if max_value != min_value:
			var fraction: float = clamp((affinity_equilibrium - min_value) / (max_value - min_value), 0.0, 1.0)
			var x: float = bar_rect.position.x + bar_rect.size.x * fraction
			if absf(at_position.x - x) <= 2.0:
					return "Affinity will drift toward equilibrium over time"
	return tooltip_text
